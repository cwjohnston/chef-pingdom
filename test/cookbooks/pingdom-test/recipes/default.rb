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

%w{ username password api_key contactids }.each do |a|
  unless node['pingdom_test'][a]
    Chef::Application.fatal!("Could not test pingdom, node['pingdom_test']['#{a}'] is not set.")
  end
end

include_recipe 'pingdom::default'

pingdom_check 'pingdom_lwrp_test' do
  host 'www.google.com'
  type 'http'
  username node['pingdom_test']['username']
  password node['pingdom_test']['password']
  api_key node['pingdom_test']['api_key']
  check_params(
    :shouldnotcontain => 'this should never happen',
    :resolution => 5,
    :contactids => node['pingdom_test']['contactids'],
    :sendtoemail => true,
    :requestheader1 => "User-Agent:Pingdom.com_bot_version_1.4_(http://www.pingdom.com)"
  )
  action :add
end

pingdom_check 'pingdom_lwrp_test' do
  host 'www.google.com'
  type 'http'
  action :delete
end
