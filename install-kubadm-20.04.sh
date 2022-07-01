#!/bin/bash

read -p "Enter your bridge IP: " bridge_ip
read -p "input master or worker node  (m/w)" node


apt-get update
apt-get install -y apt-transport-https vim net-tools wget
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update

apt-get install -y docker.io

swapoff -a

systemctl enable docker
systemctl stop docker
echo '{"exec-opts":["native.cgroupdriver=systemd"]}' > /etc/docker/daemon.json
systemctl start docker

K_VER='1.21.3-00'
# Install kubernetes components!
apt-get install -y \
        kubelet=${K_VER} \
        kubeadm=${K_VER} \
        kubectl=${K_VER}


if $node == "m"; then

	kubeadm init --pod-network-cidr=10.244.0.0/16 --service-cidr=10.245.0.0/16 --apiserver-advertise-address=$bridge_ip

	mkdir -p $HOME/.kube
	cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	chown $(id -u):$(id -g) $HOME/.kube/config

	kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


	generation_token=$(kubeadm token generate)
	echo "\n\nEnter the join token on the worker node side: \n"

	kubeadm token create $generation_token --print-join-command

	echo "\n--------------------------------------------"

elif $node == "w"; then
	echo "\n\n"
	read -p "Enter the join token: "join_token

	$join_token

fi



exit 0

