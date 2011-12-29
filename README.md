Description
===========

This cookbook provides libraries, resources and providers to configure and manage service checks and contacts on Pingdom's external monitoring system.

Requirements
============

Requires Chef 0.7.10 or higher for Lightweight Resource and Provider support. Chef 0.10+ is recommended as this cookbook has not been tested with earlier versions.

A valid username, password and API key for your Pingdom account is required. These credentials should be provided as values for the following node attributes:

* `node[:pingdom][:api_user]`
* `node[:pingdom][:api_pass]`
* `node[:pingdom][:api_key]`

Recipes
=======

This cookbook provides an empty default recipe which installs the required `json` gem.

Libraries
=========

This cookbook provides the `Opscode::Pingdom::Check` library module which is required by all the check providers.

Resources and Providers
=======================

This cookbook provides a single resource (`pingdom_check`) and corresponding provider for managing Pingdom service checks. 

`pingdom_check` resources support the actions `add` and `delete`, `add` being the default. Each `pingdom_check` resource requires a `host` attribute parameter which indicates the hostname (or IP address) which the service check will target, and may also specifiy attributes for the optional `type` and `check_params` parameters. 

The `type` parameter will accept one of the following service check types. If no value is specified, the check type will default to `http`.

* http
* tcp
* udp
* ping
* dns
* smtp
* pop3
* imap

The optional `params` attribute is expected to be a hash containing key/value pairs which match the type-specific parameters defined by the [Pingdom API](http://www.pingdom.com/services/api-documentation-rest/#ResourceChecks).

Usage
=====

In order to utilize this cookbook, put the following at the top of the recipe where Pingdom resources are used:

    include_recipe 'pingdom'

The following resource would configure a HTTP service check for the host `foo.example.com`:
    
    pingdom_check 'foo http check' do
      host 'foo.example.com'
    end

The resulting HTTP service check would be created using all the Pingdom defaults for HTTP service checks. 

The following resource would configure an HTTP service check for the host `bar.example.com` utilizing some of the parameters specific to the HTTP service check type:

    pingdom_check 'bar.example.com http status check' do
      host 'bar.example.com'
      check_params :url => "/status",
                   :shouldcontain => "Everything is OK!",
                   :sendnotificationwhendown => 2,
                   :sendtoemail => "true",
                   :sendtoiphone => "true"
    end

License and Author
==================

Author:: Cameron Johnston (<cameron@needle.com>)

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

Changes
=======

## v0.0.2

* Rewire LWRP to use a single resource and provider instead of a resource and provider per service check type.
* Add support for TCP, UDP, DNS, SMTP, POP3, IMAP and Ping service check types.

## v0.0.1

Initial release.
