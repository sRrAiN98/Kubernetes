# Jenkins Kubernetes Helm 배포 가이드

공식 Jenkins Helm 차트를 활용하여 Kubernetes 클러스터 내에 Jenkins 마스터를 배포하고, 영구 스토리지(PV) 마운트 및 ServiceAccount를 구성하는 실무 가이드입니다.

---

## 1. Helm Repository 등록 및 사전 매니페스트 준비

```bash
helm repo add jenkinsci https://charts.jenkins.io/
helm repo update
helm fetch jenkinsci/jenkins --untar
```

공식 Jenkins Kubernetes 배포에 필요한 ServiceAccount 및 PV 템플릿을 다운로드합니다:

```bash
wget https://raw.githubusercontent.com/jenkins-infra/jenkins.io/master/content/doc/tutorials/kubernetes/installing-jenkins-on-kubernetes/jenkins-sa.yaml
wget https://raw.githubusercontent.com/jenkins-infra/jenkins.io/master/content/doc/tutorials/kubernetes/installing-jenkins-on-kubernetes/jenkins-volume.yaml
```

---

## 2. 네임스페이스 및 스토리지(PV/SA) 배포

데이터 보존을 위해 `jenkins-volume.yaml`의 `hostPath` 마운트 경로와 `storageClassName`을 지정한 뒤 적용합니다.

```yaml
# jenkins-volume.yaml 수정 예시
storageClassName: jenkins-pv
hostPath:
  path: /data/jenkins
  type: DirectoryOrCreate
```

```bash
kubectl create namespace jenkins
kubectl apply -f jenkins-sa.yaml
kubectl apply -f jenkins-volume.yaml
```

---

## 3. `values.yaml` 작성 및 Helm 설치

미리 생성한 ServiceAccount와 PV 볼륨을 사용하도록 Helm 설정을 작성합니다.

```yaml
# config.yaml
controller:
  serviceType: NodePort
persistence:
  storageClass: jenkins-pv
  size: "10Gi" # PV volume에 정의된 용량과 같거나 작게 지정
serviceAccount:
  create: false
  name: jenkins
```

```bash
helm install -n jenkins -f config.yaml jenkins jenkinsci/jenkins
```

---

## 4. 접속 주소 및 초기 관리자 비밀번호 확인

```bash
# NodePort 및 노드 IP 확인
export NODE_PORT=$(kubectl get --namespace jenkins -o jsonpath="{.spec.ports[0].nodePort}" services jenkins)
export NODE_IP=$(kubectl get nodes --namespace jenkins -o jsonpath="{.items[0].status.addresses[0].address}")
echo "접속 주소: http://$NODE_IP:$NODE_PORT/login"

# 초기 관리자(admin) 비밀번호 조회
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
```
