describe RunAction do
  describe '::perform' do
    subject { described_class.new(test_file(file), active_profiles).perform }
    let(:active_profiles) { [] }

    context 'given a file with one container' do
      let(:file) { 'single.json' }
      let!(:perform) { subject }
      let(:running?) { DockerAdapter.running? 'single-test' }

      after do
        begin
          container = Docker::Container.get 'single-test'
          container.kill.delete
        rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
        end
      end

      it 'should spin up a single container', :vcr do
        expect(running?).to be true
      end
    end

    context 'given a file with multiple containers' do
      let(:file) { 'multiple.json' }
      let(:running?) do
        DockerAdapter.running?('multiple-test1') && DockerAdapter.running?('multiple-test2')
      end
      let(:perform) { subject }

      after do
        begin
          c1 = Docker::Container.get 'multiple-test1'
          c1.kill.delete
        rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
        end
        begin
          c1 = Docker::Container.get 'multiple-test2'
          c1.kill.delete
        rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
        end
      end

      it 'spins up multiple containers', :vcr do
        perform
        expect(running?).to be true
      end

      it 'launches both containers in parallel', :vcr do
        running = 0
        expect(DockerAdapter).to receive(:run).with hash_including(name: 'multiple-test1') do
          running += 1
          sleep 1
          running -= 1
        end

        expect(DockerAdapter).to receive(:run).with hash_including(name: 'multiple-test2') do
          sleep 0.5
          expect(running).to eq 1
        end
        perform
      end
    end

    context 'given a file with volumes_from' do
      let(:file) { 'volumes.json' }
      let(:container) { Docker::Container.get 'mounts_volumes' }
      let(:volumes_from) { container.json['HostConfig']['VolumesFrom'] }
      let(:perform) { subject }

      after do
        begin
          c1 = Docker::Container.get 'mounts_volumes'
          c1.kill.delete
        rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
        end
        begin
          c1 = Docker::Container.get 'exports_volumes'
          c1.kill.delete
        rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
        end
      end

      it 'should pass volumes_from to the right container', :vcr do
        perform
        expect(volumes_from).to eq ['exports_volumes']
      end

      it 'starts the dependant container last', :vcr do
        running = 0
        allow(DockerAdapter).to receive(:run).with hash_including(name: 'exports_volumes') do
          running += 1
          sleep 1
          running -= 1
        end

        expect(DockerAdapter).to receive(:run).with hash_including(name: 'mounts_volumes') do
          sleep 0.5
          expect(running).to eq 0
        end
        perform
      end
    end

    context 'given a file with a path' do
      let(:file) { 'path.json' }
      let(:container) { Docker::Container.get subject }

      after do
        container.kill.delete
      end

      it 'builds the image before starting it', :vcr do
        skip 'VCR freaks out'
        expect(DockerAdapter).to receive(:build).
          with('spec/data/build').and_call_original

        subject
      end
    end

    context 'given a file with env variables' do
      let(:file) { 'env.json' }

      it 'passes the environemnt variables to docker' do
        allow(DockerAdapter).to receive(:image_id_by_tag).with('hawknewton/show-env').
          and_return 'env-testid'
        expect(DockerAdapter).to receive(:run).with hash_including(
          image_id: 'env-testid',
          env: { 'NAME1' => 'VALUE1', 'NAME2' => 'VALUE2' }
        )

        subject
      end
    end

    context 'given a file with ports' do
      let(:file) { 'ports.json' }

      it 'passes ports to docker' do
        allow(DockerAdapter).to receive(:image_id_by_tag).with('hawknewton/show-env').
          and_return 'env-testid'
        expect(DockerAdapter).to receive(:run).with hash_including(
          image_id: 'env-testid',
          ports: ['80:8080', '12345']
        )

        subject
      end
    end

    context 'with a file with active profiles' do
      let(:file) { 'profiles.json' }
      let(:active_profiles) { ['qa'] }

      after do
        container = Docker::Container.get 'profiles'
        container.kill.delete
      end

      it 'uses the overridden image', :vcr do
        subject
        container = Docker::Container.get 'profiles'
        image = Docker::Image.get 'hawknewton/show-env'
        expect(container.info['Image']).to eq image.id
      end
    end
  end
end
