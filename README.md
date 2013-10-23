Description
===========

This cookbook provides libraries, resources and providers to configure and manage service checks and contacts on Pingdom's external monitoring system.

Requirements
============

Chef 0.10+ is recommended as this cookbook has not been tested with earlier versions.

A valid username, password and API key for your Pingdom account is required.

Recipes
=======

This cookbook provides a default recipe which installs the required `httparty` gem (verison ~> 0.11.0).

Resources and Providers
=======================

This cookbook provides a single resource (`pingdom_check`) and corresponding provider for managing Pingdom service checks.

`pingdom_check` resources support the actions `add` and `delete`, `add` being the default. Each `pingdom_check` resource requires the following resource attributes:

* `host` - indicates the hostname (or IP address) which the service check will target
* `api_key` - a valid API key for your Pingdom account
* `username` - your Pingdom username
* `password` - your Pingdom password

`pingdom_check` resources may also specifiy values for the optional `type` and `check_params` attributes.

The `type` attribute will accept one of the following service check types. If no value is specified, the check type will default to `http`.

* http
* tcp
* udp
* ping
* dns
* smtp
* pop3
* imap

The optional `check_params` attribute is expected to be a hash containing key/value pairs which match the type-specific parameters defined by the [Pingdom API](http://www.pingdom.com/services/api-documentation-rest/#ResourceChecks). If no attributes are provided for `check_params`, the default values for type-specific defaults will be used.

Usage
=====

In order to utilize this cookbook, put the following at the top of the recipe where Pingdom resources are used:

    include_recipe 'pingdom'

The following resource would configure a HTTP service check for the host `foo.example.com`:

    pingdom_check 'foo http check' do
      host 'foo.example.com'
      api_key node[:pingdom][:api_key]
      username node[:pingdom][:username]
      password node[:pingdom][:password]
    end

The resulting HTTP service check would be created using all the Pingdom defaults for HTTP service checks.

The following resource would configure an HTTP service check for the host `bar.example.com` utilizing some of the parameters specific to the HTTP service check type:

    pingdom_check 'bar.example.com http status check' do
      host 'bar.example.com'
      api_key node[:pingdom][:api_key]
      username node[:pingdom][:username]
      password node[:pingdom][:password]
      check_params :url => "/status",
                   :shouldcontain => "Everything is OK!",
                   :sendnotificationwhendown => 2,
                   :sendtoemail => "true",
                   :sendtoiphone => "true"
    end

Caveats
=======

* Changes in `check_params` do not modify the configuration of existing service checks.
* One must look up contact IDs manually if setting `contactids` in `check_params`

Future
======

* Add support for managing contacts
* Add `enable` and `disable` actions for service checks
* Refactor to account for changes in `check_params` values
* Convert `TrueClass` attribute values to `"true"` strings
* Validate class types for `check_params` attributes

License and Author
==================

Author:: Cameron Johnston (<cameron@rootdown.net>)

Copyright 2011, Needle, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

