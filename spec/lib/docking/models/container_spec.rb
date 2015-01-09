describe Container do
  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :name= }
  it { is_expected.to respond_to :path }
  it { is_expected.to respond_to :path= }
  it { is_expected.to respond_to :tag }
  it { is_expected.to respond_to :tag= }
  it { is_expected.to respond_to :volumes_from }
  it { is_expected.to respond_to :volumes_from= }

  it 'accepts volumes_from as an array' do
    expect(Container.from_json('volumes_from' => ['test']).volumes_from).to be_kind_of Array
  end

  it 'wraps a single volumes_from in an array' do
    expect(Container.from_json('volumes_from' => 'test').volumes_from).to be_kind_of Array
  end

  it 'depends on containers it mounts volumes from' do
    expect(Container.from_json('volumes_from' => 'test').dependencies).to eq ['test']
  end

  describe '#dependencies' do
    it 'returns an empty array when no dependencies are present' do
      expect(Container.from_json({}).dependencies).to eq []
    end
  end

  describe '::from_json' do
    subject { Container.from_json json }
    context 'given json with a path' do
      let(:json) { { 'path' => '/path/to/Dockerfile' } }

      it 'sets the path' do
        expect(subject.path).to eq '/path/to/Dockerfile'
      end
    end
  end
end
