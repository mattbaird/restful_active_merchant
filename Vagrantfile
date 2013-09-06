# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = "lucid64"
  config.vm.box_url = "http://files.vagrantup.com/lucid64.box"

  config.vm.forward_port 4567, 9090 # guest port 4567 to host 8080

  config.vm.provision :chef_solo do |chef|
  	chef.cookbooks_path =  'cookbooks'

  chef.add_recipe 'apt'
	chef.add_recipe 'rvm::vagrant'
	chef.add_recipe 'rvm::system'

	chef.json = {
		'rvm' => {
			'rubies'       => ['1.9.3-p448'],
			'default_ruby' => '1.9.3-p448',
			'global_gems'  => [
				{'name'    => 'bundler'},
				{'name'    => 'rake', 'version' => '10.1.0'}
			],
			'vagrant' => {
				'system_chef_solo' => '/opt/vagrant_ruby/bin/chef-solo'
			}
		}
	}
  end

  config.vm.provision :shell, :inline => 'cd /vagrant && bundle install'
end
