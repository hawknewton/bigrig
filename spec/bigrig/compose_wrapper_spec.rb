describe Bigrig::ComposeWrapper do
  subject { wrapper.run }
  let(:wrapper) { Bigrig::ComposeWrapper.new profiles, args }
  let(:args) { [] }
  let(:profiles) { %w(qa l1) }
  let(:process_status) { double Process::Status, exitstatus: 123 }
  let(:wait_thr) do
    double Thread, :alive? => false, :value => process_status
  end
  let(:stdin) { double IO }
  let(:stdout) { double IO }
  let(:stderr) { double IO }

  before do
    allow(Open3).to receive(:popen3).and_return [stdin, stdout, stderr, wait_thr]
    allow(wrapper).to receive :exit
    allow(stdin).to receive :write
    allow(stdin).to receive :close
    allow(stdout).to receive(:eof?).and_return true
    allow(stderr).to receive(:eof?).and_return true
  end

  around do |example|
    in_data_dir 'compose_wrapper_spec' do
      example.run
    end
  end

  it 'invokes docker-compose' do
    expect(Open3).to receive(:popen3)
    subject
  end

  it 'uses stdin for docker-compose.yml' do
    expect(Open3).to receive(:popen3).with 'docker-compose -f - '
    subject
  end

  it 'exits with the exit code of docker-compose' do
    expect(wrapper).to receive(:exit).with 123
    subject
  end

  it 'passes in the docker-compose.yml via stdin' do
    expect(stdin).to receive(:write).with "machine1:\n  image: ubuntu\n"
    subject
  end

  it 'passes any profiles to the renderer' do
    expect(Bigrig::Renderer).to receive(:new).with(%w(qa l1)).and_call_original
    subject
  end

  context 'given arguments' do
    let(:args) { %w(ready steady go) }

    it 'passes the arguments to docker-compose' do
      expect(Open3).to receive(:popen3).with 'docker-compose -f - "ready" "steady" "go"'

      subject
    end
  end

end
