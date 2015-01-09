describe DockerAdapter do
  describe '::run' do
    subject { DockerAdapter.run tag: 'testtag', name: 'testname' }

    context 'given an image with a tag' do
      let(:mock_container) { double Docker::Container }

      before do
        allow(Docker::Image).to receive(:exist?).with('testtag').and_return image_exists
        allow(Docker::Container).to receive(:create).and_return mock_container
        allow(mock_container).to receive :id
        allow(mock_container).to receive :start
      end

      context 'that exists' do
        let(:image_exists) { true }

        it 'should run the image' do
          expect(Docker::Container).to receive(:create).with hash_including(
            'Image' => 'testtag',
            'name'  => 'testname'
          )
          expect(mock_container).to receive :start
          subject
        end
      end

      context 'that does not exist' do
        let(:image_exists) { false }

        it 'should pull the image' do
          expect(Docker::Image).to receive(:create).with 'fromImage' => 'testtag'
          subject
        end
      end
    end
  end
end
