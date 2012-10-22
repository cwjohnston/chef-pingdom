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

module Opscode
  module Pingdom
    module Check

      def api
        Gem.clear_paths
        require 'pingdom-client'
        # sorry for sending useful debug information to /dev/null, but this sure gets noisy otherwise.
        @@api ||= ::Pingdom::Client.new(:username => new_resource.username, :password => new_resource.password, :key => new_resource.api_key, :logger => Logger.new('/dev/null'))
      end

      def create_check(name,host,type,params)
        merged_params = { :name => name, :host => host, :type => type }
        merged_params.merge!(params)
        response = api.post("checks",merged_params)
        if response.status == "200"
          Chef::Log.info("#{new_resource}: check created")
        else
          Chef::Log.fatal("#{new_resource}: unexpected response from api: " + response.body.inspect)
        end
      end

      def pause_check(name,type)
        params = { :paused => true }
        check = api.checks.find {|c| c.name == name and c.type == type }
        response = api.put("checks/#{check.id}",params)
        if response.status == "200"
          Chef::Log.info("#{new_resource}: check paused")
        else
          Chef::Log.fatal("#{new_resource}: unexpected response from api: " + response.body.inspect)
        end
      end

      def resume_check(name,type)
        params = { :paused => false }
        check = api.checks.find {|c| c.name == name and c.type == type }
        response = api.put("checks/#{check.id}",params)
        if response.status == "200"
          Chef::Log.info("#{new_resource}: check resumed")
        else
          Chef::Log.fatal("#{new_resource}: unexpected response from api: " + response.body.inspect)
        end
      end

      def delete_check(name,type)
        check = api.checks.find {|c| c.name == name and c.type == type }
        response = api.delete("checks/#{check.id}")
        if response.status == "200"
          Chef::Log.info("#{new_resource}: check deleted")
        else
          Chef::Log.fatal("#{new_resource}: unexpected response from api: " + response.body.inspect)
        end
      end 

      def update_check(name,type,host,params)
        merged_params = { :name => name, :host => host }
        merged_params.merge!(params)
        merged_params.delete('hostname') if merged_params.keys.include?('hostname')
        id = check_id(name,type)
        response = api.put("checks/#{id}",merged_params)
        if response.status == "200"
          Chef::Log.info("#{new_resource}: check updated")
        else
          Chef::Log.fatal("#{new_resource}: unexpected response from api: " + response.body.inspect)
        end
      end

      def check_exists?(name,type)
        check = api.checks.find {|c| c.name == name and c.type == type }
        check.nil? ? false : true
      end

      def check_status(name,type)
        check = api.checks.find {|c| c.name == name and c.type == type }
        check.status
      end

      def check_details(name,type)
        check = api.checks.find {|c| c.name == name and c.type == type }
        response = api.get("checks/#{check.id}")
        params = response.body['check']
        # when we query the existing check we get back a response containing
        # some nested parameters under the type key. flatten out the response to make comparison easier.
        params.merge!(params['type']["#{type}"])
        params['type'] = type
        params
      end

      def check_id(name,type)
        if check_exists?(name,type)
          check = api.checks.find {|c| c.name == name and c.type == type }
          check.id
        end
      end

      def checks_differ?(current_check,new_check)
        modified = false
        params = new_check.check_params
        params.merge!({ 'hostname' => new_check.host  })
        params.keys.each do |k|
          Chef::Log.debug("#{new_resource}: new check param #{k} = " + params[k].to_s)
          Chef::Log.debug("#{new_resource}: current check param #{k} = " + current_check.check_params[k].to_s)
          unless current_check.check_params[k].to_s == params[k].to_s
            Chef::Log.debug("#{new_resource}: value of parameter #{k} differs \(current: #{current_check.check_params[k].to_s}, new: #{new_check.check_params[k].to_s}\)")
            modified = true
            return modified # we only need one parameter to differ, so return right now
          else
            modified = false
          end
        end
        return modified
      end

    end
  end
end
