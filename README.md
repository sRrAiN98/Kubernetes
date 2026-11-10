# Kubernetes Cloud-Native & DevOps Ecosystem

[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat-square&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/helm-%230F1689.svg?style=flat-square&logo=helm&logoColor=white)](https://helm.sh/)
[![ArgoCD](https://img.shields.io/badge/argocd-%23EF7B4D.svg?style=flat-square&logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Prometheus](https://img.shields.io/badge/prometheus-%23E6522C.svg?style=flat-square&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=flat-square&logo=grafana&logoColor=white)](https://grafana.com/)
[![Istio](https://img.shields.io/badge/istio-%23466BB0.svg?style=flat-square&logo=istio&logoColor=white)](https://istio.io/)

엔터프라이즈 및 하이브리드 클라우드 환경에서 검증된 **Kubernetes 인프라 구성, GitOps 지속적 배포 파이프라인, MLOps 플랫폼, 풀스택 옵저버빌리티(Observability)** 레퍼런스 아키텍처 및 Helm/YAML 매니페스트 저장소입니다.

---

## 📑 목차 (Table of Contents)

1. [아키텍처 개요 (Overview)](#-아키텍처-개요)
2. [컴포넌트 맵 & 디렉터리 구성 (Repository Map)](#-컴포넌트-맵--디렉터리-구성)
   - [GitOps & CI/CD Platform](#1-gitops--cicd-platform)
   - [Observability & APM](#2-observability--apm-모니터링--분산-추적)
   - [AI & MLOps Platform](#3-ai--mlops-platform)
   - [Core Infrastructure & Security](#4-core-infrastructure-storage--security)
   - [Sample Microservices](#5-sample-applications)
3. [보안 및 시크릿 관리 가이드 (Security & Secret Management)](#-보안-및-시크릿-관리-가이드)
4. [빠른 시작 (Quick Start)](#-빠른-시작-quick-start)

---

## 🏗️ 아키텍처 개요

본 저장소는 Kubernetes 클러스터 운영 시 요구되는 핵심 생태계를 5가지 도메인으로 체계화하여 관리합니다:

```
                      [ External Traffic / Ingress NGINX ]
                                       │
                         [ Istio Service Mesh (mTLS) ]
                                       │
     ┌───────────────────┬─────────────┴─────────────┬───────────────────┐
     ▼                   ▼                           ▼                   ▼
┌───────────────┐ ┌───────────────┐         ┌───────────────┐   ┌─────────────────┐
│ GitOps/CI/CD  │ │ Observability │         │ MLOps Platform│   │ Core Storage    │
├───────────────┤ ├───────────────┤         ├───────────────┤   ├─────────────────┤
│ • ArgoCD      │ │ • Prometheus  │         │ • Kubeflow    │   │ • Rook-Ceph     │
│ • ArgoRollouts│ │ • Grafana     │         │ • JupyterHub  │   │ • MinIO         │
│ • App of Apps │ │ • Loki / EFK  │         │ • Airflow     │   │ • PostgreSQL    │
│ • GitLab/CI   │ │ • OpenTelemetry│        │ • Milvus      │   │ • Redis         │
│ • Harbor      │ │ • Tempo/Jaeger│         │ • GPU Operator│   │ • Velero Backup │
└───────────────┘ └───────────────┘         └───────────────┘   └─────────────────┘
```

---

## 📂 컴포넌트 맵 & 디렉터리 구성

### 1. GitOps & CI/CD Platform
현대적인 선언형 배포와 자동화된 전달 파이프라인 구성을 다룹니다.

| 디렉터리 | 주요 기능 및 컴포넌트 | 설명 |
| :--- | :--- | :--- |
| [`argocd`](argocd/) | ArgoCD | GitOps 컨트롤러 설치, 초기 관리자 계정 구성 및 웹 UI 인그레스 설정 |
| [`argocd-rollout`](argocd-rollout/) | Argo Rollouts | 블루/그린(Blue-Green), 카나리(Canary) 무중단 배포 전략 및 메트릭 분석 연동 |
| [`argocd-infra-component`](argocd-infra-component/) | App of Apps (Infra) | 클러스터 인프라 컴포넌트(Prometheus, Loki, Istio, Ingress 등) 일괄 GitOps 배포 |
| [`appofapp`](appofapp/) | App of Apps Pattern v1 | 마이크로서비스 애플리케이션 일괄 배포 템플릿 (계정, 프론트, DB 등) |
| [`appofapp-v2`](appofapp-v2/) | App of Apps Pattern v2 | 고도화된 애플리케이션 동적 템플릿 (Django, LLM/HCX Bot, NGINX 프록시) |
| [`gitlab`](gitlab/) | GitLab Self-hosted | 온프레미스/쿠버네티스 기반 자체 구축 GitLab 인스턴스 |
| [`gitlab-runner`](gitlab-runner/) | GitLab Runner | 쿠버네티스 파드 오토스케일링 기반 CI/CD 실행 에이전트 |
| [`github-actions`](github-actions/) | GitHub Actions ARC | 쿠버네티스 클러스터 내부 Self-hosted Action Runner 구성 |
| [`jenkins`](jenkins/) | Jenkins on K8s | Helm 기반 Jenkins 마스터-동적 슬레이브 에이전트 배포 및 파이프라인 |
| [`gitea`](gitea/) | Gitea | 가볍고 빠른 경량 자체 호스팅 Git 서비스 |
| [`harbor`](harbor/) | Harbor Registry | 엔터프라이즈 컨테이너 이미지 레지스트리, Notary 서명 및 Trivy 취약점 검사 |

---

### 2. Observability & APM (모니터링 & 분산 추적)
메트릭(Metric), 로그(Log), 트레이스(Trace)의 세 가지 기둥(Three Pillars)을 완벽히 구축합니다.

| 디렉터리 | 주요 기능 및 컴포넌트 | 설명 |
| :--- | :--- | :--- |
| [`prometheus`](prometheus/) | Prometheus Stack | kube-prometheus-stack, Alertmanager 경보 룰, 노드/파드 모니터링 |
| [`grafanalog`](grafanalog/) | Grafana Dashboards | 통합 시각화 대시보드 구성 및 데이터 소스 연동 |
| [`logging-efk`](logging-efk/) | EFK / Opensearch | Elasticsearch/Opensearch + Fluentd/Fluent Bit + Kibana 엔터프라이즈 로깅 |
| [`logging-plg`](logging-plg/) | PLG Stack | Promtail + Loki + Grafana 기반 클라우드 네이티브 경량 로그 수집 시스템 |
| [`promtail`](promtail/) | Promtail DaemonSet | 노드 레벨 컨테이너 로그 스트리밍 수집기 |
| [`tracing`](tracing/) | Tracing Manifests | OpenTelemetry Collector, Tempo, Jaeger, Pinpoint 분산 추적 파이프라인 |
| [`tracing-guides`](tracing-guides/) | Tracing Architecture | APM/분산 트레이싱 상세 개념, 연동 매뉴얼 및 시각화 가이드 |
| [`opentelemetry-guide`](opentelemetry-guide/) | OpenTelemetry Guides | FastAPI, Python, Java 애플리케이션 SDK 자동 계측(Instrumentation) |

---

### 3. AI & MLOps Platform
대규모 AI 모델 서빙, 분산 학습, 데이터 엔지니어링을 위한 머신러닝 인프라입니다.

| 디렉터리 | 주요 기능 및 컴포넌트 | 설명 |
| :--- | :--- | :--- |
| [`kubeflow`](kubeflow/) | Kubeflow / DeployKF | 엔드투엔드 머신러닝 워크플로우, Katib 하이퍼파라미터 튜닝, KServe 모델 서빙 |
| [`jupyterhub`](jupyterhub/) | JupyterHub | KubeSpawner 기반 사용자별 동적 파드 할당, GPU 리소스 프로파일 분기 |
| [`airflow`](airflow/) | Apache Airflow | Celery/KubernetesExecutor 기반 대규모 배치 및 데이터 파이프라인 오케스트레이션 |
| [`milvus`](milvus/) | Milvus Vector DB | 분산 벡터 데이터베이스 클러스터 및 Milvus-Attu 웹 매니지먼트 |
| [`postgresql-vectordb`](postgresql-vectordb/) | pgvector PostgreSQL | RAG(검색 증강 생성) 및 임베딩 벡터 저장을 위한 PostgreSQL + pgvector |
| [`redis`](redis/) | Redis Cluster | 인메모리 고속 캐시 및 AI 실시간 세션/큐 처리 |

---

### 4. Core Infrastructure, Storage & Security
클러스터의 든든한 밑바탕이 되는 인프라, 분산 스토리지, 네트워크 메시 및 보안 도구입니다.

| 디렉터리 | 주요 기능 및 컴포넌트 | 설명 |
| :--- | :--- | :--- |
| [`gcp-gke`](gcp-gke/) | GCP GKE Cluster | Google Cloud GKE 클러스터 생성, VPC 네트워크 및 방화벽 설정 |
| [`gpu-operator`](gpu-operator/) | NVIDIA GPU Operator | Kubelet 드라이버 컨테이너, MIG(Multi-Instance GPU), GPU 메트릭 모니터링 |
| [`deepops`](deepops/) | NVIDIA DeepOps | GPU 클러스터 및 HPC(고성능 컴퓨팅) 인프라 프로비저닝 가이드 |
| [`ceph`](ceph/) | Rook-Ceph | 쿠버네티스 네이티브 분산 스토리지 (Block RWO, Shared Filesystem RWX, S3 Object) |
| [`istio`](istio/) | Istio Service Mesh | Istio Ingress Gateway, VirtualService, mTLS 트래픽 암호화 및 트래픽 분할 |
| [`nginx-ingress`](nginx-ingress/) | Ingress NGINX | 인그레스 컨트롤러 설정 및 네임스페이스 간(Cross-Namespace) 프록시 라우팅 |
| [`trivy`](trivy/) | Trivy | CI/CD 파이프라인 컨테이너 이미지 및 K8s 매니페스트 보안 취약점 자동 분석 |
| [`velero`](velero/) | Velero Backup | MinIO/S3 오브젝트 스토리지를 연동한 쿠버네티스 리소스 및 볼륨 스냅샷 백업/복구 |
| [`kubesphere`](kubesphere/) | KubeSphere | 멀티 테넌트 관리 및 통합 콘솔을 제공하는 엔터프라이즈 컨테이너 플랫폼 |

---

### 5. Sample Applications
실제 MSA 환경을 검증할 수 있는 엔터프라이즈 마이크로서비스 예제 모음입니다.

| 디렉터리 | 주요 기능 및 컴포넌트 | 설명 |
| :--- | :--- | :--- |
| [`test-spring`](test-spring/) | Spring Cloud MSA | Spring Cloud Gateway, Eureka/K8s 서비스 디스커버리, Config, MongoDB Helm 차트 |

---

## 🔒 보안 및 시크릿 관리 가이드

> [!IMPORTANT]
> **보안 원칙 (Security First)**
> 1. 본 저장소의 모든 설정 파일, Helm 차트, README 예제에서 실제 개인 도메인, 개인 이메일 주소, 외부 공인 IP, GitLab Personal Access Token, OAuth Client Secret, 클라우드 Access Key는 제거되었으며 안전한 플레이스홀더(`example.com`, `<SECRET_TOKEN>`, `192.0.2.x` 등)로 표준화되었습니다.
> 2. 실제 운영 환경에 배포 시에는 `.env.example`을 참고하여 환경변수를 구성하시고, Git에 민감정보가 직접 커밋되지 않도록 주의하십시오.
> 3. 운영 환경에서는 **External Secrets Operator (ESO)**, **HashiCorp Vault**, 또는 **Sealed Secrets**를 연동하여 시크릿을 안전하게 주입하는 것을 강력히 권장합니다.

---

## 🚀 빠른 시작 (Quick Start)

### 1. 사전 요구사항
- `kubectl` v1.24+
- `helm` v3.8+
- 접속 가능한 Kubernetes 클러스터 (`kubeconfig` 구성 완료)

### 2. 저장소 클론
```bash
git clone https://github.com/sRrAiN98/Kubernetes.git
cd Kubernetes
```

### 3. 인프라 코어 컴포넌트 배포 예시 (ArgoCD App of Apps)
```bash
# 1. ArgoCD 설치
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. 인프라 통합 컴포넌트 GitOps 배포
kubectl apply -f argocd-infra-component/infrastructure-app-of-apps.yaml
```

---

## 📄 라이선스 (License)

본 저장소의 모든 매니페스트와 가이드는 교육 및 클라우드 네이티브 아키텍처 연구 목적으로 자유롭게 활용하실 수 있습니다.
