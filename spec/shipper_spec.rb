require 'docker'
require 'colorize'
require 'sys/proctable'

describe 'shipper' do
  subject { `spec/support/shipper_vcr "#{casette_name}" #{args.join ' '}` }
  let(:output) { system }
  let(:casette_name) do |example|
    "shipper bin #{example.metadata[:full_description].gsub('"', '\\"')}"
  end

  describe 'dev' do
    context 'spec/data/dev.json' do
      let(:args) { ['dev', 'spec/data/dev.json'] }
      let(:env) do
        url = URI.parse Docker.connection.url
        text = Net::HTTP.get URI.parse("http://#{url.host}:4568")
        text.split("\n").each_with_object({}) { |e, o| o.store(*e.split('=')) }
      end

      it 'starts the containers', :vcr do
        pid = spawn %(spec/support/shipper_vcr "#{casette_name}" #{args.join ' '} > /dev/null)
        sleep 2
        dev_test = Docker::Container.get('dev-test')
        dev_logs = Docker::Container.get('dev-logs')
        expect(dev_test.json['State']['Running']).to be true
        expect(dev_logs.json['State']['Running']).to be true
        kill_with_children pid
      end

      it 'destroys containers on exit', :vcr do
        pid = spawn %(spec/support/shipper_vcr "#{casette_name}" #{args.join ' '} > /dev/null)
        sleep 2
        kill_with_children pid
        begin
          Docker::Container.get('dev-test')
          fail 'dev-test is still running'
        rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
        end
        begin
          Docker::Container.get('dev-logs')
          fail 'dev-logs is still running'
        rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
        end
      end

      it 'activates the dev profile', :vcr do
        pid = spawn %(spec/support/shipper_vcr "#{casette_name}" #{args.join ' '} > /dev/null)
        sleep 2
        expect(env).to include 'PROFILE' => 'dev'
        kill_with_children pid
      end

      it 'tails the logs', :vcr do
        outfile = "/tmp/shipper-rspec-dev.#{Process.pid}"
        pid = spawn %(spec/support/shipper_vcr "#{casette_name}" #{args.join ' '} > #{outfile})

        sleep 2
        kill_with_children pid
        output = File.read outfile

        expect(output).to match(/container 1 stdout/)
      end
    end
  end

  describe 'logs' do
    context 'spec/data/log.json' do
      let(:args) { ['log', 'spec/data/log.json'] }
      let(:container) { Docker::Container.get 'log-test' }
      let(:image) { Docker::Image.create 'fromImage' => 'hawknewton/log-test:0.0.1' }

      before do
        container = Docker::Container.create 'name' => 'log-test', 'Image' => image.id
        container.start
      end

      after { container.kill.delete }

      it 'tails the logs', :vcr do
        outfile = "/tmp/shipper-rspec.#{Process.pid}"
        pid = spawn %(spec/support/shipper_vcr "#{casette_name}" #{args.join ' '} > #{outfile})

        sleep 2
        Process.kill(:SIGTERM, pid)
        Process.waitpid pid
        output = File.read outfile

        expect(output).to match(/^\e\[0;32;49mlog-test\e\[0m: .+ container 1 stdout/)
        expect(output).to match(/^\e\[0;32;49mlog-test\e\[0m: .+ container 1 stderr/)
      end
    end
  end

  describe 'run' do
    context 'spec/data/single.json' do
      let(:args) { ['run', 'spec/data/single.json'] }
      let(:output) { subject }
      let(:container) { Docker::Container.get 'single-test' }
      let(:running?) { container.json['State']['Running'] }

      after { container.kill.delete }

      it 'starts the container', :vcr do
        subject
        expect(running?).to be true
      end

      it 'sends the name of the container to stdout', :vcr do
        expect(output).to match(/^Starting single-test/)
      end
    end

    context '-p qa spec/data/profiles.json' do
      let(:args) { ['run', '-p qa', 'spec/data/profiles.json'] }
      let(:container) { Docker::Container.get('profiles') }
      let(:image) { Docker::Image.get 'hawknewton/show-env' }
      let(:env) do
        url = URI.parse Docker.connection.url
        text = Net::HTTP.get URI.parse("http://#{url.host}:4567")
        text.split("\n").each_with_object({}) { |e, o| o.store(*e.split('=')) }
      end

      after { container.kill.delete }

      it 'overrides the tag', :vcr do
        subject
        expect(container.info['Image']).to eq image.id
      end

      it 'overrides the env', :vcr do
        subject
        sleep 1
        expect(env).to include 'NAME1' => 'VALUE1A'
      end

      it 'leaves existing env values alone', :vcr do
        subject
        sleep 1
        expect(env).to include 'NAME2' => 'VALUE2'
      end
    end
  end

  describe 'destroy' do
    context 'spec/data/single.json' do
      let(:args) { ['destroy', 'spec/data/single.json'] }
      before do
        c = Docker::Container.create 'name' => 'single-test', 'Image' => 'hawknewton/show-env'
        c.start
      end

      it 'kills the container', :vcr do
        subject
        begin
          Docker::Container.get 'single-test'
          fail 'Container still exists!'
        rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
        end
      end
    end
  end
end
