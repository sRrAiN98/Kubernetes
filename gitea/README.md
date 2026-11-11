# Gitea 경량 Git 서버 배포 가이드

GitLab 대비 메모리와 리소스를 매우 적게 소모(수백 MB 수준)하여 쿠버네티스 클러스터 내에서 빠르게 자체 Git 레포지토리를 운영할 수 있는 **Gitea**의 Helm 배포 가이드입니다.

---

## 1. Helm Repository 등록

```bash
helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo update
```

---

## 2. 빠른 원라이너 설치 (NodePort)

테스트 및 개발용으로 NodePort를 열어 빠르게 설치할 때 사용합니다.

```bash
helm install gitea -n gitea --create-namespace gitea-charts/gitea --set service.http.type=NodePort
```

---

## 3. 커스텀 배포 (`custom-values.yaml`)

관리자 계정 및 Ingress, Service를 사전에 정의하여 배포하는 방식입니다.

```bash
helm fetch gitea-charts/gitea --untar
cd gitea
```

### `custom-values.yaml` 작성
```yaml
gitea:
  admin:
    existingSecret: ""
    username: admin
    password: "<YOUR_GITEA_ADMIN_PASSWORD>"
    email: "admin@example.com"

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: git.example.com
      paths:
        - path: /
          pathType: Prefix

service:
  http:
    type: ClusterIP
    port: 3000
```

### 설치 실행
```bash
helm install gitea -n gitea --create-namespace -f custom-values.yaml .
```
