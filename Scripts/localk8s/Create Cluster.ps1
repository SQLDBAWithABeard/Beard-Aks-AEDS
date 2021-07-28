# once Ubuntu installed

#update and reboot
sudo apt update
sudo apt -y upgrade && sudo systemctl reboot

# install ssh so we can work remotely
sudo apt update
sudo apt install openssh-server -y
ip addr show

# Disable swap memory on each ubuntu node
sudo swapoff -a
sudo sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

# install nfs-common

#on both install nfs-common

sudo apt install nfs-common -y

# Adding Kubernetes signing key as follows:

apt install curl

sudo -i
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
sudo mv ~/kubernetes.list /etc/apt/sources.list.d
sudo apt update

## install required packages

sudo apt update
sudo apt -y install vim git curl wget kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# check version

kubectl version --client && kubeadm version

# configure sysctl

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# install containerd
# Configure persistent loading of modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

# Load at runtime
sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Install required packages
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates


# Add Docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install containerd
sudo apt update
sudo apt install -y containerd.io

# Configure containerd and start service
sudo mkdir -p /etc/containerd
sudo su -
containerd config default > /etc/containerd/config.toml

# restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
#   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#    SystemdCgroup = true

nano /etc/containerd/config.toml

# ensure br_netfilter is loaded
lsmod | grep br_netfilter


# enable kubelet
sudo systemctl enable kubelet

# cluster cluster cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

#configure kubectl
# from sudo export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# to connect from local machine need to cat $HOME/.kube/config
# and copy into local .kube/config file
# the name that is given to the cluster needs to be added to the hosts file with IP for ARC enablement

 kubectl cluster-info

 kubectl get nodes

# untaint master node to allow deployment

kubectl taint node singlebeard node-role.kubernetes.io/master:NoSchedule-

# Next, deploy a pod network to cluster:

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Verifying that all Control-plane components have successfully installed:

kubectl get pod --all-namespaces

# add local storage class

kubectl apply -f G:\OneDrive\Documents\GitHub\BeardLInux\bens-local-storage.yaml
kubectl patch storageclass bens-local-storage -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'

# On cluster node run


## need to this on worker

PV_COUNT="80"
for i in $(seq 1 $PV_COUNT); do
  vol="vol$i"
  sudo mkdir -p /mnt/seconddrive/azurearc/local-storage/$vol
  sudo mkdir -p /azurearc/local-storage/$vol
  sudo mount --bind /mnt/seconddrive/azurearc/local-storage/$vol /azurearc/local-storage/$vol
done
