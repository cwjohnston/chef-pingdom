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


def api
  @@api ||= PingdomClient.new(new_resource.username,new_resource.password,new_resource.api_key)
end

def add_check(name,host,type,params)
  merged_params = { :name => name, :host => host, :type => type }
  merged_params.merge!(params)
  response = api.post("/checks", {:body => merged_params})
end

def pause_check(name,type)
  params = { :paused => true }
  check = api.checks.find {|c| c['name'] == name and c['type'] == type }
  response = api.put("/checks/#{check['id']}",{:body => params})
end

def resume_check(name,type)
  params = { :paused => false }
  check = api.checks.find {|c| c['name'] == name and c['type'] == type }
  response = api.put("/checks/#{check['id']}",{:body => params})
end

def delete_check(name,type)
  check = api.checks.find {|c| c['name'] == name and c['type'] == type }
  response = api.delete("/checks/#{check['id']}")
end 

def update_check(name,type,host,params)
  merged_params = { :name => name, :host => host }
  merged_params.merge!(params)
  merged_params.delete('hostname') if merged_params.keys.include?('hostname')
  Chef::Log.debug("#{new_resource}: merged params = " + merged_params.inspect)
  id = check_id(name,type)
  response = api.put("/checks/#{id}", {:body => merged_params})
end

def check_exists?(name,type)
  check = api.checks.find {|c| c['name'] == name and c['type'] == type }
  check.nil? ? false : true
end

def check_status(name,type)
  check = api.checks.find {|c| c['name'] == name and c['type'] == type }
  check['status']
end

def check_details(name,type)
  check = api.checks.find {|c| c['name'] == name and c['type'] == type }
  response = api.get("/checks/#{check['id']}")
  params = response.parsed_response['check']
  # when we query the existing check we get back a response containing
  # some nested parameters under the type key. flatten out the response to make comparison easier.
  params['type']["#{params['type'].keys.first}"].each do |k,v|
    params.merge!(k => v)
  end
  params['type'] = params['type'].keys.first
  params
end

def check_id(name,type)
  if check_exists?(name,type)
    check = api.checks.find {|c| c['name'] == name and c['type'] == type }
    check['id']
  end
end

def checks_differ?(current_check,new_check)
  modified = false
  params = new_check.check_params
  params.merge!({ 'hostname' => new_check.host  })
  params.keys.each do |k|
    Chef::Log.debug("new check param #{k} = " + params[k].to_s)
    Chef::Log.debug("current check param #{k} = " + current_check.check_params[k].to_s)
    unless current_check.check_params[k].to_s == params[k].to_s
      Chef::Log.debug("value of parameter #{k} differs \(current: #{current_check.check_params[k].to_s}, new: #{new_check.check_params[k].to_s}\)")
      modified = true
      return modified # we only need one parameter to differ, so return right now
    else
      modified = false
    end
  end
  return modified
end
