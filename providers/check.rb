# Author:: Cameron Johnston (<cameron@needle.com>)
#
# Copyright 2011-2013, Needle, Inc.
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

require 'json'

def load_gem
  begin
    require 'rest-client'
  rescue LoadError
    Chef::Log.info "rest-client gem not found. Attempting to install "
    chef_gem 'rest-client' do
      version node['pingdom']['api']['gem']['version']
    end
  end
end

def initialize(new_resource, run_context=nil)
  super
  load_gem
  pingdom_api
end

action :add do
  unless check_exists?(new_resource.name, new_resource.type)
    response = add_check(new_resource.name, new_resource.host, new_resource.type, new_resource.check_params)
    if response.code == 200
      Chef::Log.info("#{new_resource}: check added")
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.fatal("#{new_resource}: failed to add check, unexpected response from api: " + response.parsed_response.inspect)
      raise unless new_resource.ignore_failure
    end
  else
    Chef::Log.debug("#{new_resource}: check of type #{new_resource.type} already exists for host #{new_resource.host} already exists")
    if checks_differ?(current_resource, new_resource)
      Chef::Log.debug("#{new_resource}: parameters differ, attempting to update")
      response = update_check(new_resource.name, new_resource.type, new_resource.host, new_resource.check_params)
      if response.code == 200
        Chef::Log.info("#{new_resource}: check modified")
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.fatal("#{new_resource}: failed to modify check, unexpected response from api: " + response.parsed_response.inspect)
        raise unless new_resource.ignore_failure
      end
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
      response = pause_check(new_resource.name, new_resource.type)
      if response.code == 200
        Chef::Log.info("#{new_resource}: check paused")
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.fatal("#{new_resource}: failed to pause check, unexpected response from api: " + response.parsed_response.inspect)
        raise unless new_resource.ignore_failure
      end
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
      response = resume_check(new_resource.name, new_resource.type)
      if response.code == 200
        Chef::Log::info("#{new_resource}: check resumed")
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.fatal("#{new_resource}: failed to resume check, unexpected response from api: " + response.parsed_response.inspect)
        raise unless new_resource.ignore_failure
      end
    when "up","down","unconfirmed_down"
      Chef::Log.debug("#{new_resource}: status of check is \"#{status}\", no action necessary." )
    end
  end
end

action :delete do
  if check_exists?(new_resource.name, new_resource.type)
    response = delete_check(new_resource.name, new_resource.type)
    if response.code == 200
      Chef::Log.info("#{new_resource}: check deleted")
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.fatal("#{new_resource}: failed to delete check, unexpected response from api: " + response.parsed_response.inspect)
      raise unless new_resource.ignore_failure
    end
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
  Chef::Log.debug("#{new_resource}: loaded current resource: " + @current_resource.inspect)
  @current_resource
end

private

def sanitize_params(params)
  # we are sending form encoded data,
  # so arrays should become comma delimited strings
  params.map do |k,v|
    if v.respond_to?(:join)
      params[k] = v.join(',')
    end
  end
  params
end

def pingdom_api
  pingdom_api ||= Pingdom::Client.new(
    new_resource.username,
    new_resource.password,
    new_resource.api_key,
    new_resource.account_email
  )
end

def find_check(name, type)
  pingdom_api.checks.find { |c| c['name'] == name && c['type'] == type }
end

def add_check(name, host, type, params)
  merged_params = { 'name' => name, 'host' => host, 'type' => type }
  merged_params.merge!(params.keys_to_s)

  merged_params = sanitize_params(merged_params)

  Chef::Log.debug("#{new_resource}: merged params = " + merged_params.inspect)

  pingdom_api.post('/checks', merged_params)
end

def pause_check(name, type)
  params = { paused: true }
  check = find_check(name, type)
  pingdom_api.put("/checks/#{check['id']}", params)
end

def resume_check(name, type)
  params = { paused: false }
  check = find_check(name, type)
  pingdom_api.put("/checks/#{check['id']}", params)
end

def delete_check(name, type)
  check = find_check(name, type)
  pingdom_api.delete("/checks/#{check['id']}")
end

def update_check(name, type, host, params)

  clean_params = params.keys_to_s

  merged_params = { 'name' => name, 'host' => host }
  merged_params.merge!(clean_params)
  merged_params.delete('hostname') if merged_params.keys.include?('hostname')

  merged_params = sanitize_params(merged_params)

  Chef::Log.debug("#{new_resource}: merged params = " + merged_params.inspect)
  id = check_id(name, type)
  pingdom_api.put("/checks/#{id}", merged_params)
end

def check_exists?(name, type)
  check = find_check(name, type)
  check.nil? ? false : true
end

def check_status(name, type)
  check = find_check(name, type)
  check['status']
end

def check_details(name, type)
  check = find_check(name, type)
  response = pingdom_api.get("/checks/#{check['id']}")
  response_body = ::JSON.parse(response)
  params = response_body['check']
  # when we query the existing check we get back a response containing
  # nested parameters under the type key.
  # flatten out the response to make comparison easier.
  params['type']["#{params['type'].keys.first}"].each do |k, v|
    params.merge!(k => v)
  end
  params['type'] = params['type'].keys.first
  params = sanitize_params(params)
  params
end

def check_id(name, type)
  if check_exists?(name, type)
    check = find_check(name, type)
    check['id']
  end
end

def checks_differ?(current_check, new_check)
  modified = false

  params = new_check.check_params.keys_to_s
  params.merge!({ 'hostname' => new_check.host  })

  requestheader_keys = params.keys.grep(/^requestheader\d*$/)

  unless requestheader_keys.empty? || requestheader_keys.nil?
    params.merge!({ 'requestheaders' => {} })
    params.select { |k, v| k.match(/^requestheader\d*$/) }.each do |k, v|
      params['requestheaders'].merge!(
        v.split(':')[0] => v.split(':')[1..-1].join(':')
      )
      params.delete(k)
    end
  end

  params = sanitize_params(params)

  params.keys.each do |k|
    Chef::Log.debug("comparing values for #{k}")
    Chef::Log.debug("current: #{current_check.check_params[k].to_s}")
    Chef::Log.debug("new: #{params[k].to_s}")
    if current_check.check_params[k].to_s != params[k].to_s
      Chef::Log.debug("value of parameter #{k} differs")
      modified = true
      # we only need one parameter to differ, so return now
      return modified
    else
      modified = false
    end
  end
  modified
end
