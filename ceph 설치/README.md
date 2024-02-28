# ceph

- 목차

Ceph 설치 조건

1. 최소 node 3개 이상(볼륨 3개 이상)
2. 6core, memory 16G 이상 (kt cloud 기준)

# rook 빠른 시작 정리 - yaml 버전

```bash
git clone --single-branch --branch v1.10.3 https://github.com/rook/rook.git
cd rook/deploy/examples
kubectl create -f crds.yaml -f common.yaml -f operator.yaml
kubectl create -f cluster.yaml

#필요한 확장 yaml 설치 후에 cluster생성인데
#지금 pod가 확장이 안되고 있으면 cluster.yaml 지우고 재생성

#대쉬보드 nodeport 오픈
kubectl apply -f dashboard-external-https.yaml

# 패스워드 확인
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
```

```bash
#ceph 명령어 치는 tools pod
kubectl create -f toolbox.yaml
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
```

```bash
# 스토리지 클래스란?

#PVC를 요청하면 스토리지 클래스 리소스에 의해 PV가 자동으로 프로비저닝되어 사용할 수 있도록 동적 프로비저닝 기능

#rook-ceph-block: Ceph RBD 블록
#csi-cephfs: CephFS 파일시스템
```

```bash
# FS,rgw 설치
kubectl apply -n rook-ceph -f filesystem.yaml
kubectl apply -n rook-ceph -f object.yaml

#storageclass생성 
kubectl create -f csi/rbd/storageclass.yaml
kubectl create -f csi/cephfs/storageclass.yaml
```

```bash
#위에서 생성한 csi/cephfs/storageclass.yaml의 이름과
#아래에서 생성할 pvc의 storageClassName 을 매칭시키기

##--rook/deploy/examples/csi/rbd-- 폴더에 예제 yaml 존재
```

- dynamic-pvc.yml
    
    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: dynamic-pvc
    spec:
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 10Gi
      storageClassName: csi-cephfs
    ```
    

- /rook/deploy/examples/csi/cephfs/snapshotclass.yaml
    
    ```yaml
    ---
    # 1.17 <= K8s <= v1.19
    # apiVersion: snapshot.storage.k8s.io/v1beta1
    # K8s >= v1.20
    apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshotClass
    metadata:
      name: csi-cephfsplugin-snapclass
    driver: rook-ceph.cephfs.csi.ceph.com # driver:namespace:operator
    parameters:
      # Specify a string that identifies your cluster. Ceph CSI supports any
      # unique string. When Ceph CSI is deployed by Rook use the Rook namespace,
      # for example "rook-ceph".
      clusterID: rook-ceph # namespace:cluster
      csi.storage.k8s.io/snapshotter-secret-name: rook-csi-cephfs-provisioner
      csi.storage.k8s.io/snapshotter-secret-namespace: rook-ceph # namespace:cluster
    deletionPolicy: Delete
    ```
    

- /rook/deploy/examples/csi/cephfs/snapshot.yaml
    
    ```yaml
    ---
    # 1.17 <= K8s <= v1.19
    # apiVersion: snapshot.storage.k8s.io/v1beta1
    # K8s >= v1.20
    apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshot
    metadata:
      name: cephfs-pvc-snapshot # 그냥 snapshot 정의할 이름
    spec:
      volumeSnapshotClassName: csi-cephfsplugin-snapclass #volumesnapshotclasses 의 이름이랑 매칭
      source:
        persistentVolumeClaimName: dynamic-pvc ##pvc 의 이름이랑 매칭ㅜ
    ```
    

#관계도

| storageclass |           ↔ | pvc |            ➡ | pod |
| --- | --- | --- | --- | --- |
|          ↕ |  |         ↕ |  |  |
| snapshotclass |           ↔ | snapshot |  |  |

```bash
#pod는 pvc를 공용 스토리지로 갖고
#storageclass는 pvc를 갖고 pv를 동적 생성
#snapshotclass가 storageclass에 생성된 cephfs를 참조
#snapshot는 snapshotclass를 참조해서 사용중인 pvc를 스냅샷 찍음
#snapshot이 복원데이터의 저장소로 pvc 생성
#복원된 pvc와 pod를 매칭하여 복원된 pod 생성
```

---

# helm 버전

#node3개 볼륨 각각 1개씩(7분 소요)

```bash
helm repo add rook https://charts.rook.io/release
helm install rook-ceph rook/rook-ceph --version 1.10.4 -n rook-ceph --create-namespace
helm install rook-ceph-cluster rook/rook-ceph-cluster --version 1.10.4 -n rook-ceph
```

custom.yaml #node 여러개의 각각의 볼륨을 가지고 있을때 명시

```yaml
cephClusterSpec:
  storage: 
    nodes:
      - name: "kisti-jjh1" # node의 hostname      
        devices: 
        - name: "vdb" #lsblk 의 추가 볼륨명
      - name: "kisti-jjh2"
        devices: 
        - name: "vdb"
      - name: "kisti-jjh3"      
        devices: 
        - name: "vdb"
