describe Bigrig::ComposeWrapper do
  subject { wrapper.run }
  let(:wrapper) { Bigrig::ComposeWrapper.new profiles, args }
  let(:args) { [] }
  let(:profiles) { %w(qa l1) }
  let(:process_status) { double Process::Status, exitstatus: 123 }

  let(:input) { double IO }
  let(:output) { double IO }
  let(:pid) { 123 }

  before do
    allow(PTY).to receive(:spawn).and_return [output, input, pid]
    allow(output).to receive(:sysread).with(1).and_return "\n"
    allow(output).to receive(:sysread).with(1024).and_return nil
    allow(wrapper).to receive :exit
    allow(input).to receive :write
    allow(input).to receive :flush
    allow(Process).to receive :wait
  end

  around do |example|
    in_data_dir 'compose_wrapper_spec' do
      example.run
    end
  end

  it 'invokes docker-compose' do
    expect(PTY).to receive(:spawn)
    subject
  end

  it 'uses input for docker-compose.yml' do
    expect(PTY).to receive(:spawn).with 'docker-compose -f - '
    subject
  end

  it 'passes in the docker-compose.yml via stdin' do
    expect(input).to receive(:write).with "machine1:\n  image: ubuntu\n"
    subject
  end

  it 'passes any profiles to the renderer' do
    expect(Bigrig::Renderer).to receive(:new).with(%w(qa l1)).and_call_original
    subject
  end

  context 'given arguments' do
    let(:args) { %w(ready steady go) }

    it 'passes the arguments to docker-compose' do
      expect(PTY).to receive(:spawn).with 'docker-compose -f - "ready" "steady" "go"'

      subject
    end
  end

end
