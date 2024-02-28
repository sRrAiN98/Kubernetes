# kubeSphere node3 install (1)

```bash
curl -sfL https://get-kk.kubesphere.io | VERSION=v2.3.0 sh -
chmod +x kk
yum install -y socat ebtables ebtables ipset ipvsadm conntrack docker
./kk create config --with-kubernetes v1.23.7 --with-kubesphere v3.3.1
```

#node들 설정할 값들

```bash
hostnamectl set-hostname master1 #(worker1, worker2)
timedatectl set-timezone Asia/Seoul

# permissive 모드로 SELinux 설정(효과적으로 비활성화)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

#swap 끄기 && 방화벽 끄기
sudo swapoff -a && sudo sed -i '/swap/s/^/#/' /etc/fstab
sudo systemctl disable firewalld

yum update
yum install -y openssl openssl-devel socat epel-release conntrack-tools
```

vim config-sample.yaml

```bash
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
  - {name: master1, address: 172.25.0.34, internalAddress: 172.25.0.34, privateKeyPath: "~/.ssh/key.pem"}
  - {name: worker1, address: 172.25.0.158, internalAddress: 172.25.0.158, privateKeyPath: "~/.ssh/key.pem"}
  - {name: worker2, address: 172.25.0.133, internalAddress: 172.25.0.133, privateKeyPath: "~/.ssh/key.pem"}
  roleGroups:
    etcd:
    - master1
    control-plane:
    - master1
    worker:
    - worker1
    - worker2
```

#key로 접근시 ssh, sftp를 root로 접근하는 듯 함으로, 해당 노드들의 root접근이 가능한지 확인해야함.

vim /etc/ssh/sshd_config

```bash
#루트 로그인 허용 유무
**PermitRootLogin yes

#패스워드 로그인 허용 유무
PasswordAuthentication yes #상관없음 키로 접근할 예정**
```

`systemctl restart sshd`

#클라우드에서 인스턴스 발급 시 사용한 키에 키쌍의 pub키가 자동으로 등록됨

vim ~/.ssh/authorized_keys

```bash
no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="echo 'Please login as the user \"centos\" rather than the user \"root\".';echo;sleep 10" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2DL3BwT/beGaBDJAmiKE//Bhxk0IP6pdppg4NBlhJMlwbkeBXL4o1h44E6Y5ww/Ww4TQQU8MtiucYVP//4bIdv7a3qyTvgpIj/sYqNxCJEr9TWbcrei8VMnCiOSMa/gS7SABMXPzxjcFrHiAc61z2Pxpv2whcHghUeuaK7dlI35UdEJTYVUKXkDeXdFTwT2dphDkt21YbnL9GELlMJ51nfxkr7jMZw6HPjajEqSlmJ82FrDkNNo/3ZyPAE/73rVAx9ydJ8bLx32hPw7tgQMKdkX3PhDSFyaMf1uk1n9KjArveq9Ej0HLiN7fh+/x/2tspxXnFYfBCuobbmxJ6/Jkn Generated-by-Nova
```

#command 라인을 마지막으로 ssh connect가 종료되기에 root로 접근할 수 없음!

#해당하는 라인을 지워서 저장

vim ~/.ssh/authorized_keys

```bash
~~no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="echo 'Please login as the user \"centos\" rather than the user \"root\".';echo;sleep 10"~~ ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2DL3BwT/beGaBDJAmiKE//Bhxk0IP6pdppg4NBlhJMlwbkeBXL4o1h44E6Y5ww/Ww4TQQU8MtiucYVP//4bIdv7a3qyTvgpIj/sYqNxCJEr9TWbcrei8VMnCiOSMa/gS7SABMXPzxjcFrHiAc61z2Pxpv2whcHghUeuaK7dlI35UdEJTYVUKXkDeXdFTwT2dphDkt21YbnL9GELlMJ51nfxkr7jMZw6HPjajEqSlmJ82FrDkNNo/3ZyPAE/73rVAx9ydJ8bLx32hPw7tgQMKdkX3PhDSFyaMf1uk1n9KjArveq9Ej0HLiN7fh+/x/2tspxXnFYfBCuobbmxJ6/Jkn Generated-by-Nova
```

`./kk create cluster -f config-sample.yaml`

#쿠버네티스와, 쿠버스피어가 설치됨 환경변수 설정이 같이 되지 않기에 커맨드 미존재

#쿠버네티스 conf값을 환경변수에 넣어주면 커맨드로 설치 확인 가능.