```

```bash
#ClusterIP -> NodePort로 수정
kubectl edit svc -n rook-ceph rook-ceph-mgr-dashboard

kubectl get secrets -n rook-ceph rook-ceph-dashboard-password -o jsonpath"={.data.password}" | base64 -d && echo
```

---

# ceph local install

https://docs.ceph.com/en/quincy/rbd/rbd-kubernetes/#configure-ceph-csi-plugins

https://access.redhat.com/documentation/ko-kr/openshift_container_platform/3.11/html/configuring_clusters/ceph-rbd-dynamic-example

```bash
#cephadm download
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
chmod +x cephadm

#ubuntu
apt update 
apt install -y python3 
sudo update-ca-certificates --fresh
export SSL_CERT_DIR=/etc/ssl/certs

./cephadm add-repo --release quincy
./cephadm install

#centos7
./cephadm add-repo --release octopus
rpm --import 'https://download.ceph.com/keys/release.asc'

#vm이 가지고 있는 내부 ip 기입
cephadm bootstrap --mon-ip 172.25.0.139 --allow-fqdn-hostname
sudo cephadm install ceph-common
```

```bash
#install 완료시 제공되는 정보들
URL: https://kisti-jjh2:8443/
	    User: admin
	Password: tfvi8fb8uh

#ceph tools가 설치되어 있는 cluster container 접속 command 제공
You can access the Ceph CLI with:

	sudo /sbin/cephadm shell --fsid e13eef96-4f66-11ed-8fae-fa163ec466bd -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

#disk ceph에 mount되지 않고 남아있는 여유 disk를 osd에 mount
ceph orch apply osd --all-available-devices
```

```bash
#pool 생성
ceph osd pool create kubernetes

#생성된 pool 초기화(사용준비)
ceph osd pool application enable kubernetes rbd
rbd pool init kubernetes

#Kubernetes 및 ceph-csi 용 새 사용자 생성 및 가져오기 - secret에 기입
ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes' mgr 'profile rbd pool=kubernetes'

#Ceph 클러스터 고유 fsid 와 모니터 주소 확인 - configmap에 기입
ceph mon dump
```

**RGW Service**

```bash
#초기 rgw 배포
#ceph orch apply <유형> <name>
ceph orch apply rgw foo

#rgw Label 추가
#ceph orch host label add <hostname> <name>
ceph orch host label add ceph-test rgw

#rgw 자동자격 증명이 자동으로 기본 dashboard로 생성되어 있는 것을 수동 커맨드 적용
ceph dashboard set-rgw-credentials
```

**MDS Service**

```bash
#ceph fs volume create <name> --placement="<개수> <hostname>"
ceph fs volume create fs-test --placement="1 ceph-test"
#YAML 파일을 통해 MDS를 설정
vi mds.yaml
service_type: mds
service_id: fs_name
placement:
  count: 3

ceph orch apply -i mds.yaml
```

**~~iSCSI Service - 패스~~**

```yaml
iSCSI gateway 를 생성합니다.

