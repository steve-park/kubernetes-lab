# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define "storage" do |storage|
    storage.vm.hostname = "storage"
    storage.vm.box = "bento/ubuntu-20.04"
    # master.vm.box_check_update = false

    storage.vm.network "private_network", ip: "192.168.56.210"

    # config.vm.synced_folder "../data", "/vagrant_data"

    storage.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.name = "storage"
      vb.cpus = 2
      vb.memory = "1024"
    end

    storage.vm.provision "shell", path: "./scripts/storage.sh"

    storage.vm.provision "shell", privileged: false, inline: <<-SHELL
      echo "nfs storage server is ready!!!"
    SHELL
  end

  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.box = "bento/ubuntu-20.04"
    # master.vm.box_check_update = false

    master.vm.network "private_network", ip: "192.168.56.200"

    # config.vm.synced_folder "../data", "/vagrant_data"

    master.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.name = "master"
      vb.cpus = 2
      vb.memory = "2048"
    end

    master.vm.provision "shell", path: "./scripts/common.sh"
    master.vm.provision "shell", path: "./scripts/master.sh"

    master.vm.provision "shell", privileged: false, inline: <<-SHELL
      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config
      echo "source <(kubectl completion bash)" >> $HOME/.bashrc
      echo "source <(kubeadm completion bash)" >> $HOME/.bashrc

      echo "kubernetes master node is ready!!!"
    SHELL
  end

  (1..2).each do |i|
    config.vm.define "worker-#{i}" do |worker|
      worker.vm.hostname = "worker-#{i}"
      worker.vm.box = "bento/ubuntu-20.04"

      worker.vm.network "private_network", ip: "192.168.56.20#{i}"

      worker.vm.provider "virtualbox" do |vb|
        vb.gui = false
        vb.name = "worker-#{i}"
        vb.cpus = 2
        vb.memory = "2048"  
      end

      worker.vm.provision "shell", path: "./scripts/common.sh"
      worker.vm.provision "shell", path: "./scripts/worker.sh"

      worker.vm.provision "shell", privileged: false, inline: <<-SHELL
        mkdir -p $HOME/.kube
        sudo cp -i /vagrant/config/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        echo "source <(kubectl completion bash)" >> $HOME/.bashrc
        echo "source <(kubeadm completion bash)" >> $HOME/.bashrc
        
        echo "kubernetes worker node is ready!!!"
      SHELL
    end
  end

end
