module Shipper
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
          expect(subject.map(&:name)).to match_array %w(test1 test2)
        end
      end
    end
  end
end