https://docs.ceph.com/en/pacific/cephadm/mon

yaml 샘플

service_type: iscsi
service_id: iscsi
placement:
  hosts:
  - [...]
spec:
  pool: iscsi_pool
  trusted_ip_list: "IP_ADDRESS_1,IP_ADDRESS_2,IP_ADDRESS_3,..."
  api_user: API_USERNAME
  api_password: API_PASSWORD
  api_secure: true
  ssl_cert: |
    -----BEGIN CERTIFICATE-----
    MIIDtTCCAp2gAwIBAgIYMC4xNzc1NDQxNjEzMzc2MjMyXzxvQ7EcMA0GCSqGSIb3
    DQEBCwUAMG0xCzAJBgNVBAYTAlVTMQ0wCwYDVQQIDARVdGFoMRcwFQYDVQQHDA5T
    [...]
    -----END CERTIFICATE-----
  ssl_key: |
    -----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC5jdYbjtNTAKW4
    /CwQr/7wOiLGzVxChn3mmCIF3DwbL/qvTFTX2d8bDf6LjGwLYloXHscRfxszX/4h
    [...]
    -----END PRIVATE KEY-----
```

# kubernetes에서 pv로 ceph 사용하기

#ceph의 clusterID와 IP:port정보 정의

- csi-config-map.yaml
    
    ```bash
    cat <<EOF > csi-config-map.yaml
    ---
    apiVersion: v1
    kind: ConfigMap
    data:
      config.json: |-
        [
          {
            "clusterID": "b9127830-b0cc-4e34-aa47-9d1a2e9949a8",
            "monitors": [
              "192.168.1.1:6789",
              "192.168.1.2:6789",
              "192.168.1.3:6789"
            ]
          }
        ]
    metadata:
      name: ceph-csi-config
    EOF
    ```
    

#Ceph 클러스터와 통신하기 위한 cephx 자격 증명 - 생성 된 Kubernetes 사용자 ID 및 cephx 키

- csi-rbd-secret.yaml
    
    ```bash
    cat <<EOF > csi-rbd-secret.yaml
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: csi-rbd-secret
      namespace: default
    stringData:
      userID: kubernetes
      userKey: AQD9o0Fd6hQRChAAt7fMaSZXduT3NWEqylNpmg==
    EOF
    ```
    

#KMS(키 관리 서비스) 공급자 세부 정보를 정의 - 없어도 생성 필요(최신버전)

- csi-kms-config-map.yaml
    
    ```bash
    cat <<EOF > csi-kms-config-map.yaml
    ---
    apiVersion: v1
    kind: ConfigMap
    data:
      config.json: |-
        {}
    metadata:
      name: ceph-csi-encryption-kms-config
    EOF
    ```
    

#CSI 컨테이너 내부의 ceph.conf 파일에 추가할 Ceph 구성 정의 - 없어도 생성 필요(최신버전)

- ceph-config-map.yaml
    
    ```bash
    cat <<EOF > ceph-config-map.yaml
    ---
    apiVersion: v1
    kind: ConfigMap
    data:
      ceph.conf: |
        [global]
        auth_cluster_required = cephx
        auth_service_required = cephx
        auth_client_required = cephx
      # keyring is a required key and its value should be empty
      keyring: |
    metadata:
      name: ceph-config
    EOF
    ```
    

#yaml 배포

```bash
kubectl apply -f csi-config-map.yaml
kubectl apply -f csi-kms-config-map.yaml
kubectl apply -f ceph-config-map.yaml
kubectl apply -f csi-rbd-secret.yaml

#ceph-csi 배포 YAML
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-provisioner-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-nodeplugin-rbac.yaml

#ceph-csi 프로비저닝 도구와 노드 플러그인
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-rbdplugin-provisioner.yaml
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-rbdplugin.yaml
```

#StorageClass create

```bash
cat <<EOF > csi-rbd-sc.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: csi-rbd-sc
provisioner: rbd.csi.ceph.com
parameters:
   clusterID: b9127830-b0cc-4e34-aa47-9d1a2e9949a8
   pool: kubernetes
   imageFeatures: layering
   csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
   csi.storage.k8s.io/provisioner-secret-namespace: default
   csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
   csi.storage.k8s.io/controller-expand-secret-namespace: default
   csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
   csi.storage.k8s.io/node-stage-secret-namespace: default
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
   - discard
