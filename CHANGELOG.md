pingdom Cookbook CHANGELOG
==========================

## v0.2.9
* Made version constraint on HTTParty configurable via node attribute - thanks Jose Luis Salas

## v0.2.8
* Added version constraint on installation of HTTParty gem to avoid conflicts with Chef's JSON dependencies

## v0.2.7
* Added `ignore_failure` parameter to allow Chef run to continue when communicating with Pingdom fails.

## v0.2.2 - v0.2.6
* Changes to data structure processing

## v0.2.1
* Additional data sanitization and debug logging

## v0.2.0
* Refactor around HTTParty

## v0.1.0
* Refactor around pingdom-client gem
* Fix scoping of OpenSSL::SSL::VERIFY_NONE - thanks Patrick Debois
* Default check type to http - thanks Patrick Debois

## v0.0.3
* Added `api_key`, `username` and `password` as resource attributes instead of relying on node attributes.

## v0.0.2
* Rewire LWRP to use a single resource and provider instead of a resource and provider per service check type.
* Add support for TCP, UDP, DNS, SMTP, POP3, IMAP and Ping service check types.

## v0.0.1
* Initial release.
