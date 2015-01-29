describe Application do
  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :name= }

  it { is_expected.to respond_to :containers }
  it { is_expected.to respond_to :containers= }

  describe '::read' do
    subject { described_class.read file }

    context 'given a simple file' do
      let(:file) { test_file 'single.json' }

      its('containers.size') { is_expected.to eq 1 }

      it 'should set the container name' do
        expect(subject.containers[0].name).to eq 'single-test'
      end

      it 'should set the container tag' do
        expect(subject.containers[0].tag).to eq 'hawknewton/show-env'
      end
    end
  end
end
