require 'open3'

module Bigrig
  class ComposeWrapper
    def initialize(profiles, args)
      @args = args
      @profiles = profiles
    end

    def run
      command = "docker-compose -f - #{@args.map { |a| "\"#{a}\"" }.join ' '}"
      stdin, @stdout, @stderr, wait_thr = Open3.popen3 command

      stdin.write docker_compose_yml
      stdin.close

      print_output

      exit wait_thr.value.exitstatus
    end

    private

    attr_accessor :args, :stdout, :stderr, :profiles

    def docker_compose_yml
      Renderer.new(profiles).render
    end

    def print_output
      while [stdout, stderr].select { |io| !io.eof? }.any?
        ready = IO.select([stderr, stdout], [])[0]
        ready.each { |io| print io.read }
      end
    end
  end
end
