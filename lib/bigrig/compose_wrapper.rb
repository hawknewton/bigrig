require 'pty'
require 'english'

module Bigrig
  class ComposeWrapper
    def initialize(profiles, args)
      @args = args
      @profiles = profiles
    end

    def run
      wait_thread = launch_compose

      begin
        while (s = output.sysread 1024)
          STDOUT.write s
        end
      # rubocop:disable Lint/HandleExceptions
      rescue EOFError
      end
      # rubocop:enable Lint/HandleExceptions

      wait_thread.join
      exitstatus
    end

    private

    attr_accessor :args, :output, :profiles, :exitstatus

    def docker_command
      "docker-compose -f - #{@args.map { |a| "\"#{a}\"" }.join ' '}"
    end

    def compose_yml
      @compose_yml ||= Renderer.new(profiles).render
    end

    def exitstatus
      $CHILD_STATUS.exitstatus
    end

    def launch_compose
      @output, input, pid = PTY.spawn docker_command
      send_compose_yml input

      Thread.new do
        Process.wait pid
      end
    end

    def send_compose_yml(input)
      input.write compose_yml
      input.write ""
      input.flush

      lines_read = 0
      loop do
        output.sysread(1) == "\n" && lines_read += 1
        lines_read == compose_yml.lines.count && break
      end
    end
  end
end
