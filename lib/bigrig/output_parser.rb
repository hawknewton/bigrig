module Bigrig
  class OutputParser
    def self.parser_proc
      parser = OutputParser.new
      proc { |chunk| print parser.parse chunk }
    end

    def initialize
      @last_line = ''
      @buffer = ''
    end

    def parse(input)
      output = documents(input).map do |json|
        if json['errorDetail']
          "#{json['errorDetail']['message'].red}\n"
        elsif json['stream'] || json['id'].nil?
          json['stream'] || "#{json['status']}\n"
        else
          parse_progress json
        end
      end
      output.join
    end

    private

    def documents(str)
      @buffer += str
      documents = []
      begin
        loop do
          documents << JSON.parse(next_document)
        end
      rescue JSON::ParserError # rubocop:disable Lint/HandleExceptions
      end
      documents
    end

    def last_line_length
      @last_line.strip.length
    end

    # rubocop:disable all
    def next_document
      chars = @buffer.chars
      i = count = 0
      string = false

      while i < chars.length
        chars[i] == '"' && string = !string
        chars[i] == '\\' && i += 1
        unless string
          chars[i] == '{' && count += 1
          chars[i] == '}' && count -= 1
        end
        count == 0 && chars[0..i].join.strip.length > 0 && break
        i += 1
      end

      count == 0 && @buffer = (chars.join[i + 1..-1] || '')
      chars.join[0..i]
    end
    # rubocop:enable all

    def padding(line)
      if last_line_length > line.length
        padding = ' ' * (last_line_length - line.length)
      end
      @last_line = line
      padding || ''
    end

    def parse_progress(json)
      line = should_print_cr?(json['id']) ? "\n" : ''
      line << "#{json['id']}: #{json['status']} #{json['progress']}"
      line << padding(line) << "\r"
    end

    def should_print_cr?(id)
      @current_id ||= id
      if id != @current_id
        @current_id = id
        true
      else
        false
      end
    end
  end
end
