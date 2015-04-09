module Bigrig
  describe LogAction do
    describe '#perform' do
      subject { runner.perform }
      let(:active_containers) { Descriptor.read test_file(file), active_profiles }
      let(:active_profiles) { [] }
      let(:runner) { described_class.new(active_containers.as_json) }
      let(:file) { 'log.json' }
      let(:image) { Docker::Image.create 'fromImage' => 'hawknewton/log-test:0.0.1' }
      let(:container) { Docker::Container.get 'log-test' }

      before do
        begin
          Docker::Container.get('log-test').kill.delete
        rescue Docker::Error::NotFoundError # rubocop:disable Lint/HandleExceptions
        end
        Docker::Container.create('Image' => image.id, 'name' => 'log-test').start
      end

      after do
        container.kill.delete
      end

      it 'follows the log', :vcr do
        allow(Docker::Container).to receive(:get).
          with('log-test', {}, anything).and_return container
        allow(container).to receive(:streaming_logs).
          and_yield(:stdout, 'stdout message').
          and_yield(:stderr, 'stderr message')
        expect($stdout).to receive(:puts).with "\e[0;32;49mlog-test\e[0m: stdout message"
        expect_any_instance_of(LogTailer).to receive(:print).
          with "\e[0;32;49mlog-test\e[0m: \e[0;91;49mstderr message\e[0m"
        subject
      end
    end
  end
end
