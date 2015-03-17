module Bigrig
  describe DestroyAction do
    describe '#perform' do
      subject { described_class.new(active_containers.as_json).perform }
      let(:active_containers) { Descriptor.read test_file(file), profiles }
      let(:profiles) { [] }

      context 'given json with a single container' do
        let(:container) do
          image = Docker::Image.create 'fromImage' => 'hawknewton/show-env'
          Docker::Container.create 'Image' => image.id, 'name' => 'single-test'
        end

        let(:file) { 'single.json' }

        let(:exists?) do
          begin
            Docker::Container.get(container.id)
            true
          rescue Docker::Error::NotFoundError
            false
          end
        end

        after do
          begin
            container.kill.delete
          rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
          end
        end

        context 'and the container is running' do
          before { container.start }

          it 'kills and removes the container', :vcr do
            subject
            expect(exists?).to be false
          end
        end

        context 'and the container has exited' do
          before do
            container.start
            container.kill
          end

          it 'should remove the container', :vcr do
            subject
            expect(exists?).to be false
          end
        end
      end
    end
  end
end
