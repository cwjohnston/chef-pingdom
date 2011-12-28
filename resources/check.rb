def initialize(*args)
    super
      @action = :add
end

actions :add, :delete

attribute :name, :kind_of => String, :name_attribute => true
attribute :type, :kind_of => String, :required => true, :default => 'http', :regex => /http|tcp|udp|ping|dns|smtp|pop3|imap/
attribute :host, :kind_of => String, :required => true
attribute :check_params, :kind_of => [ NilClass, Hash ]
attribute :notification_params, :kind_of => [ NilClass, Hash ]
