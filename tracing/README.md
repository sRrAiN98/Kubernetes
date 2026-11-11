# Distributed Tracing & APM Manifests (분산 추적 & APM 배포 매니페스트)

Kubernetes 클러스터 및 컨테이너 환경에서 마이크로서비스 간의 트랜잭션을 실시간으로 추적하고 지연 시간 병목을 진단하기 위한 **분산 추적(Distributed Tracing) 및 APM(Application Performance Monitoring)** Helm 차트와 YAML 매니페스트 모음입니다.

---

## 📂 서브 프로젝트 구성

| 디렉터리 | 주요 기술 스택 | 설명 |
| :--- | :--- | :--- |
| [`OpenTelemetry-for-docker`](OpenTelemetry-for-docker/) | Docker, OTel Collector | 로컬 Docker 환경에서 OpenTelemetry 수집기와 백엔드를 검증하는 실습 매니페스트 |
| [`OpenTelemetry-for-k8s`](OpenTelemetry-for-k8s/) | OTel Operator, Kubernetes | K8s 클러스터 환경에서 OpenTelemetry Collector 및 자동 계측(Instrumentation) 배포 |
| [`opentelemetry-tempo-loki`](opentelemetry-tempo-loki/) | OTel, Tempo, Loki, Grafana | 트레이스(Tempo), 로그(Loki), 메트릭(Prometheus)을 그라파나 대시보드와 통합 연동 |
| [`pinpoint-web`](pinpoint-web/) | Pinpoint, HBase | 대규모 트랜잭션 추적을 위한 Naver Pinpoint APM 웹/컬렉터 및 스토리지 매니페스트 |

---

## 📖 상세 아키텍처 및 이론 가이드

각 트레이싱 도구의 내부 동작 원리, 자동 인스트루멘테이션 설정법, 아키텍처 다이어그램 및 시각화 가이드는 **[`../tracing-guides`](../tracing-guides/)** 문서를 참고하세요.
