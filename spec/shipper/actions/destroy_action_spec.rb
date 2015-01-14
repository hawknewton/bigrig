describe DestroyAction do
  describe '#perform' do
    subject { described_class.new(test_file file).perform }

    context 'given json with a single container' do
      let(:file) { 'single.json' }

      context 'and the centainer is running' do
        before do
          allow(DockerAdapter).to receive(:running?).with('env').and_return true
          allow(DockerAdapter).to receive(:container_exists?).with('env').and_return true
        end

        it 'should kill the container and remove the image' do
          expect(DockerAdapter).to receive(:kill).with 'env'
          expect(DockerAdapter).to receive(:remove_container).with 'env'
          subject
        end
      end

      context 'and the container has exited' do
        before do
          allow(DockerAdapter).to receive(:running?).with('env').and_return false
          allow(DockerAdapter).to receive(:container_exists?).with('env').and_return true
        end

        it 'should remove the container' do
          expect(DockerAdapter).to receive(:remove_container).with 'env'
          subject
        end
      end
    end
  end
end