EOF

```

clusterID - fsid 기입

allowVolumeExpansion - pvc 변경시 용량 증가 가능

#pvc create

```bash
cat <<EOF > raw-block-pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: raw-block-pvc
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Block
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-rbd-sc
EOF
```

#pod create

```bash
cat <<EOF > raw-block-pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-raw-block-volume
spec:
  containers:
    - name: fc-container
      image: fedora:26
      command: ["/bin/sh", "-c"]
      args: ["tail -f /dev/null"]
      volumeDevices:
        - name: data
          devicePath: /dev/xvda
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: raw-block-pvc
EOF
```

#pvc생성되면서 ceph에 생성되었는지 확인

```bash
rbd list kubernetes
```

# helm으로 ceph-csi-rbd 설치하기

#위의 yaml파일들을 helm으로 설치하는 방법

```
helm repo add ceph-csi https://ceph.github.io/csi-charts
helm fetch ceph-csi/ceph-csi-rbd --untar

custom.ymal 작성 후
helm install ceph-csi-rbd -n ceph-csi --create-namespace -f custom.yaml .

#기본 sc로 사용
kubectl patch storageclass csi-rbd-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

custom.yaml

```yaml
#clusterID에 fsid 값 기입 
csiConfig:
  - clusterID: "0f2a2534-55c4-11ed-841d-434484286646"
    monitors:
      - "172.25.0.36:6789"

provisioner:
  replicaCount: 1

storageClass:
  create: true
  clusterID: 0f2a2534-55c4-11ed-841d-434484286646 #clusterID에 fsid 값 기입 
  pool: kubernetes #osd pool create로 생성한 pool 이름

secret:
  create: true
  name: csi-rbd-secret
#auth get-or-create로 생성한 사용자 키값
  userID: kubernetes
  userKey: AQDPMlpjKEE8FxAAw4uQBRhYmqoZuM/mQyYZtA==
  #encryptionPassphrase: ""

##암호화 key에 관련된 밸류값으로
##helm에 if문으로 처리되어있지 않아서 무조건 값이 들어가서 nui오류 발생
##**templates/secret.yaml파일의** encryptionPassphrase에 관한 값을 "**제거"**해야함
```

#클러스터 삭제

```bash
#ceph 클러스터 {fsid} 기입
sudo /usr/sbin/cephadm rm-cluster --fsid 6d6fa746-55c3-11ed-b24a-a900200f0a00 --force

#mount된 disk 이름 기입 {vdb}
dd if=/dev/zero of=/dev/vdb bs=1M count=1000

rm -rf /dev/mapper/ceph*
```

---

# 트러블 슈팅

# 대쉬보드에서 grafana 값 못 가져오는 현상 해결

```yaml
cluster - manager modules - dashboards 탭 안의 IP값들을 변경
```

# dashboards http로 바꾸고 admin 계정 활성화하기

https://documentation.suse.com/ses/7/html/ses-all/dashboard-initial-configuration.html

https://documentation.suse.com/ses/7/html/ses-all/dashboard-user-roles.html

```bash
#helm 차트에서 먼저 false로 upgrade후 변경이 안 됐으면 toolbox에서 ssl 비활성화 
ceph config set mgr mgr/dashboard/ssl false

#dashboard 재시작으로 설정 변경 적용
ceph mgr module disable dashboard
ceph mgr module enable dashboard

#대쉬보드 IP:Port 확인
ceph mgr services

#관리자 계정 비활성화 되었으므로 다시 활성화하기 (이번 케이스에서 자동으로 비활성화 되었음.)
ceph dashboard ac-user-enable admin

#--tip--# 대쉬보드 계정 만들기
cat <<EOF > ~/passwd
qwer1234
EOF
ceph dashboard ac-user-create jjh -i ~/passwd
ceph dashboard ac-user-enable jjh
ceph dashboard ac-user-set-roles jjh administrator
```

