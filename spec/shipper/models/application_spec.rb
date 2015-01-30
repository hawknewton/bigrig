describe Application do
  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :name= }

  it { is_expected.to respond_to :containers }
  it { is_expected.to respond_to :containers= }

  describe '::read' do
    subject { described_class.read test_file file }

    context 'given a simple file' do
      let(:file) { 'single.json' }

      its('containers.size') { is_expected.to eq 1 }

      it 'should set the container name' do
        expect(subject.containers[0].name).to eq 'single-test'
      end

      it 'should set the container tag' do
        expect(subject.containers[0].tag).to eq 'hawknewton/show-env'
      end
    end

    context 'given two containers with the same name' do
      let(:file) { 'duplicate.json' }

      example { expect { subject }.to raise_error(/have the same name: duplicate/) }
    end
  end
end
