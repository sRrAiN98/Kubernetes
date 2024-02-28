```bash
sudo su

setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
swapoff -a
systemctl disable firewalld

cd /etc/yum.repos.d

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

cat <<EOF > /etc/yum.repos.d/centos.repo
[AppStream]
name=CentOS-$releasever - AppStream
baseurl=https://vault.centos.org/8.4.2105/AppStream/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

[BaseOS]
name=CentOS-$releasever - Base
baseurl=https://vault.centos.org/8.4.2105/BaseOS/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

[extras]
name=CentOS-$releasever - Extras
baseurl=https://vault.centos.org/8.4.2105/extras/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
EOF

cd /etc/pki/rpm-gpg/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official

yum clean all
yum update -y

dnf install -y kubeadm-1.23.0 kubelet-1.23.0 kubectl-1.23.0
systemctl enable kubelet
systemctl start kubelet

dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
dnf install -y docker-ce

cat <<EOF > /etc/sysctl.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

systemctl enable docker
systemctl start docker

#/etc/containerd/config.toml 파일에서 "disabled_plugins" 항목에서 "CRI" 제거
systemctl restart containerd

#------------#
kubeadm init

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

# deepops

```bash
#파이썬이랑 앤써블 설치, 안되면 하단블럭 코드 실행
sudo dnf install python3
pip3 install ansible --user
subscription-manager repos --enable ansible-2.8-for-rhel-8-x86_64-rpms
dnf -y install ansible

#sshpass에러 설치
wget https://cbs.centos.org/kojifiles/packages/sshpass/1.06/8.el8/x86_64/sshpass-1.06-8.el8.x86_64.rpm
 dnf install -y ./sshpass-1.06-8.el8.x86_64.rpm

#linux 한국어 설정
yum install glibc-langpack-ko -y --allowerasing
sudo localectl set-locale LANG=ko_KR.UTF-8
```

ansible python3.8

```bash
wget http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/ansible-core-2.12.2-3.el8.x86_64.rpm
wget http://mirror.centos.org/centos/8-stream/AppStream/aarch64/os/Packages/python38-resolvelib-0.5.4-5.el8.noarch.rpm
wget http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/sshpass-1.09-4.el8.x86_64.rpm
rpm -ivh python38-resolvelib-0.5.4-5.el8.noarch.rpm
rpm -ivh sshpass-1.09-4.el8.x86_64.rpm
rpm -ivh ansible-core-2.12.2-3.el8.x86_64.rpm
```

# deepops install

http://www.openkb.info/2021/04/how-to-install-kubernetes-cluster-with.html

```bash
git clone https://github.com/NVIDIA/deepops.git
cd deepops
vim config/inventory
#아래 페이지 형식 참조
```

<details>
<summary>vi config/inventory</summary>
<div markdown="1">

```bash
#
# Server Inventory File
#
# Uncomment and change the IP addresses in this file to match your environment
# Define per-group or per-host configuration in group_vars/*.yml

######
# ALL NODES
# NOTE: Use existing hostnames here, DeepOps will configure server hostnames to match these values
###### 호스트네임과 사설아이피 기입
[all]
kisti-jjh   ansible_host=172.25.0.119
#mgmt01     ansible_host=10.0.0.1
#mgmt02     ansible_host=10.0.0.2
#mgmt03     ansible_host=10.0.0.3
#login01    ansible_host=10.0.1.1
#gpu01      ansible_host=10.0.2.1
#gpu02      ansible_host=10.0.2.2

######
# KUBERNETES
###### 
# 단일 노드에는 다 똑같이 local 호스트네임 기입
[kube-master]
kisti-jjh
#mgmt02
#mgmt03

# Odd number of nodes required 
# 단일 노드에는 다 똑같이 local 호스트네임 기입
[etcd]
kisti-jjh
#mgmt02
#mgmt03

# Also add mgmt/master nodes here if they will run non-control plane jobs
# 단일 노드에는 다 똑같이 local 호스트네임 기입
[kube-node]
kisti-jjh
#gpu01
#gpu02

[k8s-cluster:children]
kube-master
kube-node

######
# SLURM
######
[slurm-master]
#login01

[slurm-nfs]
#login01

[slurm-node]
#gpu01
#gpu02

# The following groups are used to break out individual cluster services onto
# different nodes. By default, we put all these functions on the cluster head
# node. To break these out into different nodes, replace the
# [group:children] section with [group], and list individual nodes.
[slurm-cache:children]
slurm-master

[slurm-nfs-client:children]
slurm-node

[slurm-metric:children]
slurm-master

[slurm-login:children]
slurm-master

# Single group for the whole cluster
[slurm-cluster:children]
slurm-master
slurm-node
slurm-cache
slurm-nfs
slurm-metric
slurm-login

######
# SSH connection configuration
######
[all:vars]
#앤서블은 ssh로 접근해서 원격 명령어 배포여서 ssh접근 가능한 환경을 제공해야함
# ssh-keygen 명령어로 pri,pub키 생성(한 쌍 필요)
# SSH User
ansible_user=cloud-user
ansible_ssh_private_key_file='~/.ssh/id_rsa'
# SSH bastion/jumpbox
#ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ubuntu@10.0.0.1"'
```

</div>
</details>
```bash
#접속 테스트 명령어
ansible all -m raw -a "hostname"

#deepops ansible 배포
./scripts/setup.sh

#쿠버네티스 배포
ansible-playbook -l k8s-cluster playbooks/k8s-cluster.yml

#gpu pod 생성 가능 테스트
kubectl run gpu-test --rm -t -i --restart=Never --image=nvcr.io/nvidia/cuda:10.1-base-ubuntu18.04 --limits=nvidia.com/gpu=1 nvidia-smi
```