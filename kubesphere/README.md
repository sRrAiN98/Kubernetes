# KubeSphere 3노드 클러스터 구축 가이드 (KubeKey)

KubeSphere의 설치 도구인 **KubeKey(`kk`)**를 사용하여 마스터 1대, 워커 2대의 3노드 환경에 Kubernetes와 KubeSphere 올인원 콘솔을 배포하고, 클라우드 VM 환경에서 자주 마주치는 **SSH Root 접근 차단 문제**를 해결한 실무 구축 가이드입니다.

---

## 1. 노드 공통 사전 환경 설정 (CentOS 기준)

모든 노드(master1, worker1, worker2)에 접속하여 사전 필수 패키지 설치 및 보안 설정을 수행합니다.

```bash
# 호스트명 및 타임존 설정
hostnamectl set-hostname master1 # (각각 worker1, worker2로 설정)
timedatectl set-timezone Asia/Seoul

# SELinux 해제 (permissive 모드)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Swap 메모리 비활성화 및 방화벽 끄기
sudo swapoff -a && sudo sed -i '/swap/s/^/#/' /etc/fstab
sudo systemctl disable --now firewalld

# 필수 의존성 패키지 설치
yum update -y
yum install -y socat ebtables ipset ipvsadm conntrack docker openssl openssl-devel epel-release conntrack-tools
```

---

## 2. 실무 트러블슈팅: SSH Root 접근 강제 해제

> [!CAUTION]
> **KubeKey 설치 시 핵심 주의사항**
> KubeKey(`kk`)는 노드 프로비저닝 시 원격 노드에 SSH/SFTP로 `root` 계정 접근을 시도합니다.  
> 클라우드(KT Cloud, AWS 등) 기본 CentOS 이미지는 `~/.ssh/authorized_keys`에 `root` 로그인을 강제로 차단하고 일반 유저(`centos`)로 로그인하라는 커맨드가 심어져 있어 KubeKey가 연결 직후 튕기며 실패합니다.

### 1) sshd 설정에서 Root 로그인 허용
```bash
sudo vi /etc/ssh/sshd_config

# 아래 옵션 확인 및 활성화
PermitRootLogin yes
PasswordAuthentication yes

sudo systemctl restart sshd
```

### 2) `~/.ssh/authorized_keys`의 Root 로그인 차단 커맨드 제거
```bash
sudo vi ~/.ssh/authorized_keys

# ❌ 제거해야 할 차단 커맨드 부분:
# command="echo 'Please login as the user \"centos\" rather than the user \"root\".';echo;sleep 10" ssh-rsa AAAAB3NzaC1yc2E...

# ⭕ 커맨드 앞부분을 지우고 순수한 공개키(ssh-rsa AAAAB...)만 남겨서 저장합니다.
```

---

## 3. KubeKey 다운로드 및 클러스터 설정 파일 작성

```bash
curl -sfL https://get-kk.kubesphere.io | VERSION=v2.3.0 sh -
chmod +x kk
./kk create config --with-kubernetes v1.23.7 --with-kubesphere v3.3.1
```

### `config-sample.yaml` 작성
각 노드의 내부 사설 IP와 SSH Private Key 경로를 지정합니다.

```yaml
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
    - {name: master1, address: 172.25.0.34, internalAddress: 172.25.0.34, privateKeyPath: "~/.ssh/id_rsa"}
    - {name: worker1, address: 172.25.0.158, internalAddress: 172.25.0.158, privateKeyPath: "~/.ssh/id_rsa"}
    - {name: worker2, address: 172.25.0.133, internalAddress: 172.25.0.133, privateKeyPath: "~/.ssh/id_rsa"}
  roleGroups:
    etcd:
      - master1
    control-plane:
      - master1
    worker:
      - worker1
      - worker2
```

---

## 4. 클러스터 설치 실행 및 검증

```bash
./kk create cluster -f config-sample.yaml
```

설치가 완료되면 `~/.kube/config`가 생성되며, `kubectl` 명령어로 클러스터 상태를 확인하고 KubeSphere 웹 콘솔(포트 30880)에 접속할 수 있습니다.

```bash
export KUBECONFIG=$HOME/.kube/config
kubectl get nodes
# master1   Ready   control-plane,master   v1.23.7
# worker1   Ready   worker                 v1.23.7
# worker2   Ready   worker                 v1.23.7
```
