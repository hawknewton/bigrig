module Bigrig
  class Container < BaseModel
    ARRAY_ATTRS = :volumes_from, :links, :hosts, :volumes, :wait_for
    attr_accessor :env, :name, :path, :ports, :tag, :volumes_from, :links, :hosts, :repo,
                  :volumes, :scan, :wait_for

    class << self
      def from_json(name, json)
        opts = [:env, :path, :ports, :tag,
                :repo, :scan].each_with_object(name: name) do |e, o|
          o[e] = json.send :[], e.to_s
        end
        ARRAY_ATTRS.each { |x| opts[x] = as_array json[x.to_s] }

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

      ARRAY_ATTRS.map { |a| "@#{a}" }.each do |attr|
        instance_variable_get(attr) || instance_variable_set(attr, [])
      end

      # Yes rubocop, I know this is a very stupid thing to do
      @env = Hash[*@env.map { |k, v| [k, eval("\"#{v}\"")] }.flatten] # rubocop:disable Lint/Eval
    end

    def dependencies
      volumes_from + links.map { |l| l.split(':').first }
    end
  end
end