# ceph 문제해결 명령어

#**HEALTH_WARN** 3 mgr modules have recently crashed

```bash
ceph crash archive-all
```

**#이건 …kubernetes 버전의 ceph의 백엔드 서비스 모듈 활성화하는 것**

```bash
ceph mgr module enable rook
ceph orch set backend rook

#취소하기
ceph mgr module disable rook
ceph orch set backend cephadm
```

~~#**CEPH OBJECT GATEWAY(개체 게이트웨이 활성화) (deploy로 ceph를 배포했을때)**~~

https://docs.ceph.com/en/nautilus/start/quick-rgw/

```bash
ceph-deploy install --rgw ceph-test

#첫 명령어가 안 먹을 때 - pip버전이 높아서 동작 명령어가 달라짐. pip버전을 낮추든 ceph-deploy버전을 높여야함
#ceph-deploy 최신버전 갖고오기
pip3 install git+https://github.com/ceph/ceph-deploy.git

#local/bin에 들어가서 PATH에 등록 안 되어있는 경로일 수 있음
/usr/local/bin/ceph-deploy install --rgw ceph-test
```

**#wget 증명서를 확인하는 과정을 생략하기(issued by ‘CN=R3,O=Let's Encrypt,C=US)**

```bash
**echo "check_certificate = off" >> ~/.wgetrc**
```

**#pool 삭제**

```bash
ceph tell mon.\* injectargs '--mon-allow-pool-delete=true'
ceph osd pool rm <poolname> <poolname> --yes-i-really-really-mean-it
```

**#pool rbr가 사용하도록 태깅**

```bash
rbd pool init hello
```

#**too many PGs per OSD**

```yaml
#1. Number of OSD
ceph osd ls

#2. Number of Pools
ceph osd pool ls

#3. Replication Count
ceph osd dump | grep repli

Total PGs = (Total_number_of_OSD * 100) / max_replication_count
권장 pool당 PGs = (Total_number_of_OSD * 100) / max_replication_count / Number of Pools 

#ceph osd pool set <poolname> pg_num <num>
ceph osd pool set ceph-objectstore.rgw.control pg_num 16
```

#**no active mgr**

```bash
kubectl rollout restart deployment -n rook-ceph rook-ceph-mgr-a
kubectl rollout restart deployment -n rook-ceph rook-ceph-mgr-b

or

systemctl restart ceph-mgr###~~~뒤에 컨테이너 이름이 붙어있음
```

# init 무한 루프

https://stackoverflow.com/questions/63456581/1-pg-undersized-health-warn-in-rook-ceph-on-single-node-clusterminikube/63472905#63472905

```bash
#기본 규칙 확인
ceph osd crush rule dump replicated_rule
#pool list 확인
ceph osd pool ls

#pool의 pg상태 확인 - 오류 발생 확인
ceph pg ls-by-pool kubernetes
#pg가 기본 규칙을 사용중인지 확인
ceph osd pool get kubernetes crush_rule

#새로운 규칙 생성 
#osd crush rule create-replicated <name> <root> <type> [<class>]
ceph osd crush rule create-replicated replicated_rule_osd default osd

#pool에 적용되는 규칙 바꾸기
#ceph osd pool set <pool name> <rule name> <rule name>
ceph osd pool set kubenertes crush_rule replicated_rule_osd

#규칙이 바뀌었는지 확인
ceph osd pool get device_health_metrics crush_rule
```

---

# rgw 외부 노출시켜서 S3 api로 접근하기

https://rook.io/docs/rook/v1.10/Storage-Configuration/Object-Storage-RGW/object-storage/#create-a-bucket

