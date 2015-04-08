require 'colorize'

module Bigrig
  class LogAction
    def initialize(active_containers)
      @application = Application.from_json active_containers
    end

    def perform
      tailers = @application.containers.map { |c| LogTailer.create c.name }
      tailers.each(&:join)
    end
  end
end
