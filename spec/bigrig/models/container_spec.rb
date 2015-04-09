module Bigrig
  describe Container do
    it { is_expected.to respond_to :hosts= }
    it { is_expected.to respond_to :hosts }
    it { is_expected.to respond_to :links= }
    it { is_expected.to respond_to :links }
    it { is_expected.to respond_to :name }
    it { is_expected.to respond_to :name= }
    it { is_expected.to respond_to :path }
    it { is_expected.to respond_to :path= }
    it { is_expected.to respond_to :ports }
    it { is_expected.to respond_to :ports= }
    it { is_expected.to respond_to :repo }
    it { is_expected.to respond_to :repo= }
    it { is_expected.to respond_to :scan= }
    it { is_expected.to respond_to :scan }
    it { is_expected.to respond_to :tag }
    it { is_expected.to respond_to :tag= }
    it { is_expected.to respond_to :volumes_from }
    it { is_expected.to respond_to :volumes_from= }
    it { is_expected.to respond_to :volumes }
    it { is_expected.to respond_to :volumes= }

    it 'accepts volumes as an array' do
      expect(Container.from_json(nil, 'volumes' => ['test']).volumes).to be_kind_of Array
    end

    it 'wraps a single volumes in an array' do
      expect(Container.from_json(nil, 'volumes' => 'test').volumes).to be_kind_of Array
    end

    it 'accepts volumes_from as an array' do
      expect(Container.from_json(nil, 'volumes_from' => ['test']).volumes_from).to be_kind_of Array
    end

    it 'wraps a single volumes_from in an array' do
      expect(Container.from_json(nil, 'volumes_from' => 'test').volumes_from).to be_kind_of Array
    end

    it 'accepts links as an array' do
      expect(Container.from_json(nil, 'links' => ['machine:alias']).links).to be_kind_of Array
    end

    it 'wraps a single links in an array' do
      expect(Container.from_json(nil, 'links' => 'machine:alias').links).to be_kind_of Array
    end

    it 'accepts hosts as an array' do
      expect(Container.from_json(nil, 'links' => ['host:alias']).links).to be_kind_of Array
    end

    it 'wraps a single links in an array' do
      expect(Container.from_json(nil, 'hosts' => 'host:alias').links).to be_kind_of Array
    end

    it 'depends on containers it mounts volumes from' do
      expect(Container.from_json(nil, 'volumes_from' => 'test').dependencies).to eq ['test']
    end

    it 'depends on containers it links to' do
      expect(Container.from_json(nil, 'links' => 'machine:alias').dependencies).to eq ['machine']
    end

    describe '#dependencies' do
      it 'returns an empty array when no dependencies are present' do
        expect(Container.from_json(nil, {}).dependencies).to eq []
      end
    end

    describe '::from_json' do
      subject { Container.from_json name, json }
      let(:name) { 'name' }

      context 'with an empty json document' do
        let(:json) { {} }

        its(:env) { is_expected.to be_empty }
        its(:env) { is_expected.to be_a Hash }

        its(:volumes_from) { is_expected.to be_empty }
        its(:volumes_from) { is_expected.to be_a Array }

        its(:volumes) { is_expected.to be_empty }
        its(:volumes) { is_expected.to be_a Array }

        its(:ports) { is_expected.to be_a Array }
        its(:ports) { is_expected.to be_empty }
      end

      context 'given json with a path' do
        let(:json) { { 'path' => '/path/to/Dockerfile' } }

        it 'sets the path' do
          expect(subject.path).to eq '/path/to/Dockerfile'
        end
      end

      context 'given json with a scan' do
        let(:json) { { 'scan' => '/path/to/scan' } }

        it 'sets the path' do
          expect(subject.scan).to eq '/path/to/scan'
        end
      end

      context 'given json with env params' do
        let(:json) { { 'env' => { 'NAME1' => 'VALUE1', 'NAME2' => 'VALUE2' } } }

        it 'parses the environment variables' do
          expect(subject.env).to include(
            'NAME1' => 'VALUE1',
            'NAME2' => 'VALUE2'
          )
        end

        context 'that reference environment variables' do
          let(:json) { { 'env' => { 'NAME1' => "\#{ENV['NAME1']}" } } }

          before { ENV['NAME1'] = 'ENV1' }
          after { ENV['NAME1'] = nil }

          it 'retrieves the variable from the environemnt' do
            expect(subject.env).to include('NAME1' => 'ENV1')
          end
        end
      end

      context 'given json with ports' do
        let(:json) { { 'ports' => ['80:8080', '12345'] } }

        it 'has ports' do
          expect(subject.ports).to eq ['80:8080', '12345']
        end
      end
    end
  end
end
