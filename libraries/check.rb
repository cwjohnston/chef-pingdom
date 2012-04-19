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

module Opscode
  module Pingdom
    module Check
      def validate_check_params(type,params)
        Chef::Log.debug("Pingdom: Attempting to validate parameters for check of type '#{type}'")
        valid_params = [ 'name', 'host', 'type', 'paused', 'resolution', 'contactids', 'sendtoemail',
          'sendtosms', 'sendtotwitter', 'sendtoiphone', 'sendtoandroid', 'sendnotificationwhendown',
          'notifyagainevery', 'notifywhenbackup' ]

        case type
        when 'http'
          %w{ url encryption port username password shouldcontain shouldnotcontain postdata requestheader }.each do |p|
            valid_params << p
          end
          Chef::Log.debug("Pingdom: The following parameters are considered valid for check type '#{type}': #{valid_params.inspect}")
        when 'httpcustom'
          %w{ url encryption port username password additionalurls }.each do |p|
            valid_params << p
          end
          Chef::Log.debug("Pingdom: The following parameters are considered valid for check type '#{type}': #{valid_params.inspect}")
        when 'tcp'
          %w{ port stringtosend stringtoexpect }.each do |p|
            valid_params << p
          end
          Chef::Log.debug("Pingdom: The following parameters are considered valid for check type '#{type}': #{valid_params.inspect}")
        when 'udp'
          %w{ port stringtosend stringtoexpect }.each do |p|
            valid_params << p
          end
          Chef::Log.debug("Pingdom: The following parameters are considered valid for check type '#{type}': #{valid_params.inspect}")
        when 'ping'
          # ping has no special attributes
        when 'dns'
          %w{ nameserver expectedip }.each do |p|
            valid_params << p
          end
          Chef::Log.debug("Pingdom: The following parameters are considered valid for check type '#{type}': #{valid_params.inspect}")
        when 'smtp'
          %w{ port username password encryption stringtoexpect }.each do |p|
            valid_params << p
          end
          Chef::Log.debug("Pingdom: The following parameters are considered valid for check type '#{type}': #{valid_params.inspect}")
        when 'pop3'
          %w{ port encryption stringtoexpect }.each do |p|
            valid_params << p
          end
          Chef::Log.debug("Pingdom: The following parameters are considered valid for check type '#{type}': #{valid_params.inspect}")
        when 'imap'
          %w{ port encryption stringtoexpect }.each do |p|
            valid_params << p
          end
          Chef::Log.debug("Pingdom: The following parameters are considered valid for check type '#{type}': #{valid_params.inspect}")
        end

        params.each_key do |k|
          Chef::Log.debug("Pingdom: Validating check parameter '#{k}'")
          unless valid_params.include?(k.to_s)
            Chef::Log.error("Pingdom: Encountered unknown check parameter '#{k}'")
            raise
          else
            Chef::Log.debug("Pingdom: Check parameter '#{k}' appears to be valid.")
          end
        end
      end

      def get_checks()
        begin
          request = Net::HTTP::Get.new("/api/#{API_VER}/checks", { 'App-Key' => new_resource.api_key })
          request.basic_auth(new_resource.username, new_resource.password)
          Chef::Log.debug("Pingdom: API connection configured as #{api.inspect}")
          Chef::Log.debug("Pingdom: API request configured as #{request.to_hash.inspect}")
          Chef::Log.debug("Pingdom: Sending API request...")
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

     def get_check_id(check_name, type)
        checks = get_checks()
        checks['checks'].each do |check|
          if check['name'] == check_name and check['type'] == type
            Chef::Log.debug("Pingdom: found check id #{check['id']} for check name #{check_name} of type #{type}")
            return check['id']
          end
        end
      end

      def get_check_name(check_id)
        checks = get_checks()
        checks['checks'].each do |check|
          if check['id'] == check_id
            Chef::Log.debug("Pingdom: found check name #{check['name']} for check id #{check_id}")
            return check['name']
          end
        end
      end

      def get_check(check_name, type)
        result = nil
        target = get_check_id(check_name, type)
        checks = get_checks()
        checks['checks'].each do |check|
          if check['id'] == target
            Chef::Log.debug("Pingdom: found details for check #{check_name} of type #{type}: #{check.inspect}")
            result = check
          end
        end
        return result
      end

      def check_exists?(check_name, type)
        answer = false
        checks = get_checks()
        checks['checks'].each do |check|
          if check['name'] == check_name and check['type'] == type
            Chef::Log.debug("Pingdom: found existing check (name: #{check['name']}, id: #{check['id']}, type: #{check['type']})")
            answer = true
          end
        end
        return answer
      end

      def add_check(name, host, type, params)
        begin
          Chef::Log.debug("Pingdom: Attempting to add check '#{name}' of type '#{type}' for host '#{host}' with parameters #{params.inspect}")
          form_data = { 'name' => name, 'host' => host, 'type' => type }
          validate_check_params(type, params)
          params.each do |k,v|
            form_data.merge!({ k => v})
          end
          request = Net::HTTP::Post.new("/api/#{API_VER}/checks", { 'App-Key' => new_resource.api_key })
          request.basic_auth(new_resource.username, new_resource.password)
          request.set_form_data(form_data)
          Chef::Log.debug("Pingdom: API connection configured as #{api.inspect}")
          Chef::Log.debug("Pingdom: API request configured as #{request.to_hash.inspect}")
          Chef::Log.debug("Pingdom: Constructed the following post data:\n#{form_data.inspect}")
          Chef::Log.debug("Pingdom: Sending API request...")
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
          Chef::Log.error("Pingdom: Error creating check: #{e}")
          raise
        end
      end

      def delete_check(check_id)
        begin
          result = false
          request = Net::HTTP::Delete.new("/api/#{API_VER}/checks/#{check_id}", { 'App-Key' => new_resource.api_key })
          request.basic_auth(new_resource.username, new_resource.password)
          Chef::Log.debug("Pingdom: API connection configured as #{api.inspect}")
          Chef::Log.debug("Pingdom: API request configured as #{request.to_hash.inspect}")
          Chef::Log.debug("Pingdom: Sending API request...")
          response = api.request(request)
          unless response.body.nil?
            Chef::Log.debug("Pingdom: Received response code #{response.code}")
            Chef::Log.debug("Pingdom: Retrieved the following response body: #{JSON.parse(response.body).inspect}")
            if response.code == '200'
              Chef::Log.info("Pingdom: Successfully deleted check id #{check_id}")
              result = true
            end
          else
            Chef::Log.error("Pingdom: Response body was empty!")
            raise
          end
          return result
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, JSON::ParserError => e
          Chef::Log.error("Pingdom: Error deleting check id #{check_id}: #{e}")
          raise
        end
      end

      def update_check(check_id)
        Chef::Log.error("Pingdom: updating checks is not currently supported!")
        raise
      end

    end
  end
end
