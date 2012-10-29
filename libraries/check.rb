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

# this proc will ensure that check params have strings for keys
# courtesy http://stackoverflow.com/a/8380073/1118434
s2s =
lambda do |h|
  Hash === h ?
    Hash[
      h.map do |k, v|
        [k.respond_to?(:to_s) ? k.to_s : k, s2s[v]]
      end
    ] : h
end

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

  clean_params = s2s[params]

  merged_params = { 'name' => name, 'host' => host }
  merged_params.merge!(clean_params)
  merged_params.delete('hostname') if merged_params.keys.include?('hostname')

  if merged_params['contactids'].class == Array
    cids = merged_params['contactids'].join(',')
    merged_params['contactids'] = cids
  end

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
  if params['contactids']
    cids = params['contactids'].join(',')
    params['contactids'] = cids
  end
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

  params = s2s[new_check.check_params]
  params.merge!({ 'hostname' => new_check.host  })

  requestheader_keys = params.keys.grep(/^requestheader\d*$/)

  unless requestheader_keys.empty? or requestheader_keys.nil?
    params.merge!({ 'requestheaders' => {} })
    params.select {|k,v| k.match(/^requestheader\d*$/)}.each do |k,v|
      params['requestheaders'].merge!(v.split(":")[0] => v.split(":")[1..-1].join(':'))
      params.delete(k)
    end
  end

  if params['contactids'].class == Array
    cids = params['contactids'].join(',')
    params['contactids'] = cids
  end

  params.keys.each do |k|
    Chef::Log.debug("current check param #{k} = " + current_check.check_params[k].to_s)
    Chef::Log.debug("new check param #{k} = " + params[k].to_s)
    unless current_check.check_params[k].to_s == params[k].to_s
      Chef::Log.debug("value of parameter #{k} differs \(current: #{current_check.check_params[k].to_s}, new: #{params[k].to_s}\)")
      modified = true
      return modified # we only need one parameter to differ, so return right now
    else
      modified = false
    end
  end
  return modified
end
