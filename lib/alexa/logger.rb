module Alexa
  class Logger
    def initialize(app, formatting_char = '=')
      @app = app
      @formatting_char = formatting_char
    end

    def call(env)
      req = Rack::Request.new(env)

      @status, @headers, @response = @app.call(env)

      if req.path == '/alexa/intent_handlers'
        Rails.logger.debug @formatting_char * 50
        Rails.logger.debug "Alexa response\n\n"

        begin
          Rails.logger.debug JSON.pretty_generate(JSON.parse(@response.body)) unless @response.body.blank?
        rescue JSON::ParserError
          Rails.logger.error 'JSON error'
          Rails.logger.error @response.body
        end

        Rails.logger.debug @formatting_char * 50
      end

      [@status, @headers, @response]
    end
  end
end
