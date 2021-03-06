module Fog
  module AWS
    class SQS < Fog::Service

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :region, :host, :path, :port, :scheme, :persistent

      request_path 'fog/aws/requests/sqs'
      request :change_message_visibility
      request :create_queue
      request :delete_message
      request :delete_queue
      request :get_queue_attributes
      request :list_queues
      request :receive_message
      request :send_message
      request :set_queue_attributes

      class Mock

        def initialize(options={})
        end

      end

      class Real

        # Initialize connection to SQS
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   sqs = SQS.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #   * region<~String> - optional region to use, in ['eu-west-1', 'us-east-1', 'us-west-1', 'ap-southeast-1']
        #
        # ==== Returns
        # * SQS object with connection to AWS.
        def initialize(options={})
          @aws_access_key_id      = options[:aws_access_key_id]
          @aws_secret_access_key  = options[:aws_secret_access_key]
          @hmac = Fog::HMAC.new('sha256', @aws_secret_access_key)
          options[:region] ||= 'us-east-1'
          @host = options[:host] || case options[:region]
          when 'ap-southeast-1'
            'ap-southeast-1.queue.amazonaws.com'
          when 'eu-west-1'
            'eu-west-1.queue.amazonaws.com'
          when 'us-east-1'
            'queue.amazonaws.com'
          when 'us-west-1'
            'us-west-1.queue.amazonaws.com'
          else
            raise ArgumentError, "Unknown region: #{options[:region].inspect}"
          end
          @path       = options[:path]      || '/'
          @port       = options[:port]      || 443
          @scheme     = options[:scheme]    || 'https'
          @connection = Fog::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", options[:persistent])
        end

        def reload
          @connection.reset
        end

        private

        def path_from_queue_url(queue_url)
          queue_url.split('.com', 2).last
        end

        def request(params)
          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)
          path        = params.delete(:path)

          body = AWS.signed_params(
            params,
            {
              :aws_access_key_id  => @aws_access_key_id,
              :hmac               => @hmac,
              :host               => @host,
              :path               => path || @path,
              :port               => @port,
              :version            => '2009-02-01'
            }
          )

          args = {
            :body       => body,
            :expects    => 200,
            :idempotent => idempotent,
            :headers    => { 'Content-Type' => 'application/x-www-form-urlencoded' },
            :host       => @host,
            :method     => 'POST',
            :parser     => parser
          }
          args.merge!(:path => path) if path

          response = @connection.request(args)

          response
        end

      end
    end
  end
end
