module Shipper
  class Container < BaseModel
    attr_accessor :env, :name, :path, :ports, :tag, :volumes_from

    class << self
      def from_json(name, json)
        opts = [:env, :path, :ports, :tag].each_with_object(name: name) do |e, o|
          o[e] = json.send :[], e.to_s
        end
        opts[:volumes_from] = [json['volumes_from']].flatten.compact if json['volumes_from']

        Container.new opts
      end

      private

      def parse_env(list)
        pairs = list.map do |var|
          if var.include? '='
            var.split('=', 2).flatten
          else
            [var, ENV[var]]
          end
        end
        Hash[*pairs.flatten]
      end
    end

    def initialize(*opts)
      super
      @env = {} unless @env
      @ports = [] unless @ports
      @volumes_from = [] unless @volumes_from

      # Yes rubocop, I know this is a very stupid thing to do
      @env = Hash[*@env.map { |k, v| [k, eval("\"#{v}\"")] }.flatten] # rubocop:disable Lint/Eval
    end

    def dependencies
      volumes_from
    end
  end
end
