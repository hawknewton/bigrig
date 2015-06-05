module Bigrig
  describe RunAction do
    describe '::perform' do
      subject { described_class.new(descriptor.as_json).perform }
      let(:descriptor) { Descriptor.read test_file(file), active_profiles }
      let(:active_profiles) { [] }

      context 'given a file with one container' do
        let(:file) { 'single.json' }
        let(:running?) { DockerAdapter.running? 'single-test' }

        after do
          begin
            container = Docker::Container.get 'single-test'
            container.kill.delete
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end

        it 'should spin up a single container', :vcr do
          subject
          expect(running?).to be true
        end

        context 'when a dead container exists' do
          before do
            container = Docker::Container.create 'Image' => 'hawknewton/show-env',
                                                 'name' => 'single-test'
            container.start.kill
          end

          it 'should remove existing containers', :vcr do
            subject
            expect(running?).to be true
          end
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

        before do
          allow_any_instance_of(Waiter).to receive :wait_if_needed
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

      context 'given a file with links' do
        let(:file) { 'links.json' }
        let(:container) { Docker::Container.get 'uses_service' }
        let(:links) { container.json['HostConfig']['Links'] }
        let(:perform) { subject }

        after do
          begin
            c1 = Docker::Container.get 'provides_service'
            c1.kill.delete
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
          begin
            c1 = Docker::Container.get 'uses_service'
            c1.kill.delete
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end

        it 'should pass links to the right container', :vcr do
          perform
          expect(links).to eq ['/provides_service:/uses_service/service']
        end
      end

      context 'given a file with hosts by ip' do
        let(:file) { 'hosts_ip.json' }
        let(:container) { Docker::Container.get 'uses_host' }
        let(:hosts) { container.json['HostConfig']['ExtraHosts'] }
        let(:perform) { subject }

        after do
          begin
            c1 = Docker::Container.get 'uses_host'
            c1.kill.delete
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end

        it 'should pass hosts to container', :vcr do
          perform
          expect(hosts).to include '1.2.3.4:host1'
          expect(hosts).to include '5.6.7.8:host2'
        end
      end

      context 'given a file with hosts by name' do
        let(:file) { 'hosts_name.json' }
        let(:container) { Docker::Container.get 'uses_host' }
        let(:hosts) { container.json['HostConfig']['ExtraHosts'] }
        let(:perform) { subject }

        after do
          begin
            c1 = Docker::Container.get 'uses_host'
            c1.kill.delete
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end

        it 'should lookup ips for hosts with a hostname', :vcr do
          perform
          expect(hosts[0]).to match(/^[0-9\.]+:host1$/)
        end
      end

      context 'given a file with volumes' do
        let(:file) { 'volumes.json' }
        let(:container) { Docker::Container.get 'volumes' }
        let(:volumes) { container.json['HostConfig']['Binds'] }
        let(:perform) { subject }

        after do
          begin
            c1 = Docker::Container.get 'volumes'
            c1.kill.delete
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end

        it 'should pass volumes to the right container', :vcr do
          perform
          expect(volumes).to eq ['/tmp/test:/test']
        end
      end

      context 'given a file with volumes_from' do
        let(:file) { 'volumes_from.json' }
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

          allow_any_instance_of(Waiter).to receive :wait_if_needed
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
          allow(DockerAdapter).to receive(:remove_container)
          allow(DockerAdapter).to receive(:image_id_by_tag).with('hawknewton/show-env:0.0.1').
            and_return 'env-testid'
          expect(DockerAdapter).to receive(:run).with hash_including(
            image_id: 'env-testid',
            env: { 'NAME1' => 'VALUE1', 'NAME2' => 'VALUE2' }
          )
          allow_any_instance_of(Waiter).to receive :wait_if_needed

          subject
        end
      end

      context 'given a file with ports' do
        let(:file) { 'ports.json' }

        it 'passes ports to docker' do
          allow(DockerAdapter).to receive(:remove_container)
          allow(DockerAdapter).to receive(:image_id_by_tag).with('hawknewton/show-env:0.0.1').
            and_return 'env-testid'
          expect(DockerAdapter).to receive(:run).with hash_including(
            image_id: 'env-testid',
            ports: ['80:8080', '12345']
          )
          allow_any_instance_of(Waiter).to receive :wait_if_needed

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

      context 'when activating profiles that do not exist' do
        let(:file) { 'profiles.json' }
        let(:active_profiles) { ['notreallyathing'] }

        after do
          begin
            container = Docker::Container.get 'profiles'
            container.delete force: true
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end

        it 'ignores the missing profile', :vcr do
          subject
          container = Docker::Container.get 'profiles'
          image = Docker::Image.get 'hawknewton/true'
          expect(container.info['Image']).to eq image.id
        end
      end
    end
  end
end
