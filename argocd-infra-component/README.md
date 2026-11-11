# ArgoCD App of Apps 기반 인프라 코어 컴포넌트 통합 배포 가이드

ArgoCD의 **App of Apps** 패턴을 활용하여 클러스터 운영에 필수적인 핵심 인프라 솔루션(Prometheus, Grafana, Loki, Tempo, Jaeger, Ingress NGINX, Istio)을 단일 진입점 매니페스트(`infrastructure-app-of-apps.yaml`)로 일괄 배포 및 동기화하는 가이드입니다.

---

## 1. 포함된 인프라 컴포넌트 목록 (`component/`)

| 컴포넌트 매니페스트 | 주요 역할 |
| :--- | :--- |
| `prometheus.yaml` | 메트릭 수집 및 모니터링 코어 |
| `grafana.yaml` | 통합 시각화 대시보드 |
| `loki.yaml` | 경량 로그 수집 백엔드 |
| `tempo.yaml` | 분산 추적(Distributed Tracing) 백엔드 |
| `helm-jaeger.yaml` | Jaeger 트레이싱 올인원 및 OTel 연동 |
| `nginx-ingress.yaml` | 외부 L7 트래픽 인그레스 컨트롤러 |
| `istio-base.yaml`, `istiod.yaml`, `istio-ingress.yaml` | Istio 서비스 메시 컨트롤 플레인 및 게이트웨이 |

---

## 2. 배포 방식 및 특징

* **실행 명령어**:
  ```bash
  kubectl apply -f infrastructure-app-of-apps.yaml
  ```
* **Helm 릴리즈와의 차이점**:
  * 이 방식은 Helm CLI를 직접 실행하는 것이 아니라, 렌더링된 매니페스트를 ArgoCD Application 리소스로 등록하여 배포하는 방식입니다.
  * 따라서 클러스터 내에서 `helm list`에는 잡히지 않지만, ArgoCD 웹 콘솔에서 모든 인프라 리소스의 상태와 관계망을 시각적으로 한눈에 관리할 수 있습니다.

---

## 3. 실무 운영 개발일지 & 느낀 점

* **리소스 요구량 주의**:
  * Prometheus, Grafana, Loki, Tempo, Istio를 한 번에 올리면 메모리와 CPU를 상당량 소모하므로, 로컬 미니쿠베/개발용 PC 환경에서는 리소스가 부족해 파드가 다 안 뜰 수 있습니다. 최소 4 Core / 16GB RAM 이상의 노드 스펙을 권장합니다.
* **ArgoCD 관리의 장점**:
  * 여러 인프라 도구를 한눈에 볼 수 있어 토폴로지 파악이 매우 쉽고, 각 파드의 로그를 브라우저 클릭만으로 바로 확인할 수 있어 트러블슈팅 편의성이 대폭 향상됩니다.
  * values를 인라인 파라미터가 아닌 Git 매니페스트 파일로 오버라이드 관리하니 버전 추적이 훨씬 수월합니다.
* **Istio 배포 방식에 대한 고찰**:
  * Istio를 Helm Chart App of Apps로 배포해 보았으나, 공식 Helm 옵션 가이드가 다소 복잡하여 세부 옵션을 미세 조정하기에는 Helm보다 **`istioctl`** CLI 설치 방식이 실무에서는 훨씬 직관적이고 안정적이었습니다.
