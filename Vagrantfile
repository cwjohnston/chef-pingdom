Vagrant::Config.run do |config|

  config.vm.define :precise64 do |dist_config|
    dist_config.vm.box       = 'opscode-ubuntu-12.04'
    dist_config.vm.box_url   = 'https://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-ubuntu-12.04.box'

    dist_config.vm.customize do |vm|
      vm.name        = 'pingdom'
      vm.memory_size = 1024
    end

    dist_config.vm.network :bridged, '33.33.33.10'

    dist_config.vm.provision :chef_solo do |chef|

      chef.cookbooks_path    = [ '/tmp/pingdom-cookbooks' ]
      chef.provisioning_path = '/etc/vagrant-chef'
      chef.log_level         = :debug

      chef.run_list = %w| pingdom::test |

      chef.json = {}
    end
  end

end
