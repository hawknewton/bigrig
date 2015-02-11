require 'docker'

# Monkey patch this in until https://github.com/swipely/docker-api/pull/244 is merged
class Docker::Image
  def self.create(opts = {}, creds = nil, conn = Docker.connection, &block)
      credentials = creds.nil? ? Docker.creds : creds.to_json
      headers = credentials && Docker::Util.build_auth_header(credentials) || {}
      body = ''
      conn.post(
        '/images/create',
        opts,
        :headers => headers,
        :response_block => response_block(body, &block)
      )
      json = Docker::Util.fix_json(body)
      image = json.reverse_each.find { |el| el && el.key?('id') }
      new(conn, 'id' => image && image.fetch('id'), :headers => headers)
  end

  # I have no goddamn idea
  def self.response_block(body)
    lambda do |chunk, remaining, total|
      body << chunk
      yield chunk if block_given?
    end
  end
end
