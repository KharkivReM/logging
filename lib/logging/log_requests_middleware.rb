# frozen_string_literal: true

require 'pry'
require 'rack'
require 'active_support/logger'
require 'json'

module Logging
  class LogRequestsMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      request_body = request.body.read
      log_request_and_response!(
        request: request_body,
        headers: env['HTTP_AUTHORIZATION'],
        url: request.path,
        response: response.first
      )

      [status, headers, response]
    end

    def log_request_and_response!(request:, headers:, url:, response:)
      # FIX #1
      # return if ['swagger', 'favicon.ico'].include?(url)
      return if ['/swagger', '/favicon.ico'].include?(url)

      # FIX #2 catch JSON parsing error
      unless request.empty?
        begin
          request = JSON.parse(request)
        rescue JSON::ParserError
          logger.error "Request is not JSON! Body: #{request}"
          return
        end
      end

      # FIX #3 catch JSON parsing error
      unless response.empty?
        begin
          response = JSON.parse(response)
        rescue JSON::ParserError
          logger.error "Response is not JSON! Body: #{response}"
          return
        end
      end
      Logging::Log.create!(
        request: request,
        headers: headers,
        url: url,
        response: response
      )
    end

    def logger
      return @logger if @logger

      @logger ||= ::ActiveSupport::Logger.new(STDOUT)
      @logger.level = ENV['logger_level'] || 'error'
      @logger
    end
    private :logger
  end
end
