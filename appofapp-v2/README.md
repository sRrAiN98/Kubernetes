# ArgoCD App of Apps 배포 패턴 v2 (고도화 템플릿)

기존 v1 버전에서 발생하던 클러스터 변수 주입 한계와 네임스페이스 강제 문제를 개선하여, **서비스별 독립 네임스페이스 지정 및 동적 템플릿 제어**가 가능하도록 개선한 **App of Apps 패턴(v2)** 가이드입니다.

---

## 1. v1 대비 주요 개선 사항

* **독립적인 네임스페이스 지원**:
  * 기존 v1에서는 `range` 루프를 사용해 모든 차트를 동일한 네임스페이스/클러스터에 일괄 배포하도록 되어 있었습니다.
  * v2에서는 각 차트(예: Django 웹, AI 봇/API, NGINX 프록시)마다 목적에 맞게 서로 다른 네임스페이스(`web`, `ai` 등)로 분기 배포할 수 있도록 개별 템플릿 구조로 분리했습니다.
* **유연한 템플릿 변수 관리**:
  * 루트 `/apps`에서 ArgoCD Application 레벨의 소스 저장소, 브랜치, 대상 클러스터 변수를 중앙에서 관리합니다.
  * 실제 각 서비스 차트(`django`, `file2text`, `hcxapi`, `hcxbot`, `nginx-django`)는 독립된 서브차트로 유지됩니다.

---

## 2. 디렉터리 구성 및 배포 흐름

```
[ application.yaml ] (최상위 루트 ArgoCD Application)
         │
         ▼
     [ apps/ ]        (ArgoCD Applications 템플릿)
   ├── templates/
   │   ├── django.yaml
   │   ├── file2text.yaml
   │   ├── hcxapi.yaml
   │   ├── hcxbot.yaml
   │   └── nginx-django.yaml
   └── values.yaml    (중앙 배포 변수 관리)
         │
         ▼
[ 각 서비스 Helm 차트 ]
   ├── django/
   ├── file2text/
   ├── hcxapi/
   ├── hcxbot/
   └── nginx-django/
```

---

## 3. 배포 실행 절차

```bash
# 1. 최상위 부트스트랩 Application 적용
kubectl apply -f application.yaml

# 2. ArgoCD 콘솔에서 각 하위 애플리케이션(django, hcxbot 등)이 
#    각자의 목적지 네임스페이스로 자동 프로비저닝되는지 확인
```
