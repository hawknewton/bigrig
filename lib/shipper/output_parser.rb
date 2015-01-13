class OutputParser
  def initialize
    @last_line = ''
  end

  def parse(input)
    json = JSON.parse input
    if json['stream'] || json['id'].nil?
      json['stream'] || "#{json['status']}\n"
    else
      parse_progress json
    end
  end

  private

  def last_line_length
    @last_line.strip.length
  end

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
