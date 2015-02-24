module Bigrig
  describe ShipAction do
    subject { described_class.new(file_name, version).perform }
    let(:dir) { Dir.mktmpdir }
    let(:version) { '1.2.3' }
    let(:file) { 'ship.json' }

    before do
      allow(DockerAdapter).to receive :tag
      allow(DockerAdapter).to receive :push
      allow(DockerAdapter).to receive :build
    end

    around do |example|
      FileUtils.copy_file test_file(file), File.join(dir, file_name)
      FileUtils.cp_r "#{test_file('.')}/build", dir
      Dir.chdir dir do
        example.run
      end
    end

    context 'using defaults' do
      let(:opts) { {} }
      let(:json) { JSON.parse File.read File.join(dir, 'bigrig-1.2.3.json') }
      let(:tag) { json['containers']['ship-me']['tag'] }
      let(:path) { json['containers']['ship-me']['path'] }
      let(:file_name) { 'bigrig.json' }
      let(:exists?) { File.exist? File.join(dir, "bigrig-#{version}.json") }

      it 'creates a bigrig.json with a version' do
        subject
        expect(exists?).to be true
      end

      it 'adds a tag' do
        subject
        expect(tag).to eq '1.2.3'
      end

      it 'removes the path' do
        subject
        expect(path).to be_nil
      end
    end

    context 'with a different file name' do
      let(:opts) { {} }
      let(:file_name) { 'custom.json' }
      let(:exists?) { File.exist? File.join(dir, "custom-#{version}.json") }

      it 'creates a file with that name' do
        subject
        expect(exists?).to be true
      end
    end
  end
end
