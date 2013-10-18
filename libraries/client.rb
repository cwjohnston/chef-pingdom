class PingdomClient

  def initialize(username, password, key)
    require 'rest-client'
    @key ||= key
    @api ||= RestClient::Resource.new('https://api.pingdom.com/api/2.0', username, password)
  end

  def get(uri, options={})
    options.merge!({:app_key => @key})
    response = @api[uri].get options
    return response
  end

  def put(uri, body, options={})
    options.merge!({:app_key => @key})
    response = @api[uri].put body, options
    return response
  end

  def post(uri, body, options={})
    options.merge!({:app_key => @key})
    Chef::Log.info("options: #{options.inspect}")
    response = @api[uri].post body, options
    return response
  end

  def delete(uri, options={})
    options.merge!({:app_key => @key})
    response = @api[uri].delete options
    return response
  end

  def checks(options={})
    require 'json'
    response = self.get('/checks')
    data = ::JSON.parse(response)
    return data['checks']
  end

end
