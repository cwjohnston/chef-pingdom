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

action :create do
  unless check_exists?(new_resource.name, new_resource.type)
    create_check(new_resource.name, new_resource.host, new_resource.type, new_resource.check_params)
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug("#{new_resource}: check of type #{new_resource.type} already exists for host #{new_resource.host} already exists")
    current_resource = load_current_resource
    if checks_differ?(current_resource, new_resource)
      Chef::Log.debug("#{new_resource}: parameters differ, attempting to update")
      update_check(new_resource.name, new_resource.type, new_resource.host, new_resource.check_params)
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.debug("#{new_resource}: parameters are unchanged, no update required")
    end
  end
end

action :pause do
  if check_exists?(new_resource.name, new_resource.type)
    status = check_status(new_resource.name, new_resource.type)
    case status
    when "up","down","unconfirmed_down","unknown"
      Chef::Log.debug("#{new_resource}: status of check is \"#{status}\", attempting to pause it.")
      pause_check(new_resource.name, new_resource.type)
      new_resource.updated_by_last_action(true)
    when "paused"
      Chef::Log.debug("#{new_resource}: status of check is paused, no action necessary." )
    end
  end
end

action :resume do
  if check_exists?(new_resource.name, new_resource.type)
    status = check_status(new_resource.name, new_resource.type)
    case status
    when "paused","unknown"
      Chef::Log.debug("#{new_resource}: status of check is \"#{status}\", attempting to resume it.")
      resume_check(new_resource.name, new_resource.type)
      new_resource.updated_by_last_action(true)
    when "up","down","unconfirmed_down"
      Chef::Log.debug("#{new_resource}: status of check is \"#{status}\", no action necessary." )
    end
  end
end

action :delete do
  if check_exists?(new_resource.name, new_resource.type)
    delete_check(new_resource.name, new_resource.type)
    new_resource.updated_by_last_action(true)
  end
end

def load_current_resource
  @current_resource = Chef::Resource::PingdomCheck.new(@new_resource.name)
  if check_exists?(@new_resource.name,@new_resource.type)
    @current_resource.type(@new_resource.type)
    @current_resource.host(@new_resource.host)
    @current_resource.id(check_id(@new_resource.name,@new_resource.type))
    @current_resource.check_params(check_details(@new_resource.name,@new_resource.type))
  end
  @current_resource
end
