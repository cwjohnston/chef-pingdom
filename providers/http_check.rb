include Opscode::Pingdom::Check

type = 'http'

action :add do
  if check_exists?(new_resource.name, type)
    Chef::Log.debug("Pingdom: #{type} check #{new_resource.name} already exists, so I will not attempt to create it again.")
  else
    add_check(new_resource.name, new_resource.host, type, new_resource.params)
  end
end

action :delete do
  unless check_exists?(new_resource.name, type)
    Chef::Log.debug("Pingdom: #{type} check #{new_resource.name} does not exist, so I will not attempt to delete it.")
  else
    check_id = get_check_id(new_resource.name, type)
    Chef::Log.debug("Pingdom: resolved check #{new_resource.name} of type #{type} to check id #{check_id}")
    unless delete_check(check_id)
    end
  end
end
