module Bigrig
  describe Descriptor do
    subject { described_class.read test_file(file), profiles }

    context 'given a simple descriptor' do
      let(:file) { 'single.json' }
      let(:tag) { subject.as_json['single-test']['tag'] }
      let(:repo) { subject.as_json['single-test']['repo'] }
      let(:profiles) { [] }

      it 'returns JSON' do
        expect(repo).to eq 'hawknewton/show-env'
        expect(tag).to eq '0.0.1'
      end
    end

    context 'given a descriptor and an active but missing profile' do
      let(:file) { 'single.json' }
      let(:repo) { subject.as_json['single-test']['repo'] }
      let(:profiles) { ['dev'] }

      it 'returns JSON' do
        expect(repo).to eq 'hawknewton/show-env'
      end
    end

    context 'given a descriptor with active profiles ' do
      let(:file) { 'profiles.json' }
      let(:profiles) { ['qa'] }
      let(:env_vars) { subject.as_json['profiles']['env'] }
      let(:repo) { subject.as_json['profiles']['repo'] }

      it 'overrides present ENV values' do
        expect(env_vars).to include 'NAME1' => 'VALUE1A'
      end

      it 'leaves existing ENV values alone' do
        expect(env_vars).to include 'NAME2' => 'VALUE2'
      end

      it 'also overrides the repo' do
        expect(repo).to eq 'hawknewton/show-env'
      end
    end

    context 'given a descriptor that adds a container' do
      let(:file) { 'addscontainer.json' }
      let(:profiles) { ['new'] }
      let(:container) { subject.as_json['new'] }

      it 'adds the container' do
        expect(container).to_not be_nil
      end
    end
  end
end
