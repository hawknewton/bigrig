class RunAction
  attr_accessor :application

  def initialize(file, active_profiles)
    application = Application.read file, active_profiles
    @runner = Runner.new application
  end

  def perform
    @runner.run
  end
end
