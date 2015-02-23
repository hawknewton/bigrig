module Bigrig
  class BaseModel
    def initialize(args = {})
      args.each { |k, v| send "#{k}=", v }
    end
  end
end
