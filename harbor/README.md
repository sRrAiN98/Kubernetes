# Harbor 엔터프라이즈 컨테이너 레지스트리 구축 및 운영 가이드

쿠버네티스 환경에서 자체 프라이빗 이미지 저장소인 **Harbor**를 Helm으로 배포하고, 공인 TLS 인증서 연동 및 도커 이미지 태깅/푸시 파이프라인을 구성하는 실무 가이드입니다.

---

## 1. Helm Repository 등록 및 차트 다운로드

```bash
helm repo add harbor https://helm.goharbor.io
helm repo update
helm fetch harbor/harbor --untar
cd harbor
```

---

## 2. 공인 TLS 인증서 Secret 생성

도커 클라이언트는 HTTPS 보안 통신을 기본으로 요구하므로, 발급받은 공인 인증서(개인 키 + 인증서 체인)로 Secret을 먼저 생성합니다.

> [!TIP]
> **인증서 체인 합치기 순서**
> 인증서 번들(`certificate.crt`)은 반드시 아래 순서대로 합쳐서 작성해야 브라우저 및 도커 데몬에서 신뢰성 오류가 발생하지 않습니다:
> 1. 발급받은 도메인 인증서
> 2. 중개(Intermediate) CA 인증서
> 3. 루트(Root) CA 인증서

```bash
kubectl create namespace harbor
kubectl create secret tls harbor-tls \
  --key="private.key" \
  --cert="certificate.crt" \
  -n harbor
```

---

## 3. `values.yaml` 핵심 설정

```yaml
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: "harbor-tls"
      notarySecretName: "harbor-tls"
  ingress:
    hosts:
      core: core.harbor.example.com
      notary: notary.harbor.example.com
    className: nginx

externalURL: https://core.harbor.example.com

# 지속성 스토리지 설정 (RWO 또는 S3/Ceph 연동)
persistence:
  enabled: true
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      size: 100Gi
```

설치 명령어:
```bash
helm install harbor -n harbor -f values.yaml .
```

* 참고: 공인 인증서 및 Ingress 등록 확인 시 컨트롤러 상태에 따라 1~2분 정도 소요될 수 있습니다.

---

## 4. 도커 이미지 빌드, 태그 및 푸시 실습

Harbor 웹 콘솔(`https://core.harbor.example.com`)에 `admin`으로 로그인 후 신규 프로젝트(예: `spring`)를 생성합니다.

### 1) 도커 로그인
```bash
docker login core.harbor.example.com
# Username: admin
# Password: <YOUR_HARBOR_ADMIN_PASSWORD>
```

### 2) 이미지 태그 지정 및 푸시
```bash
# 기본 문법: docker tag [원본이미지]:[태그] core.harbor.example.com/[프로젝트명]/[이미지명]:[태그]
docker tag nginx:latest core.harbor.example.com/spring/nginx:0.1
docker push core.harbor.example.com/spring/nginx:0.1
```

푸시가 완료되면 Harbor 웹 콘솔의 `spring` 프로젝트 리포지토리 목록에서 푸시된 이미지와 Trivy 취약점 자동 스캔 결과를 확인할 수 있습니다.
