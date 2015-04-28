module Bigrig
  describe Tar do
    it 'honors the .dockerignore' do
      expect(Tar).to_not receive(:add_file).with anything, anything, 'ignoreme/ignore'
      expect(Tar).to_not receive(:add_file).with anything, anything, 'ignoreme2/ignore'
      expect(Tar).to receive(:add_file).with anything, anything, 'Dockerfile'
      Bigrig::Tar.create_dir_tar 'spec/data/build'
    end
  end
end
