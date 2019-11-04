# -*- mode: ruby -*-
# vi: set ft=ruby :

ram = 1024
cpus = 1

Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-8.9"
  config.vm.hostname = "newdeal"

  config.vm.network "private_network", ip: "192.168.29.04"
  config.ssh.forward_agent = true

  #config.vm.synced_folder "../fnev.eu", "/home/vagrant/fnev.eu"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |v|
    v.memory = ram
    v.cpus = cpus
  end

  config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/id_rsa.pub"
  config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"
  config.vm.provision "file", source: "~/.gitconfig", destination: "~/.gitconfig"
  config.vm.provision "shell", path: "./Vagrant_bootstrap.sh"
end

