Module Opscode
  Module Pingdom

    begin
      
      require 'pingdom-client'

      class Pingdom::Client
        def put(uri, params = {}, data, &block)
          response = @connection.put(@connection.build_url(uri, prepare_params(params)), data, "App-Key" => @options[:key], &block)
          update_limits!(response.headers['req-limit-short'], response.headers['req-limit-long'])
          response
        end

        def post(uri, params = {}, data, &block)
          response = @connection.post(@connection.build_url(uri, prepare_params(params)), data, "App-Key" => @options[:key], &block)
          update_limits!(response.headers['req-limit-short'], response.headers['req-limit-long'])
          response
        end

        def delete(uri, &block)
          response = @connection.delete(@connection.build_url(uri), "App-Key" => @options[:key], &block)
          update_limits!(response.headers['req-limit-short'], response.headers['req-limit-long'])
          response
        end
      end

    rescue
      Chef::Log.warn("Missing gem 'pingdom-client'")
    end

    def pingdom
      @@pingdom ||= Pingdom.Client.new::(:username => new_resource.username, :password => new_resource.password, :key => new_resource.api_key)
    end

  end
end