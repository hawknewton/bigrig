module Bigrig
  describe DevAction do
    describe '#perform' do
      subject { described_class.new descriptor.as_json }
      let(:descriptor) { Descriptor.new test_file(file), profiles }

      context 'when no profile is provided' do
        let(:profiles) { [] }
        let(:file) { 'dev.json' }

        it 'should initialize dev action' do
          expect { subject }.to_not raise_error
        end
      end
    end
  end
end
