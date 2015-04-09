module Bigrig
  describe DependencyGraph do
    describe '#resolve' do
      subject { described_class.new(containers).resolve }
      context 'given two containers, one depending on the other' do
        let(:containers) do
          [
            Container.new(name: 'test2', volumes_from: ['test1']),
            Container.new(name: 'test1')
          ]
        end

        it 'resolves in the correct order' do
          expect(subject.map(&:name)).to eq %w(test1 test2)
        end
      end
    end

    describe '#resolve_subtree' do
      subject { described_class.new(containers).resolve_subtree target }
      context 'given three containers, two of which have a relationship' do
        let(:target) do
          containers[0]
        end

        let(:containers) do
          [
            Container.new(name: 'target', volumes_from: ['test2']),
            Container.new(name: 'test1', volumes_from: ['target']),
            Container.new(name: 'test2')
          ]
        end

        it 'resolves only related containers' do
          expect(subject.map(&:name)).to eq %w(target test1)
        end
      end
    end
  end
end
