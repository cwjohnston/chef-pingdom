# encoding: utf-8
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

module Pingdom
  class Client

    def initialize(username, password, key)
      require 'rest-client'
      @key ||= key
      @api ||= RestClient::Resource.new(
        'https://api.pingdom.com/api/2.0',
        username,
        password
      )
    end

    def get(uri, options = {})
      options.merge!({ app_key: @key })
      @api[uri].get options
    end

    def put(uri, body, options = {})
      options.merge!({ app_key: @key })
      @api[uri].put body, options
    end

    def post(uri, body, options = {})
      options.merge!({ app_key: @key })
      @api[uri].post body, options
    end

    def delete(uri, options = {})
      options.merge!({ app_key: @key })
      @api[uri].delete options
    end

    def checks(options = {})
      require 'json'
      response = get('/checks')
      data = ::JSON.parse(response)
      data['checks']
    end

  end
end
