# This thing's pretty stupid, but it should be good enough for the majority
# of cases
#
# Right not it breaks with ^, $, [, ], and \\
module Bigrig
  class GoMatcher
    ESCAPES = ['.', '(', ')']
    REPLACES = {
      /^\/?/ => '',
      /^/ => '^',
      /$/ => '/',
      '?' => '[^/]',
      '+' => '\\\\+',
      '*' => '[^/]+'
    }

    def initialize(glob)
      ESCAPES.each { |e| glob.gsub! e, "\\#{e}" }
      REPLACES.each { |k, v| glob.gsub! k, v }
      @regex = %r{#{glob}} # rubocop:disable Style/RegexpLiteral
    end

    def matches?(path)
      @regex.match("#{path}/") != nil
    end
  end
end
