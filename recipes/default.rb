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

gem_file_path = ::File.join(Chef::Config[:file_cache_path],'pingdom-client-0.0.6.alpha.gem')
gem_url = "http://needle-repo.s3.amazonaws.com/gems/pingdom-client-0.0.6.alpha.gem"

rf = remote_file gem_file_path do
  owner "root"
  group "root"
  mode "0644"
  source gem_url
  action :nothing
end

g = chef_gem 'pingdom-client' do
  source gem_file_path
  action :nothing
end

rf.run_action(:create_if_missing)
g.run_action(:install)
