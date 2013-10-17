begin
  require 'httparty'
rescue LoadError
  Chef::Log.warn('httparty gem not available')
end

class PingdomClient

  class << self
    def load_httparty
      require 'httparty'
      self.send(:include, HTTParty)
      self.class_eval do
        self.base_uri 'https://api.pingdom.com/api/2.0'
      end
    end
  end

  def initialize(u,p,k)
    @auth = {:username => u, :password => p}
    @headers = {'App-Key' => k}
  end

  def get(uri, options={})
    options.merge!({:basic_auth => @auth})
    options.merge!({:headers => @headers})
    response = self.class.get(uri, options)
  end

  def put(uri, options={})
    options.merge!({:basic_auth => @auth})
    options.merge!({:headers => @headers})
    response = self.class.put(uri, options)
  end

  def post(uri, options={})
    options.merge!({:basic_auth => @auth})
    options.merge!({:headers => @headers})
    response = self.class.post(uri, options)
  end

  def delete(uri, options={})
    options.merge!({:basic_auth => @auth})
    options.merge!({:headers => @headers})
    response = self.class.delete(uri, options)
  end

  def checks(options={})
    options.merge!({:basic_auth => @auth})
    options.merge!({:headers => @headers})
    response = self.class.get('/checks', options).parsed_response
    checks = response['checks']
  end

end
