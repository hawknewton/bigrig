module Bigrig
  class DevAction
    def initialize(file, profiles = [])
      @file = file
      profiles.include?('dev') || profiles << 'dev'
      @profiles = profiles
    end

    def perform
      RunAction.new(@file, @profiles).perform
      [:SIGTERM, :SIGINT].each { |s| Signal.trap(s) { DestroyAction.new(@file).perform } }
      LogAction.new(@file).perform
    end
  end
end