```bash
#helm 설치 기준으로 테스트된 환경
#helm으로 ceph설치 시 기본적인 모듈들은 모두 같이 설치됨
CephObjectStore가 기본적인 오브젝트 저장소의 모듈들을 관리 및 설치함으로 가장 중요

kubectl -n rook-ceph get pod -l app=rook-ceph-rgw
해당 명령어로 나오는 pod가 오브젝트 저장소를 관리

svc중 rook-ceph-rgw-ceph-objectstore로 로컬에서 접근이 가능하며
외부에 오브젝트 저장소를 노출시킬려면 새로운 svc를 생성 해야함
#하위 페이지에 해당 yaml 첨부
```

![Untitled](ceph_img/Untitled.png)

![Untitled](ceph_img/Untitled%201.png)

- external svc.yaml
    
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: rook-ceph-rgw-my-store-external
      namespace: rook-ceph
      labels:
        app: rook-ceph-rgw
        rook_cluster: rook-ceph
        rook_object_store: my-store
    spec:
      ports:
      - name: http
        port: 80
        protocol: TCP
        targetPort: 8080
      selector:
        app: rook-ceph-rgw
        ceph_daemon_id: ceph-objectstore
        rgw: ceph-objectstore
        rook_cluster: rook-ceph
        rook_object_store: ceph-objectstore
      sessionAffinity: None
      type: NodePort
    ```
    
    ```yaml
    helm기준 pod가 사용하는 포트는 8080.
    
    seletor가 중요
    kind: CephObjectStore가 사용하는 이름으로 매칭
    
    #-- 자동으로 생성되는 rook-ceph-rgw-ceph-objectstore 서비스와 똑같이 만들면 됨
    #-- 해당 svc를 nodeport로 변경은 동기화되고 있어서 불가능하지만
    #-- svc를 추가로 생성하면 외부로 노출 가능
    ```
    
    ![Untitled](ceph_img/Untitled%202.png)
    
    ```bash
    <hostIP>:<NodePort>가 s3의 주소가 됨
    ```
    

**ingress로 외부에 노출**

```yaml
#ingress로 내부에 접근하여 사용, ceph랑 같은 namespace에 배포
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --version 4.4.0 -n rook-ceph --create-namespace

#ingress-nginx-controller 서비스가 공인아이피를(loadbalacner) 갖고 있고
#DNS설정에서 URL이 해당 공인아이피를 바라보도록 설정한다.
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: s3
  namespace: rook-ceph
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-headers: "X-Forwarded-For"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "120"
spec:
  ingressClassName: nginx
  rules:
    - host: s3.kuberixtest.kro.kr #DNS가 자신의 IP로 설정되어 바라보는 URL
      http:
        paths:
          - pathType: Prefix
            backend:
              service:
                name: rook-ceph-rgw-ceph-objectstore #같은 namespace의 실제 접근할 SVC
                port:
                  number: 80 # 서비스의 포트
            path: /
```

---

**pod에 적용하기**

```bash
오브젝트 저장소를 사용하는 pod 생성
1. StorageClass
2. ObjectBucketClaim # <-> pvc와 같은 개념이지만 다른 kind를 사용
3. pod # <-> env을 통해 탑재

