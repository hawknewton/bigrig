module Bigrig
  describe LogTailer do

    describe '#create' do
      before do
        LogTailer.instance_variable_set :@colors, nil
        LogTailer.instance_variable_set :@color, nil
      end
      it 'reuses the same color for a given container' do
        expect(LogTailer).to receive(:new).with('container', :green).twice
        LogTailer.create 'container'
        LogTailer.create 'container'
      end

      it 'uses new colors for new containers' do
        expect(LogTailer).to receive(:new).with 'container1', :green
        expect(LogTailer).to receive(:new).with 'container2', :yellow

        LogTailer.create 'container1'
        LogTailer.create 'container2'
      end
    end
  end
end
