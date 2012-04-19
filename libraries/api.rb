require 'net/http'
require 'net/https'

ApiHost = 'api.pingdom.com'
ApiPort = 443
ApiVersion = '2.0'
RootCA = '/etc/ssl/certs'

def api

  @@api ||= Net::HTTP.new(API_HOST, API_PORT)

  api.use_ssl = true
  if (File.directory?(RootCA) && api.use_ssl?)
    http.ca_path = RootCA
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.verify_depth = 5
  else
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
  end

  request = Net::HTTP::Get.new("/api/#{API_VER}/checks", { 'App-Key' => api_key })
  request.basic_auth(username, password)
  Chef::Log.debug("Pingdom: API connection configured as #{api.inspect}")
  Chef::Log.debug("Pingdom: API request configured as #{request.to_hash.inspect}")
  Chef::Log.debug("Pingdom: Sending API request...")

  api.start

  @@api
end