하위 페이지에서 yaml파일과 함께 설명 추가
```

- StorageClass.yaml
    
    ```yaml
    #helm과 함께 배포되지만 설명을 위한 페이지
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
       name: rook-ceph-bucket
    provisioner: rook-ceph.ceph.rook.io/bucket
    reclaimPolicy: Delete
    parameters:
      objectStoreName: ceph-objectstore #kind: cephobjectstore로 Connected된 이름을 기입
      objectStoreNamespace: rook-ceph #개별 namespace 리소스
      region: us-east-1 #S3의 호환 리전을 명시(미사용할 예정)
    ```
    
- ObjectBucketClaim.yaml
    
    ```yaml
    apiVersion: objectbucket.io/v1alpha1
    kind: ObjectBucketClaim
    metadata:
      name: ceph-bucket
      namespace: rook-ceph
    spec:
      generateBucketName: ceph-bkt #해당 이름으로 버켓이름이 생성됨
      storageClassName: ceph-bucket #PROVISIONER가 rook-ceph.ceph.rook.io/bucket로 사용중인 storageClass를 명시
    ```
    
- pod.yaml
    
    https://rook.io/docs/rook/v1.10/Storage-Configuration/Object-Storage-RGW/ceph-object-bucket-claim/#app-pod
    
    ```yaml
    #테스트에서 실행한 pod.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: pod-test
      namespace: rook-ceph
    spec:
      containers:
        - name: fc-container
          image: fedora:26
          command: ["/bin/sh", "-c"]
          args: ["tail -f /dev/null"]
          envFrom:
          - configMapRef:
              name: ceph-bucket
          - secretRef:
              name: ceph-bucket
    
    #envFrom부분 설명
    StorageClass가 pod의 생성요청에 의해 ObjectBucketClaim에 요청-응답하는 순간
    해당 namespace에 configmap과 secret이 ObjectBucketClaim의 이름으로 생성됨
    
    configmap에는 BUCKET_HOST, BUCKET_PORT, BUCKET_NAME 가 생성되며
    secret에는 AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY 가 생성됨
    ```
    
    ```yaml
    #configmap 불필요 정보 제거
    apiVersion: v1
    data:
      BUCKET_HOST: rook-ceph-rgw-ceph-objectstore.rook-ceph.svc
      BUCKET_NAME: ceph-bkt-ce4e5fc1-397f-4b0f-9890-c3b58216c413
      BUCKET_PORT: "80"
      BUCKET_REGION: ""
      BUCKET_SUBREGION: ""
    kind: ConfigMap
    metadata:
      name: ceph-bucket
      namespace: rook-ceph
      ownerReferences:
      - apiVersion: objectbucket.io/v1alpha1
        blockOwnerDeletion: true
        controller: true
        kind: ObjectBucketClaim
        name: ceph-bucket
    ```
    
    ```yaml
    #secert
    apiVersion: v1
    data:
      AWS_ACCESS_KEY_ID: QVA4T0NFN1M0TVczMEg4NVI2SFE=
      AWS_SECRET_ACCESS_KEY: MkEzSmR6d0JTRnN6R0xDVmVFQnk1UmlSNU5wbHBSY3dmdENWdUxlTg==
    kind: Secret
    metadata:
      name: ceph-bucket
      namespace: rook-ceph
      ownerReferences:
      - apiVersion: objectbucket.io/v1alpha1
        blockOwnerDeletion: true
        controller: true
        kind: ObjectBucketClaim
        name: ceph-bucket
    ```
    

---

**s3 api로 접근 확인**

```bash
s3cmd --configure
```

![Untitled](ceph_img/Untitled%203.png)

```bash
Access Key와 Secret Key는 Object Gateway -> Users의 Key값을 사용
Default Region은 기본 값을 사용.
S3 Endpoint는 rook-ceph-rgw-my-store-external의 HOST IP와 NodePort를 사용.
accessing a bucket은 위의 주소를 그대로 사용하거나 버켓 경로까지 기입.
Use HTTPS protocol은 no로 설정한다(yes일 경우 ca.cert파일 필요)
```

![Untitled](ceph_img/Untitled%204.png)

![Untitled](ceph_img/Untitled%205.png)

![Untitled](ceph_img/Untitled%206.png)

---

```bash
s3cmd ls 명령어로 연동된 것을 확인
```

![Untitled](ceph_img/Untitled%207.png)

![Untitled](ceph_img/Untitled%208.png)

---

# minio gateway mode로 연동하기

#2022 2월에 gateway모드 6개월간 유지 후 지원 종료를 공지 - 2022년 10월 24일 버전으로 지원 종료

#s3를 지원 종료가 되지 않은 minio 버전을 사용해야함.

#해당 helm chart는 minio:RELEASE.2021-02-14T04-01-33Z 버전

```yaml
helm repo add minio https://helm.min.io/
helm install -n minio minio minio/minio --version 8.0.10 --create-namespace

helm install -n minio minio minio/minio -f custom.yaml --version 8.0.10 --create-namespace
```

custom.yaml

```yaml
persistence:
  enabled: true
  size: 5Gi

