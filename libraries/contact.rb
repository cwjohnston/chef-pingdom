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
    module Contact

      def add_contact(contact)
        params = { :name => contact.name }
        %w{ email 
            cellphone
            countrycode
            countryiso
            defaultsmsprovider
            directtwitter
            twitteruser}.each do |param|
          unless contact.#{param}
            params.merge({#{param} => contact.#{param}})
          end
        end
        pingdom.post("contacts",params)
      end

      def delete_contact(contact)
        client = pingdom.contacts.find {|c| c.name == name }
        pingdom.delete("contact/#{contact.id}")
      end 

      def update_contact(contact)
        params = { :name => contact.name }
        %w{ email 
            cellphone
            countrycode
            countryiso
            defaultsmsprovider
            directtwitter
            twitteruser}.each do |param|
          unless contact.#{param}
            params.merge({#{param} => contact.#{param}})
          end
        end
        pingdom.put("contact/#{contact.id}",params)
      end

      def contact_exists?(name)
        contact = pingdom.contacts.find {|c| c.name == name }
        contact ? true : false
      end

    end
  end
end
