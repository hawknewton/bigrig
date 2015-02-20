module Shipper
  describe DockerAdapter do

    describe '::build' do
      subject { described_class.build path }
      let(:path) { test_file 'build' }
      let(:image_id) { subject }

      it 'builds the given directory', :vcr do
        expect { Docker::Image.get(image_id) }.to_not raise_error
      end

      it 'passes build input to a block', :vcr do
        described_class.build path do |chunk|
          puts "chunk: #{chunk}"
        end
      end
    end

    describe '::container_exists?' do
      subject { described_class.container_exists?(name) }

      context 'when the container exists' do
        let!(:container) { Docker::Container.create 'name' => name, 'Image' => 'hawknewton/true' }
        let(:name) { 'container_exists' }

        after { container.remove }

        it 'is true', :vcr do
          is_expected.to be true
        end
      end

      context 'when the container does not exist' do
        let(:name) { 'container_does_not_exist' }

        it 'is false', :vcr do
          is_expected.to be false
        end
      end
    end

    describe '::image_id_by_tag' do
      subject { DockerAdapter.image_id_by_tag(tag) }

      context 'when the image exists' do
        let(:tag) { 'image_exists' }
        let!(:image) { Docker::Image.create 'fromImage' => 'hawknewton/true' }

        # Get the long id
        let(:image_id) { Docker::Image.get(image.id).id }

        before { image.tag 'repo' => tag }
        after { image.remove name: tag }

        it 'returns the image id', :vcr do
          is_expected.to eq image_id
        end
      end

      context 'when the image does not exist' do
        let(:tag) { 'hawknewton/true:not_exist' }

        before do
          begin
            image = Docker::Image.get tag
            image.remove name: tag
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end

        it 'raise a ImageNotFoundError', :vcr do
          expect { subject }.to raise_error ImageNotFoundError
        end
      end
    end

    describe '::kill' do
      subject { described_class.kill container_id }

      context 'given the container is running' do
        let(:container) { Docker::Container.create('Image' => image.id).tap(&:start) }
        let(:container_id) { container.id }
        let(:image) { Docker::Image.create 'fromImage' => 'hawknewton/show-env' }
        let(:running?) { container.json['State']['Running'] }
        let!(:kill) { subject }

        after { container.delete force: true }

        it 'should kill the container', :vcr do
          expect(running?).to be false
        end
      end

      context 'given the container does not exist' do
        let(:container_id) { 'doesnotexist' }

        it 'should raise an error', :vcr do
          expect { subject }.to raise_error ContainerNotFoundError
        end
      end
    end

    describe '::logs' do
      subject { described_class.logs(container.id) { |s, c| logs << [s, c] } }
      let(:logs) { [] }
      let(:image) { Docker::Image.create 'fromImage' => 'hawknewton/log-test:0.0.1' }
      let(:container) { Docker::Container.get 'log-test' }

      before  do
        Docker::Container.create('Image' => image.id, 'name' => 'log-test').start
      end

      after { container.kill.delete }

      it 'streams logs to a block', :vcr do
        allow(Docker::Container).to receive(:get).with(container.id, {}, anything).
          and_return container
        expect(container).to receive(:streaming_logs).
          with(follow: true, stdout: true, stderr: true).
          and_yield('stream #1', 'I am log message #1').
          and_yield('stream #2', 'I am log message #2')

        subject
        expect(logs).to include ['stream #1', 'I am log message #1']
        expect(logs).to include ['stream #2', 'I am log message #2']
      end
    end

    describe '::pull' do
      subject { described_class.pull repo }

      context 'given the repo exists' do
        let(:repo) { 'hawknewton/true:latest' }
        let(:image_id) { Docker::Image.get(repo).id }

        it 'returns the image id', :vcr do
          is_expected.to eq image_id
        end
      end

      context 'given the repo does not exist' do
        let(:repo) { 'hawknewton/doesnotexist' }

        it 'raises a RepoNotFoundError', :vcr do
          expect { subject }.to raise_error RepoNotFoundError
        end
      end

      context 'given a block to capture output' do
        let(:repo) { 'hawknewton/true' }
        let(:output) { '' }
        let(:block) { proc { |chunk| output << chunk } }
        let!(:image_id) { described_class.pull repo, &block }

        it 'should capture output', :vcr do
          expect(output).to match(/Pulling repository hawknewton\/true/)
        end
      end
    end

    describe '::remove_container' do
      subject { described_class.remove_container container_id }

      context 'when the container exists' do
        let(:container_id) { Docker::Container.create('Image' => 'hawknewton/true').id }
        let!(:remove) { subject }

        it 'should remove the container', :vcr do
          expect { Docker::Container.get container_id }.
            to raise_error { Docker::Error::NotFoundError }
        end
      end

      context 'when the container does not exist' do
        let(:container_id) { 'doesnotexist' }

        it 'raises a ContainerNotFoundError', :vcr do
          expect { subject }.to raise_error ContainerNotFoundError
        end
      end

      context 'when the container is running' do
        let(:container_id) do
          Docker::Container.create('Image' => 'hawknewton/true').tap(&:start).id
        end

        it 'raises a ContainerRunningError', :vcr do
          expect { subject }.to raise_error ContainerRunningError
        end
      end
    end

    describe '::run' do
      subject { DockerAdapter.run({ image_id: image_id }.merge opts) }

      context 'given an image_id that exists' do
        let(:image_id) { 'hawknewton/show-env' }
        let(:container_id) { subject }
        let(:container) { Docker::Container.get container_id }
        let(:running?) { container.json['State']['Running'] }

        context 'and a name' do
          let(:opts) { { name: name } }
          let(:name) { 'and_a_name' }

          # strip the leading '/' from the json name
          let(:container_name) { container.json['Name'][1..-1] }

          after { Docker::Container.get(name).kill!.delete }

          it 'starts the container with the right name', :vcr do
            expect(running?).to be true
            expect(container_name).to eq name
          end
        end

        context 'and a name and ports' do
          let(:free_port) { TCPServer.new('0.0.0.0', 0).addr[1] }
          let(:opts) { { name: name, ports: ["#{free_port}:80", '70'] } }
          let(:name) { 'with_ports' }
          let(:exposed_ports) { container.json['Config']['ExposedPorts'].map { |k, _| k } }
          let(:mapped_ports) do
            container.json['NetworkSettings']['Ports'].each_with_object({}) do |arr, hash|
              hash[arr[0]] = arr[1][0]['HostPort']
            end
          end

          after { Docker::Container.get(name).kill!.delete }

          it 'starts the container with ports exposed', :vcr do
            expect(running?).to be true
            expect(exposed_ports).to eq ['70/tcp', '80/tcp']
            expect(mapped_ports).to include '80/tcp'
            expect(mapped_ports).to include '70/tcp'

            # Because the free port will move around under VCR we can't actually
            # assert anything
            expect(mapped_ports['80/tcp'].to_i).to be_a Fixnum
            expect(mapped_ports['70/tcp'].to_i).to be_a Fixnum
          end
        end

        context 'and a name and env variables' do
          let(:name) { 'with_env' }
          let(:opts) { { name: name, env: { 'NAME1' => 'VALUE1', 'NAME2' => 'VALUE2' } } }
          let(:envs) { container.json['Config']['Env'] }

          after { Docker::Container.get(name).kill!.delete }

          it 'starts the container with env set', :vcr do
            expect(running?).to be true
            expect(envs).to include 'NAME1=VALUE1'
            expect(envs).to include 'NAME2=VALUE2'
          end
        end
      end
    end

    describe '::running?' do
      subject { described_class.running? container_id }
      let(:result) { subject }

      context 'when the container is running' do
        let(:container) do
          Docker::Container.create('Image' => 'hawknewton/show-env')
        end
        let(:container_id) { container.id }

        before { container.start }
        after { container.delete force: true }

        it 'returns true', :vcr do
          expect(result).to be true
        end
      end

      context 'when the container is not running' do
        let(:container) do
          Docker::Container.create('Image' => 'hawknewton/show-env')
        end
        let(:container_id) { container.id }

        after { container.delete force: true }

        it 'returns false', :vcr do
          expect(result).to be false
        end
      end

      context 'when the container does not exist', :vcr do
        let(:container_id) { 'doesnotexist' }

        it 'returns false' do
          expect(result).to be false
        end
      end
    end
  end
end
