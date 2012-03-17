# Author:: Cameron Johnston (<cameron@needle.com>)
# 
# Copyright 2011, Needle, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rubygems'
require 'net/http'
require 'net/https'
require 'json'

module Kernel
  def Boolean(obj)
    return true if obj== true || obj =~ (/(true)$/i)
    return false if obj== false || obj.nil? || obj =~ (/(false)$/i)
    return obj
    #raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
  end
end

class Hash
  def diff(other)
    (self.keys + other.keys).uniq.inject({}) do |memo, key|
      unless self[key] == other[key] or other[key].nil?
        if self[key].kind_of?(Hash) &&  other[key].kind_of?(Hash)
          memo[key] = self[key].diff(other[key])
        else
          memo[key] = [self[key], other[key]]
        end
      end
      memo
    end
  end
end

module Opscode
  module Pingdom
    module Check

      API_HOST = 'api.pingdom.com'
      API_PORT = 443
      API_VER = '2.0'
      
      CHECK_PARAMS = {
        'shared' => [ 'name', 'host', 'hostname', 'type', 'paused', 'resolution', 'contactids', 'sendtoemail', 'sendtosms', 'sendtotwitter', 'sendtoiphone', 'sendtoandroid', 'sendnotificationwhendown', 'notifyagainevery', 'notifywhenbackup'],
        'http' => [ 'url', 'encryption', 'port', 'username', 'password', 'shouldcontain', 'shouldnotcontain', 'postdata', 'requestheader', 'requestheaders' ],
        'httpcustom' => [ 'url', 'encryption', 'port', 'username', 'password', 'additionalurls' ],
        'tcp' => [ 'port', 'stringtosend', 'stringtoexpect' ],
        'udp' => [ 'port', 'stringtosend', 'stringtoexpect' ],
        'ping' => [ ],
        'dns' => [ 'nameserver', 'expectedip' ],
        'smtp' => [ 'port', 'username', 'password', 'encryption', 'stringtoexpect' ],
        'pop3' => [ 'port', 'encryption', 'stringtoexpect' ],
        'imap' => [ 'port', 'encryption', 'stringtoexpect' ]
      }
      
      def validate_check_params(type, params)
        Chef::Log.debug("Pingdom: Attempting to validate parameters for check of type '#{type}'")
        valid_params = CHECK_PARAMS['shared'] | CHECK_PARAMS[type]
        Chef::Log.debug("Pingdom: The following parameters are considered valid for check type '#{type}': #{valid_params.inspect}")

        params.each do |k,v|
          if k == "contactids" and v.is_a?(String)
            params[k] = v.to_a
          end
          Chef::Log.debug("Pingdom: Validating check parameter '#{k}'")
          Chef::Log.debug("Pingdom: value for '#{k}' is '#{v}', class #{v.class}")
          unless valid_params.include?(k.to_s)
            Chef::Log.error("Pingdom: Encountered unknown check parameter '#{k}' for type #{type}.")
            raise
          else
            Chef::Log.debug("Pingdom: Check parameter '#{k}' appears to be valid for type #{type}.")
          end
        end
      end

      def sanitize_check_params(type, params)
        if validate_check_params(type, params)
          # when we query Pingdom for check details they return a rather annoying multi-dimensional hash that needs flattening
          clean_params = params.inject({}) { |h, (k, v)| h[k] = Boolean(v); h }
        end
        if clean_params.has_key?('contactids')
          # contactsid parameter needs to be posted as a comma seperated list of integers
          clean_params['contactids'] = clean_params['contactids'].join(',')
        end
        return clean_params
      end

      def get_checks(api_key, username, password)
        begin
          api = Net::HTTP.new(API_HOST, API_PORT)
          api.use_ssl = true
          api.verify_mode = OpenSSL::SSL::VERIFY_PEER
          request = Net::HTTP::Get.new("/api/#{API_VER}/checks", { 'App-Key' => api_key })
          request.basic_auth(username, password)
          Chef::Log.debug("Pingdom: API connection configured as #{api.inspect}")
          Chef::Log.debug("Pingdom: API request configured as #{request.to_hash.inspect}")
          Chef::Log.debug("Pingdom: Sending API request...")
          api.start
          response = api.request(request)
          unless response.body.nil?
            Chef::Log.debug("Pingdom: Received response code #{response.code}")
            Chef::Log.debug("Pingdom: Received the following response body: #{JSON.parse(response.body).inspect}")
            return JSON.parse(response.body)
          else
            Chef::Log.error("Pingdom: Response body was empty!")
            raise
          end
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, JSON::ParserError => e
          Chef::Log.error("Pingdom: Error retreiving checks: #{e}")
          raise
        end
      end

     def get_check_id(name, type, api_key, username, password)
        checks = get_checks(api_key, username, password)
        checks['checks'].each do |check|
          if check['name'] == name and check['type'] == type
            Chef::Log.debug("Pingdom: found check id #{check['id']} for check name #{name} of type #{type}")
            return check['id']
          end
        end
      end

      def get_check_name(id, api_key, username, password)
        checks = get_checks(api_key, username, password)
        checks['checks'].each do |check|
          if check['id'] == id
            Chef::Log.debug("Pingdom: found check name #{check['name']} for check id #{id}")
            return check['name']
          end
        end
      end

      def get_check_details(name, type, api_key, username, password)
        details = Hash.new
        id = get_check_id(name, type, api_key, username, password)
        begin
          api = Net::HTTP.new(API_HOST, API_PORT)
          api.use_ssl = true
          api.verify_mode = OpenSSL::SSL::VERIFY_PEER
          request = Net::HTTP::Get.new("/api/#{API_VER}/checks/#{id}", { 'App-Key' => api_key })
          request.basic_auth(username, password)
          Chef::Log.debug("Pingdom: API connection configured as #{api.inspect}")
          Chef::Log.debug("Pingdom: API request configured as #{request.to_hash.inspect}")
          Chef::Log.debug("Pingdom: Sending API request...")
          api.start
          response = api.request(request)
          unless response.body.nil?
            Chef::Log.debug("Pingdom: Received response code #{response.code}")
            Chef::Log.debug("Pingdom: Received the following response body: #{JSON.parse(response.body).inspect}")
            details = JSON.parse(response.body)
          else
            Chef::Log.error("Pingdom: Response body was empty!")
            raise
          end
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, JSON::ParserError => e
          Chef::Log.error("Pingdom: Error retreiving check details: #{e}")
          raise
        end

        #if details['check'].has_key?('contactids')
        #  unless details['check']['contactids'].is_a?(Array)
        #    details['check']['contactids'] = details['check']['contactids'].to_a
        #  end
        #end
 
        return details['check']
      end

      def check_exists?(name, type, api_key, username, password)
        answer = false
        checks = get_checks(api_key, username, password)
        checks['checks'].each do |check|
          if check['name'] == name and check['type'] == type
            Chef::Log.debug("Pingdom: found existing check (name: #{check['name']}, id: #{check['id']}, type: #{check['type']})")
            answer = true
          end
        end
        return answer
      end

      def check_modified?(name, host, type, params, api_key, username, password)
        difference = check_diff(name, host, type, params, api_key, username, password) 
        if difference.empty?
          return false
        else
          return true
        end
      end

      def check_diff(name, host, type, params, api_key, username, password)
        current_check = get_check_details(name, type, api_key, username, password)
        # delete some key,value pairs that will never be passed in via the chef resource
        %w{ id status created lasterrortime lasttesttime }.each do |unwanted|
          current_check.delete(unwanted)
        end
        # flatten the hash to a single dimension
        type_attributes = current_check['type'][type]
        current_check['type'] = type
        current_check.merge!(type_attributes)
        current_clean_params = sanitize_check_params(type, current_check)

        new_check = Hash.new
        new_check.merge!({ "name" => name })
        new_check.merge!({ "hostname" => host })
        new_check.merge!({ "type" => type })

        new_clean_params = sanitize_check_params(type, params)

        new_clean_params.each do |k,v|
          new_check.merge!({ k => v })
        end

        Chef::Log.debug("Pingdom: Comparing existing check with provided check configuration")
        Chef::Log.debug("Pingdom: Existing check parameters: #{current_check.inspect}")
        Chef::Log.debug("Pingdom: Provided check parameters: #{new_check.inspect}")

        difference = current_check.diff(new_check)

        Chef::Log.debug("Pingdom: Difference: #{difference.inspect}")
        
        return difference
      end

      def add_check(name, host, type, params, api_key, username, password)
        begin
          Chef::Log.debug("Pingdom: Attempting to add check '#{name}' of type '#{type}' for host '#{host}' with parameters #{params.inspect}")
          api = Net::HTTP.new(API_HOST, API_PORT)
          api.use_ssl = true
          api.verify_mode = OpenSSL::SSL::VERIFY_PEER
          form_data = { 'name' => name, 'host' => host, 'type' => type }
          clean_params = sanitize_check_params(type, params)
          clean_params.each do |k,v|
            form_data.merge!({ k => v})
          end
          request = Net::HTTP::Post.new("/api/#{API_VER}/checks", { 'App-Key' => api_key })
          request.basic_auth(username, password)
          request.set_form_data(form_data)
          Chef::Log.debug("Pingdom: API connection configured as #{api.inspect}")
          Chef::Log.debug("Pingdom: API request configured as #{request.to_hash.inspect}")
          Chef::Log.debug("Pingdom: Constructed the following post data:\n#{form_data.inspect}")
          Chef::Log.debug("Pingdom: Sending API request...")
          api.start
          response = api.request(request)
          unless response.body.nil?
            Chef::Log.debug("Pingdom: Received response code #{response.code}")
            Chef::Log.debug("Pingdom: Received the following response body: #{JSON.parse(response.body).inspect}")
            parsed_response = JSON.parse(response.body)
            if response.code == '200'
              Chef::Log.info("Pingdom: Successfully added check id #{parsed_response['check']['id']}")
              return parsed_response['check']['id']
            end
          else
            Chef::Log.error("Pingdom: Response body was empty!")
            raise
          end
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, JSON::ParserError => e
          Chef::Log.error("Pingdom: Error adding check: #{e}")
          raise
        end
      end

      def update_check(name, host, type, params, api_key, username, password)
        id = get_check_id(name, type, api_key, username, password)
        begin
          Chef::Log.debug("Pingdom: Attempting to update check '#{name}' of type '#{type}' for host '#{host}' with modified parameters #{params.inspect}")
          api = Net::HTTP.new(API_HOST, API_PORT)
          api.use_ssl = true
          api.verify_mode = OpenSSL::SSL::VERIFY_PEER
          form_data = { 'host' => host }
          clean_params = sanitize_check_params(type, params)
          clean_params.each do |k,v|
            form_data.merge!({ k => v})
          end
          request = Net::HTTP::Put.new("/api/#{API_VER}/checks/#{id}", { 'App-Key' => api_key })
          request.set_form_data(form_data)
          request.basic_auth(username, password)
          Chef::Log.debug("Pingdom: API connection configured as #{api.inspect}")
          Chef::Log.debug("Pingdom: API request configured as #{request.to_hash.inspect}")
          Chef::Log.debug("Pingdom: Constructed the following form data:\n#{request.body.inspect}")
          Chef::Log.debug("Pingdom: Sending API request...")
          api.start
          response = api.request(request)
          unless response.body.nil?
            Chef::Log.debug("Pingdom: Received response code #{response.code}")
            Chef::Log.debug("Pingdom: Received the following response body: #{JSON.parse(response.body).inspect}")
            parsed_response = JSON.parse(response.body)
            if response.code == '200'
              Chef::Log.info("Pingdom: Successfully updated check id #{id}")
              return id
            end
          else
            Chef::Log.error("Pingdom: Response body was empty!")
            raise
          end
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, JSON::ParserError => e
          Chef::Log.error("Pingdom: Error updating check: #{e}")
          raise
        end
      end

      def delete_check(id, api_key, username, password)
        begin
          result = false
          api = Net::HTTP.new(API_HOST, API_PORT)
          api.use_ssl = true
          api.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Delete.new("/api/#{API_VER}/checks/#{id}", { 'App-Key' => api_key })
          request.basic_auth(username, password)
          Chef::Log.debug("Pingdom: API connection configured as #{api.inspect}")
          Chef::Log.debug("Pingdom: API request configured as #{request.to_hash.inspect}")
          Chef::Log.debug("Pingdom: Sending API request...")
          api.start
          response = api.request(request)
          unless response.body.nil?
            Chef::Log.debug("Pingdom: Received response code #{response.code}")
            Chef::Log.debug("Pingdom: Retrieved the following response body: #{JSON.parse(response.body).inspect}")
            if response.code == '200'
              Chef::Log.info("Pingdom: Successfully deleted check id #{id}")
              result = true
            end
          else
            Chef::Log.error("Pingdom: Response body was empty!")
            raise
          end
          return result
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, JSON::ParserError => e
          Chef::Log.error("Pingdom: Error deleting check id #{id}: #{e}")
          raise
        end
      end

    end
  end
end
