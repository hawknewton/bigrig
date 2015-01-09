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
end
