require 'docker'
require 'colorize'
require 'open4'

describe 'bigrig' do
  subject { `#{here}spec/support/bigrig_vcr "#{casette_name}" -f #{file} #{args.join ' '}` }
  let(:here) { '' }
  let(:output) { subject }
  let(:casette_name) do |example|
    "bigrig bin #{example.metadata[:full_description].gsub('"', '\\"')}"
  end

  describe 'dev' do
    context 'spec/data/scan.json' do
      let(:args) { ['-f', 'spec/data/scan.json', 'dev'] }
      let(:command) { %(spec/support/bigrig_vcr "#{casette_name}" #{args.join ' '}) }

      before do
        FileUtils.mkdir_p '/tmp/scan'
        FileUtils.touch '/tmp/scan/scan.me'

        %w(scanning uses_scanning some_ahole).each do |name|
          begin
            Docker::Container.get(name).kill.delete
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end
      end

      it 'restarts the container when the scanned file changes', :vcr do
        pid, _stdin, stdout, _stderr = Open4.popen4(command)
        drain_io stdout

        scanning = wait_for_containers(%w(scanning uses_scanning some_ahole)).first

        FileUtils.touch '/tmp/scan/scan.me'
        expect { Docker::Container.get('scanning').id }.to eventually_not(eq scanning.id).
          by_suppressing_errors
        wait_for { Docker::Container.get('uses_scanning').info['State']['Running'] }.to eq true

        Process.kill :SIGINT, pid
        Process.wait pid
      end

      it 'restarts dependant containers when the scanned file changes', :vcr do
        pid, _stdin, stdout, _stderr = Open4.popen4(command)
        drain_io stdout

        before_image = wait_for_containers(%w(uses_scanning scanning some_ahole)).first

        FileUtils.touch '/tmp/scan/scan.me'
        expect { Docker::Container.get('uses_scanning').id }.to eventually_not(eq before_image.id).
          by_suppressing_errors
        wait_for { Docker::Container.get('uses_scanning').info['State']['Running'] }.to eq true

        Process.kill :SIGINT, pid
        Process.wait pid
      end

      it 'leaves unaffected containers alone when the scanned file changes', :vcr do
        pid, _stdin, stdout, _stderr = Open4.popen4(command)
        drain_io stdout
        containers = wait_for_containers(%w(some_ahole uses_scanning scanning ))

        FileUtils.touch '/tmp/scan/scan.me'

        wait_for { Docker::Container.get('uses_scanning').id }.to_not eq containers[1].id
        wait_for { Docker::Container.get('scanning').id }.to_not eq containers[2].id

        expect(Docker::Container.get('some_ahole').id).to eq containers.first.id
        Process.kill :SIGINT, pid
        Process.wait pid
      end
    end

    context 'spec/data/dev.json' do
      let(:args) { ['-f', 'spec/data/dev.json', 'dev'] }
      let(:command) { %(spec/support/bigrig_vcr "#{casette_name}" #{args.join ' '}) }
      let(:env) do
        lambda do
          url = URI.parse Docker.connection.url
          text = Net::HTTP.get URI.parse("http://#{url.host}:4568")
          text.split("\n").each_with_object({}) { |e, o| o.store(*e.split('=')) }
        end
      end

      before do
        ['dev-test', 'dev-logs'].each do |container|
          begin
            Docker::Container.get(container).kill.delete
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end
      end

      it 'starts the containers', :vcr do
        pid = Open4.popen4(command).first
        begin
          expect { Docker::Container.get('dev-test').json['State']['Running'] }.
            to eventually(be true).by_suppressing_errors

          expect { Docker::Container.get('dev-logs').json['State']['Running'] }.
            to eventually(be true).by_suppressing_errors
        ensure
          Process.kill :SIGINT, pid
          Process.wait pid
        end
      end

      it 'destroys containers on exit', :vcr do
        pid = Open4.popen4(command).first
        Process.kill :SIGINT, pid
        Process.wait pid
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
        pid = Open4.popen4(command).first
        begin
          wait_for { Docker::Container.get('dev-test').info['State']['Running'] }.to eq true
          expect { env.call }.to eventually(include 'PROFILE' => 'dev').by_suppressing_errors
        ensure
          Process.kill :SIGINT, pid
          Process.wait pid
        end
      end

      it 'tails the logs', :vcr do
        pid, output = capture_stdout command
        Process.kill :SIGINT, pid
        Process.wait pid
        expect(output).to match(/container 1 stdout/)
      end
    end
  end

  describe 'logs' do
    context 'spec/data/log.json' do
      let(:args) { ['-f spec/data/log.json', 'log'] }
      let(:container) { Docker::Container.get 'log-test' }
      let(:image) { Docker::Image.create 'fromImage' => 'hawknewton/log-test:0.0.1' }

      before do
        container = Docker::Container.create 'name' => 'log-test', 'Image' => image.id
        container.start
      end

      # Killing the container will cause bigrig to exit naturally
      after { container.kill.delete }

      it 'tails the logs', :vcr do
        command = %(spec/support/bigrig_vcr "#{casette_name}" #{args.join ' '})
        _pid, output = capture_stdout command

        expect(output).to match(/^\e\[0;32;49mlog-test\e\[0m: .+ container 1 stdout/)
        expect(output).to match(/^\e\[0;32;49mlog-test\e\[0m: .+ container 1 stderr/)
      end
    end
  end

  describe 'run' do
    after { container.kill.delete }

    context 'spec/data/single.json' do
      let(:args) { ['run'] }
      let(:output) { subject }
      let(:container) { Docker::Container.get 'single-test' }
      let(:running?) { container.json['State']['Running'] }
      let(:file) { 'spec/data/single.json' }

      it 'starts the container', :vcr do
        subject
        expect(running?).to be true
      end

      it 'sends the name of the container to stdout', :vcr do
        expect(output).to match(/^Starting single-test/)
      end
    end

    context 'spec/data/profiles.json -p qa' do
      let(:args) { ['run', '-p qa'] }
      let(:container) { Docker::Container.get('profiles') }
      let(:image) { Docker::Image.get 'hawknewton/show-env' }
      let(:file) { 'spec/data/profiles.json' }
      let(:env) do
        lambda do
          url = URI.parse Docker.connection.url
          text = Net::HTTP.get URI.parse("http://#{url.host}:4567")
          text.split("\n").each_with_object({}) { |e, o| o.store(*e.split('=')) }
        end
      end

      it 'overrides the tag', :vcr do
        subject
        expect(container.info['Image']).to eq image.id
      end

      it 'overrides the env', :vcr do
        subject
        expect { env.call }.to eventually(include 'NAME1' => 'VALUE1A').by_suppressing_errors
      end

      it 'leaves existing env values alone', :vcr do
        subject
        expect { env.call }.to eventually(include 'NAME2' => 'VALUE2').by_suppressing_errors
      end
    end

    context 'spec/data/wait_for/bigrig.json' do
      let(:args) { ['run'] }
      let(:output) { subject }
      let(:file) { 'bigrig.json' }
      let(:here) { "#{File.expand_path '../..', __FILE__}/" }
      let(:container) { Docker::Container.get 'wait_for-test' }
      let(:result) do
        Docker::Container.get('wait_for-test').exec(['cat', '/tmp/result.txt']).first.first.strip
      end

      around do |example|
        Dir.chdir 'spec/data/wait_for' do
          example.run
        end
      end

      it 'waits for wait_for', :vcr do
        subject
        expect(result).to eq '2'
      end
    end

    context 'spec/data/wait_for_broken.json' do
      let(:command) { %(#{here}spec/support/bigrig_vcr "#{casette_name}" #{args.join ' '}) }
      let(:args) { ['run'] }
      let(:here) { "#{File.expand_path '../..', __FILE__}/" }
      let(:container) do
        Docker::Container.get('wait_for_broken-test')
      end

      around do |example|
        Dir.chdir 'spec/data/wait_for_broken' do
          example.run
        end
      end

      it 'fails with an error', :vcr do
        pid, output = capture_stdout command
        Process.kill :SIGINT, pid
        Process.wait pid
        expect(output).to match(/Error waiting for container/)
      end
    end
  end

  describe 'destroy' do
    context 'spec/data/single.json' do
      let(:args) { ['destroy'] }
      let(:file) { 'spec/data/single.json' }
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

  describe 'ship' do
    context 'spec/data/ship.json' do
      context 'with a version' do
        let(:args) { ['ship', version] }
        let(:dir) { Dir.mktmpdir }
        let(:file) do
          descriptor = {
            containers: {
              'ship-me' => {
                repo: "#{repo}:5000/test/ship-me",
                path: 'build'
              }
            }
          }
          file = Tempfile.new('bigrig').path
          File.write file, JSON.dump(descriptor)
          file
        end
        let(:here) { "#{File.expand_path '../..', __FILE__}/" }
        let(:registry) do
          Docker::Container.create(
            'name' => 'registry',
            'Image' => 'registry',
            'Env' => ['GUNICORN_OPTS=[--preload]'],
            'ExposedPorts' => {
              '5000/tcp' => {}
            },
            'HostConfig' => {
              'PortBindings' => { '5000/tcp' => [{ 'HostPort' => '5000' }] }
            }
          )
        end
        let(:version) { '1.2.3' }
        let(:repo) { URI.parse(Docker.connection.url).host }

        before do
          registry.start
        end

        after do
          registry.kill.delete
        end

        around do |example|
          FileUtils.copy_file file, File.join(dir, 'bigrig.json')
          FileUtils.cp_r "#{test_file('.')}/build", dir
          Dir.chdir dir do
            example.run
          end
        end

        it 'builds and pushes the image', :vcr do
          subject
          expect { Docker::Image.get "#{repo}:5000/test/ship-me:#{version}" }.to_not raise_error
        end

        context '-c' do
          let(:args) { ['ship', '-c', version] }

          it 'cleans the image when it''s done', :vcr do
            subject
            expect { Docker::Image.get "#{repo}:5000/test/ship-me:#{version}" }.
              to raise_error(Docker::Error::NotFoundError)
          end
        end
      end
      context 'with no version' do
        let(:args) { ['ship'] }
        let(:file) { test_file 'ship.json' }

        it 'raises an error' do
          expect(output).to match(/version is required/)
        end
      end
    end
  end
end
