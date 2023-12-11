# OpenTelemetry + Tempo + loki = grafana

필요한 패키지 (+ promethues)

의존도로 묶음
(cert-manager, opentelemetry-operator)
(loki-distributed, promtail)
tempo, grafana
(자기 로컬 git에 올린) 테스트 app, OpenTelemetryCollector
이렇게 8개 helm을 배포하면 된다
```yaml
argocd repo 등록할 내용

otel https://open-telemetry.github.io/opentelemetry-helm-charts
grafana  https://grafana.github.io/helm-charts
certmanager  https://charts.jetstack.io
prometheus-community  https://prometheus-community.github.io/helm-charts

+ 

#각 개인 레포에 생성
OpenTelemetry CRD 
app deployment helm
```

---

따로 values가 필요한 helm

```yaml
Cert Manager

installCRDs: true
```

```yaml
promtail

config:
  logLevel: info
  serverPort: 3101
  clients:
    - url: http://loki-distributed-gateway.grafana.svc/loki/api/v1/push
```

```yaml
grafana

adminUser: admin
adminPassword: strongpassword
```

---

Promtail이 Fluent 처럼 각 Pod들의 Stdout을 수집하여 (kubectl logs) 

Loki에게 전달(Loki가 log 보관)

Instrumentation가 Pod에 붙어서 Span 추적(tracing) 

OpenTelemetryCollector에게 전달

OpenTelemetryCollector가 Tempo에게 전달(Jaeger)

Grafana가 Tempo와 Loki에게 정보를 검색

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1963d13b-cc2f-40c8-b422-332972ae6ce6/7c46794e-0c27-4b08-8285-913f6cb566b8/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1963d13b-cc2f-40c8-b422-332972ae6ce6/bfa5a1da-3882-4ece-a650-483ca0c38c49/Untitled.png)

Span 정보와 Log 검색