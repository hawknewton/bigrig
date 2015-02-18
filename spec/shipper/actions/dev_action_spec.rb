module Shipper
  describe DevAction do
    describe '#perform' do
      subject { described_class.perform test_file(file), profiles }
      let(:profiles) { [] }
    end
  end
end
