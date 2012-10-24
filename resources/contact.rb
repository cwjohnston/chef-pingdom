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

def initialize(*args)
    super
      @action = [ :add, :update ]
end

actions :add, :update, :delete

attribute :name, :kind_of => String, :name_attribute => true
attribute :email, :kind_of => String
attribute :cellphone, :kind_of => String
attribute :countrycode, :kind_of => String
attribute :countryiso, :kind_of => String
attribute :defaultsmsprovider, :kind_of => String, :regex => /^clickatell$|^bulksms$|^esendex$|^cellsynt$/
attribute :directwitter, :kind_of => [TrueClass,FalseClass]
attribute :twitteruser, :kind_of => String
attribute :api_key, :kind_of => String, :required => true
attribute :username, :kind_of => String, :required => true
attribute :password, :kind_of => String, :required => true
