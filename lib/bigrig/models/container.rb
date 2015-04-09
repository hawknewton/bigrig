module Bigrig
  class Container < BaseModel
    attr_accessor :env, :name, :path, :ports, :tag, :volumes_from, :links, :hosts, :repo,
                  :volumes, :scan

    class << self
      def from_json(name, json)
        opts = [:env, :path, :ports, :tag, :repo, :scan].each_with_object(name: name) do |e, o|
          o[e] = json.send :[], e.to_s
        end
        [:volumes_from, :links, :hosts, :volumes].each { |x| opts[x] = as_array json[x.to_s] }

        Container.new opts
      end

      private

      def as_array(value)
        value && [value].flatten.compact
      end
    end

    def initialize(*opts)
      super
      @env ||= {}
      @ports ||= []
      @volumes ||= []
      @volumes_from ||= []
      @links ||= []
      @hosts ||= []

      # Yes rubocop, I know this is a very stupid thing to do
      @env = Hash[*@env.map { |k, v| [k, eval("\"#{v}\"")] }.flatten] # rubocop:disable Lint/Eval
    end

    def dependencies
      volumes_from + links.map { |l| l.split(':').first }
    end
  end
end
