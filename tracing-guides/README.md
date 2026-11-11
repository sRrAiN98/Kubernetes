# Distributed Tracing & APM Architecture Guides (분산 추적 심화 가이드)

클라우드 네이티브 마이크로서비스 환경에서 요청 흐름의 가시성(Observability)을 확보하기 위한 **분산 추적(Distributed Tracing) 및 APM 솔루션별 아키텍처, 연동 매뉴얼, 트러블슈팅 가이드** 모음입니다.

---

## 📑 주요 가이드 목차

| 가이드 | 핵심 주제 | 상세 문서 |
| :--- | :--- | :--- |
| **Jaeger** | 분산 추적 기본 개념 및 Jaeger 백엔드 구축 | [`Tracing/Jaeger`](Tracing/Jaeger/README.md) |
| **Jaeger + OpenTelemetry** | OpenTelemetry Collector와 Jaeger 연동 파이프라인 | [`Tracing/Jaeger-Opentelemetry`](Tracing/Jaeger-Opentelemetry/README.md) |
| **OpenTelemetry for Docker** | 컨테이너 환경 OTel 수집기 및 애플리케이션 트레이싱 실습 | [`Tracing/OpenTelemetry for docker`](Tracing/OpenTelemetry%20for%20docker/README.md) |
| **OpenTelemetry for K8s** | 쿠버네티스 파드 자동 주입(Auto-Instrumentation) 및 CRD 설정 | [`Tracing/OpenTelemetry for k8s`](Tracing/OpenTelemetry%20for%20k8s/README.md) |
| **Tempo + Loki + Grafana** | 메트릭-로그-트레이스 원클릭 상관관계(Correlation) 추적 | [`Tracing/OpenTelemetry+Tempo+loki-grafana`](Tracing/OpenTelemetry+Tempo+loki-grafana/README.md) |
| **Pinpoint** | 바이트코드 인스트루멘테이션 기반 실시간 호출 토폴로지 분석 | [`Tracing/PinPoint`](Tracing/PinPoint/README.md) |

---

## 🚀 실제 배포 매니페스트

본 가이드에서 다루는 각 컴포넌트의 Helm 차트 및 Kubernetes 배포 매니페스트는 **[`../tracing`](../tracing/)** 디렉터리에 준비되어 있습니다.
