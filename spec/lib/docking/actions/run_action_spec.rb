describe RunAction do
  describe '::perform' do
    subject { described_class.new(test_file file).perform }

    context 'given a file with one container' do
      let(:file) { 'single.json' }

      it 'should spin up a single container' do
        expect(DockerAdapter).to receive(:run).with hash_including(
          tag: 'hawknewton/show-env',
          name: 'env'
        )
        subject
      end
    end

    context 'given a file with multiple containers' do
      let(:file) { 'multiple.json' }

      it 'spins up multiple containers' do
        expect(DockerAdapter).to receive(:run).with hash_including tag: 'hnewton/env'
        expect(DockerAdapter).to receive(:run).with hash_including tag: 'hnewton/test'
        subject
      end

      it 'launches both containers in parallel' do
        running = 0
        expect(DockerAdapter).to receive(:run).with hash_including(tag: 'hnewton/env') do
          running += 1
          sleep 1
          running -= 1
        end

        expect(DockerAdapter).to receive(:run).with hash_including(tag: 'hnewton/test') do
          sleep 0.5
          expect(running).to eq 1
        end
        subject
      end
    end

    context 'given a file with voles_from' do
      let(:file) { 'volumes.json' }

      it 'should pass volumes_from to the right container' do
        allow(DockerAdapter).to receive(:run).with hash_including tag: 'hnewton/env'
        expect(DockerAdapter).to receive(:run).with hash_including(
          tag: 'hnewton/test',
          volumes_from: ['env']
        )
        subject
      end

      it 'starts the dependant container last' do
        running = 0
        allow(DockerAdapter).to receive(:run).with hash_including(tag: 'hnewton/env') do
          running += 1
          sleep 1
          running -= 1
        end

        expect(DockerAdapter).to receive(:run).with hash_including(tag: 'hnewton/test') do
          sleep 0.5
          expect(running).to eq 0
        end
        subject
      end
    end
  end
end
