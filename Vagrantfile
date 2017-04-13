# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative './bootstrap'

Vagrant.configure("2") do |config|
config.vm.box = "precise64"
   config.vm.provider :virtualbox do |provider, override|
        override.vm.box = "ubuntu/trusty64"
        override.vm.hostname = "graphite"
        override.vm.network :private_network, ip: "192.168.82.170"
        override.vm.provision "shell", :path => File.join(File.dirname(__FILE__),"scripts/graphite.sh")
        provider.customize ["modifyvm", :id, "--cpus", "2"]
        provider.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
        provider.customize ["modifyvm", :id, "--memory", "1024"]
      end
end



