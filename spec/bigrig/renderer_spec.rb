describe Bigrig::Renderer do
  subject { renderer.render }
  let(:renderer) { Bigrig::Renderer.new profiles }
  let(:profiles) { %w(qa l1) }

  it 'renders docker-compose.yml.erb' do
    in_data_dir 'renderer' do
      expect(subject).to eq "2 + 2 = 4\n"
    end
  end

  it 'makes profiles available to the erb' do
    in_data_dir 'renderer_profiles' do
      expect(subject).to eq "qa l1\n"
    end
  end

  it 'has cute little helper methods' do
    in_data_dir 'renderer_helper_methods' do
      expect(subject).to eq "qa is active\ndev is not active\n"
    end
  end
end
