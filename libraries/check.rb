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

include Opscode::Pingdom

module Opscode
  module Pingdom
    module Check

      def add_check(name,hostname,type,params)
        merged_params = { :name => name, :hostname => hostname, :type => type }
        merged_params.merge!(params)
        pingdom.post("checks",merged_params)
      end

      def delete_check(name,hostname,type)
        check = pingdom.checks.find {|c| c.name == name and c.hostname == hostname and c.type == type }
        pingdom.delete("checks/#{check.id}")
      end 

      def update_check(name,hostname,type,params)
        merged_params = { :name => name, :hostname => hostname, :type => type }
        merged_params.merge!(params)
        pingdom.put("checks/#{check.id}",merged_params)
      end

      def check_exists?(name,type,params)
        check = pingdom.checks.find {|c| c.name == name and c.type == type }
        check ? true : false
      end

    end
  end
end