service:
  type: NodePort
  port: 9000
  nodePort: 32000

s3gateway: # minio를 s3 server가 아닌 s3를 보여주는 gateway mode로 사용
  enabled: true
  replicas: 4 
  serviceEndpoint: "http://s3.srrain.kro.kr" #s3 endpoint 주소
  accessKey: "YZJN6UBIXY48IE0O6A2D"    #ceph object 유저의 accesskey
  secretKey: "qQpHInBo3YV4kAVAtwbLidVYsM6NQY6YURuQCm7E" #ceph object 유저의 secretkey
```

<details>
<summary>minio를 s3 지원하는 마지막 버전을 yaml파일로 배포하기</summary>
<div markdown="1">

# yaml로 minio gateway 마지막 버전 배포

```bash
pod가 secret값을 참조하기에 secret을 먼저 생성한다.
data 값은 base64로 변환한 값을 기입한다.
Ceph의 Object Gateway User의 Key를 base64로 암호화하여 기입한다.
---
sercet 설명

accesskey: admin ID (admin)
secretkey: secretkey (qwer12341)

awsAccessKeyId  #ceph object 유저의 accesskey
awsSecretAccessKey #ceph object 유저의 secretkey

---
pod 설명
 args:
 - minio gateway s3 http://s3.srrain.kro.kr  --console-address :9001
minio를 s3 gateway로 실행하고 바라볼 주소와 console을 어떤 포트로 오픈할 것인지 
미 입력시 랜덤 포트 오픈 (sevice expose가 어려움)

env는 같은 namespace의 secret값을 참조한다.
---
service 설명
name: http
 minio 파드 동작 시 api가 9000포트로 오픈됨: pod-svc port매칭
name: console
 minio 파드 동작 시 --console-address 포트로 오픈됨: pod-svc port매칭
```

secret.yaml

```yaml
apiVersion: v1
data:
  accesskey: YWRtaW4K
  secretkey: cXdlcjEyMzQxCg==
  awsAccessKeyId: WVpKTjZVQklYWTQ4SUUwTzZBMkQ=
  awsSecretAccessKey: cVFwSEluQm8zWVY0a0FWQXR3YkxpZFZZc002TlFZNllVUnVRQ203RQ==
kind: Secret
metadata:
  labels:
    app: minio
    release: minio
  name: minio
  namespace: minio-dev
type: Opaque
```

pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: minio
  name: minio
  namespace: minio-dev # Change this value to match the namespace metadata.name
spec:
  containers:
  - name: minio
    image: quay.io/minio/minio:RELEASE.2022-07-30T05-21-40Z
    command:
    - /bin/bash
    - -c
    args:
    - minio gateway s3 http://s3.srrain.kro.kr  --console-address :9001
    ports:
    - containerPort: 9000
      name: http
      protocol: TCP
    - containerPort: 38389
      name: console
      protocol: TCP
    env:
    - name: MINIO_ROOT_USER
      valueFrom:
        secretKeyRef:
          key: accesskey
          name: minio
    - name: MINIO_ROOT_PASSWORD
      valueFrom:
        secretKeyRef:
          key: secretkey
          name: minio
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          key: awsAccessKeyId
          name: minio
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          key: awsSecretAccessKey
          name: minio
    volumeMounts:
    - mountPath: /data
      name: localvolume # Corresponds to the `spec.volumes` Persistent Volume
  volumes:
  - name: localvolume
    hostPath: # MinIO generally recommends using locally-attached volumes
      path: /mnt/disk1/data # Specify a path to a local drive or volume on the Kubernetes worker node
      type: DirectoryOrCreate # The path to the last directory must exist
```

service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: minio
  name: minio
  namespace: minio-dev
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: http
    port: 9000
    protocol: TCP
    targetPort: 9000
  - name: console
    port: 9001
    protocol: TCP
    targetPort: 9001
  selector:
    app: minio
  sessionAffinity: None
  type: ClusterIP
```
</div>
</details>