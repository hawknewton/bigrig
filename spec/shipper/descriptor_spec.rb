describe Descriptor do
  subject { described_class.read test_file(file), profiles }

  context 'given a simple descriptor' do
    let(:file) { 'single.json' }
    let(:tag) { subject.as_json['single-test']['tag'] }
    let(:profiles) { [] }

    it 'returns JSON' do
      expect(tag).to eq 'hawknewton/show-env'
    end
  end

  context 'given a descriptor with active profiles ' do
    let(:file) { 'profiles.json' }
    let(:profiles) { ['qa'] }
    let(:env_vars) { subject.as_json['env_vars']['env'] }
    let(:tag) { subject.as_json['env_vars']['tag'] }

    it 'overrides present ENV values' do
      expect(env_vars).to include 'NAME1' => 'VALUE1A'
    end

    it 'leaves existing ENV values alone' do
      expect(env_vars).to include 'NAME2' => 'VALUE2'
    end

    it 'also overrides the tag' do
      expect(tag).to eq 'hawknewton/new-tag'
    end
  end
end
