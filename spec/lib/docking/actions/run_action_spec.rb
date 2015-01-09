describe RunAction do
  describe '::perform' do
    subject { described_class.new(test_file file).perform }

    context 'given a file with one container' do
      let(:file) { 'single.json' }

      it 'should spin up a single container' do
        expect(DockerAdapter).to receive(:image_id_by_tag).with('hawknewton/show-env').
          and_return 'showenv-testid'
        expect(DockerAdapter).to receive(:run).with hash_including(
          image_id: 'showenv-testid',
          name: 'env'
        )
        subject
      end
    end

    context 'given a file with multiple containers' do
      let(:file) { 'multiple.json' }

      before do
        allow(DockerAdapter).to receive(:image_id_by_tag).with('hnewton/env').
          and_return 'env-testid'
        allow(DockerAdapter).to receive(:image_id_by_tag).with('hnewton/test').
          and_return 'test-testid'
      end

      it 'spins up multiple containers' do
        expect(DockerAdapter).to receive(:run).with hash_including image_id: 'env-testid'
        expect(DockerAdapter).to receive(:run).with hash_including image_id: 'test-testid'
        subject
      end

      it 'launches both containers in parallel' do
        running = 0
        expect(DockerAdapter).to receive(:run).with hash_including(image_id: 'env-testid') do
          running += 1
          sleep 1
          running -= 1
        end

        expect(DockerAdapter).to receive(:run).with hash_including(image_id: 'test-testid') do
          sleep 0.5
          expect(running).to eq 1
        end
        subject
      end
    end

    context 'given a file with voles_from' do
      let(:file) { 'volumes.json' }

      before do
        allow(DockerAdapter).to receive(:image_id_by_tag).with('hnewton/env').
          and_return 'env-testid'
        allow(DockerAdapter).to receive(:image_id_by_tag).with('hnewton/test').
          and_return 'test-testid'
      end

      it 'should pass volumes_from to the right container' do
        allow(DockerAdapter).to receive(:run).with hash_including image_id: 'env-testid'
        expect(DockerAdapter).to receive(:run).with hash_including(
          image_id: 'test-testid',
          volumes_from: ['env']
        )
        subject
      end

      it 'starts the dependant container last' do
        running = 0
        allow(DockerAdapter).to receive(:run).with hash_including(image_id: 'env-testid') do
          running += 1
          sleep 1
          running -= 1
        end

        expect(DockerAdapter).to receive(:run).with hash_including(image_id: 'test-testid') do
          sleep 0.5
          expect(running).to eq 0
        end
        subject
      end
    end

    context 'given a file with a path' do
      let(:file) { 'path.json' }

      it 'builds the image before starting it' do
        expect(DockerAdapter).to receive(:build).
          with('path/to/Dockerfile').and_return('containerid')
        expect(DockerAdapter).to receive(:run).with hash_including image_id: 'containerid'

        subject
      end
    end
  end
end
