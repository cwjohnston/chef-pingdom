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

include Opscode::Pingdom::Check

action :add do
  if check_exists?(@new_resource.name, @new_resource.type, @new_resource.api_key, @new_resource.username, @new_resource.password)
    Chef::Log.debug("Pingdom: #{@new_resource.type} check #{@new_resource.name} already exists, so I will not attempt to create it again.")
  else
    if add_check(@new_resource.name, @new_resource.host, @new_resource.type, @new_resource.check_params, @new_resource.api_key, @new_resource.username, @new_resource.password)
      @new_resource.updated_by_last_action(true)
    end
  end
end

action :update do
  if check_exists?(@new_resource.name, @new_resource.type, @new_resource.api_key, @new_resource.username, @new_resource.password) and check_modified?(@new_resource.name, @new_resource.host, @new_resource.type, @new_resource.check_params, @new_resource.api_key, @new_resource.username, @new_resource.password)
    Chef::Log.debug("Pingdom: #{@new_resource.type} check #{@new_resource.name} already exists, but its attributes have changed so I will attempt to update it.")
    if update_check(@new_resource.name, @new_resource.host, @new_resource.type, @new_resource.check_params, @new_resource.api_key, @new_resource.username, @new_resource.password)
      @new_resource.updated_by_last_action(true)
    end
  else
    Chef::Log.warn("Pingdom: #{@new_resource.type} check #{@new_resource.name} was not modified. No update needed.")
  end
end

action :delete do
  unless check_exists?(@new_resource.name, @new_resource.type, @new_resource.api_key, @new_resource.username, @new_resource.password)
    Chef::Log.debug("Pingdom: #{@new_resource.type} check #{@new_resource.name} does not exist, so I will not attempt to delete it.")
  else
    check_id = get_check_id(@new_resource.name, @new_resource.type, @new_resource.api_key, @new_resource.username, @new_resource.password)
    Chef::Log.debug("Pingdom: resolved check #{@new_resource.name} of @new_resource.type #{@new_resource.type} to check id #{check_id}")
    if delete_check(check_id, @new_resource.api_key, @new_resource.username, @new_resource.password)
      @new_resource.updated_by_last_action(true)
    end
  end
end
