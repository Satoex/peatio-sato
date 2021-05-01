require 'memoist'
require 'faraday'
require 'better-faraday'

module Sato
    class Client
      Error = Class.new(StandardError)
      class ConnectionError < Error; end

      class ResponseError < Error
        def initialize(code, msg)
          @code = code
          @msg = msg
        end

        def message
          "#{@msg} (#{@code})"
        end
      end

      extend Memoist

      def initialize(endpoint)
        @json_rpc_endpoint = URI.parse(endpoint)
      end

      def json_rpc(method, params = [])
        response = connection.post \
          '/',
          { jsonrpc: '1.0', method: method, params: params }.to_json,
          { 'Accept'       => 'application/json',
            'Content-Type' => 'application/json' }
        response.assert_2xx!
        response = JSON.parse(response.body)
        response['error'].tap { |e| raise ResponseError.new(e['code'], e['message']) if e }
        response.fetch('result')
      rescue => e
        if e.is_a?(Error)
          raise e
        elsif e.is_a?(Faraday::Error)
          raise ConnectionError, e
        else
          raise Error, e
        end
      end

      def json_rpc_for_withdrawal(method, address, amount)
        response = connection.post \
        '/',
        { jsonrpc: '1.0', method: method, params: [
            address,
            amount.to_f,
        # '', REMOVED! because protocol dosent support this para
        # '', REMOVED! because protocol dosent support this para
        # options[:subtract_fee].to_s == 'true'  # subtract fee from transaction amount.
        ]}.to_json,
        { 'Accept'       => 'application/json',
          'Content-Type' => 'application/json' }
        response.assert_2xx!
        response = JSON.parse(response.body)
        response['error'].tap { |e| raise ResponseError.new(e['code'], e['message']) if e }
        response.fetch('result')
      rescue => e
        if e.is_a?(Error)
          raise e
        elsif e.is_a?(Faraday::Error)
          raise ConnectionError, e
        else
          raise Error, e
        end
      end

      private

      def connection
        Faraday.new(@json_rpc_endpoint).tap do |connection|
          unless @json_rpc_endpoint.user.blank?
            connection.basic_auth(@json_rpc_endpoint.user,
                                  @json_rpc_endpoint.password)
          end
        end
      end
      memoize :connection
    end
  end