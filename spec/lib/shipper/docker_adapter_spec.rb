describe DockerAdapter do

  describe '::build' do
    subject { described_class.build path }
    let(:path) { 'path/to/Dockerfile' }

    it 'should build the given directory' do
      expect(Docker::Image).to receive(:build_from_dir).with(path).
        and_return double id: 'imageid'
      is_expected.to eq 'imageid'
    end
  end

  describe '::container_exists?' do
    subject { described_class.container_exists?('testname') }

    context 'when the container exists' do
      before do
        allow(Docker::Container).to receive(:get).with('testname').
          and_return double Docker::Container
      end

      it { is_expected.to be true }
    end
  end

  describe '::image_id' do
    subject { DockerAdapter.image_id_by_tag('testtag') }

    context 'when the image exists' do
      it 'returns the image id' do
        expect(Docker::Image).to receive(:get).with('testtag').
          and_return double id: 'testid'
        is_expected.to eq 'testid'
      end
    end

    context 'when the image does not exist' do
      it 'pulls the image from the registry' do
        expect(Docker::Image).to receive(:get).with('testtag').
          and_raise Docker::Error::NotFoundError
        expect(Docker::Image).to receive(:create).with('fromImage' => 'testtag').
          and_return double id: 'testid'
        is_expected.to eq 'testid'
      end
    end
  end

  describe '::kill' do
    subject { described_class.kill 'testname' }

    context 'given the container is running' do
      let(:mock_container) { double Docker::Container }

      before do
        allow(Docker::Container).to receive(:get).with('testname').and_return mock_container
      end

      it 'should kill the container' do
        expect(mock_container).to receive(:kill)
        subject
      end
    end
  end

  describe 'remove_container' do
    subject { described_class.remove_container 'testname' }

    context 'when the container exists' do
      let(:mock_container) { double Docker::Container }

      before do
        allow(Docker::Container).to receive(:get).with('testname').and_return mock_container
        allow(mock_container).to receive :delete
      end

      it 'should remove the container' do
        expect(mock_container).to receive :delete
        subject
      end

      it { is_expected.to be true }
    end

    context 'when the container does not exist' do
      before do
        allow(Docker::Container).to receive(:get).with('testname').
          and_raise Docker::Error::NotFoundError
      end

      it { is_expected.to be false }
    end
  end

  describe '::run' do
    subject { DockerAdapter.run opts }

    context 'given an image_id and a name' do
      let(:opts) do
        { env: { 'NAME1' => 'VALUE1' },
          image_id: 'testid',
          name: 'testname',
          ports: ['80:8080', '12345'],
          volumes_from: ['exports_volumes'] }
      end
      let(:mock_container) { double Docker::Container }

      it 'should run the image' do
        expect(Docker::Container).to receive(:create).with(hash_including(
          'Env'   => ['NAME1=VALUE1'],
          'Image' => 'testid',
          'name'  => 'testname',
          'ExposedPorts' => { '8080/tcp' => {}, '12345/tcp' => {} }
        )).and_return mock_container
        expect(mock_container).to receive(:start).with(hash_including(
          'PortBindings' => { '8080/tcp' => [{ 'HostPort' => '80' }], '12345/tcp' => [{}] },
          'VolumesFrom'  => ['exports_volumes']
        ))
        allow(mock_container).to receive :id
        subject
      end
    end
  end

  describe '::running?' do
    subject { described_class.running? 'testname' }
    let(:mock_container) { double Docker::Container }

    context 'when the container is running' do
      before do
        allow(Docker::Container).to receive(:get).with('testname').and_return mock_container
        allow(mock_container).to receive(:info).
          and_return('State' => { 'Running' => true })
      end

      it { is_expected.to be true }
    end

    context 'when the container does not exist' do
      before do
        allow(Docker::Container).to receive(:get).with('testname').and_return mock_container
        allow(mock_container).to receive(:info).and_raise Docker::Error::NotFoundError
      end

      it { is_expected.to be false }
    end
  end
end
