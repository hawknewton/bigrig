require 'docker'

describe 'shipper' do
  subject { `spec/support/shipper_vcr "#{casette_name}" #{args.join ' '}` }
  let(:output) { system }
  let(:casette_name) do |example|
    "shipper bin #{example.metadata[:full_description].gsub('"', '\\"')}"
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
        expect(env).to include 'NAME1' => 'VALUE1A'
      end

      it 'leaves existing env values alone', :vcr do
        subject
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
