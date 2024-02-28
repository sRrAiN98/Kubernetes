# OpenTelemetry + Tempo + loki = grafana

### 요약

~~메트릭~~, 로그, 트레이싱 수집 → OpenTelemetry Collector →

로그 보관 → loki

트레이싱 보관 → tempo

서비스 맵 → tempo → promethues

시각화 → grafana

---

### 설치

필요한 패키지 (+ promethues)

![Untitled](Untitled%202.png)

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

# 커스텀 리소스 정의가 필요함
```

```yaml
promtail

config:
  logLevel: info
  serverPort: 3101
  clients: 
    - url: http://loki-distributed-gateway.grafana.svc/loki/api/v1/push

#설치한 loki 버전의 push 경로를 찾아서 기입해야함

#opentelemetry collector를 사용할때의 경로

  clients: 
    - url: http://my-collector-collector.otel.svc:3500/loki/api/v1/push

```

```yaml
grafana

adminUser: admin
adminPassword: strongpassword
```

```yaml
loki

#매니지드 쿠버네티스마다 coredns 이름이 달라서 찾아서 변경해야함 
# kubectl get svc --namespace=kube-system -l k8s-app=kube-dns  -o jsonpath='{.items..metadata.name}' && echo
global:
  dnsService: coredns
```

```yaml
kube-prometheus-stack
grafana:
  persistence:
    enabled: true
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations: {}
      # kubernetes.io/ingress.class: nginx
    labels: {}
    hosts: 
      - grafana.srrain.kro.kr
    path: /

    tls: []
    # - secretName: grafana-general-tls
    #   hosts:
    #   - grafana.example.com

  #datasource에 pvc가 안 붙어 있어서 휘발되기에 미리 정의
  additionalDataSources: 
  - name: Tempo
    type: tempo
    typeName: Tempo
    access: proxy
    url: http://tempo.grafana.svc:3100
    password: ''
    user: ''
    database: ''
    basicAuth: false
    isDefault: false
    jsonData:
    nodeGraph:
      enabled: true
    tracesToLogs:
      datasourceUid: loki
      filterBySpanID: false
      filterByTraceID: true
      mapTagNamesEnabled: false
      tags:
          - compose_service
    readOnly: false
    editable: true
  - name: loki
    type: loki
    uid: 
    url: http://loki-distributed-gateway.grafana.svc
    access: proxy
    basicAuth: false
    jsonData:
      serviceMap:
        datasourceUid: 'prometheus'

prometheus:
  prometheusSpec:
    #Tempo에서 Service Graph 그리기 위해 외부 접근 활성화
    enableRemoteWriteReceiver: true
    # dashboard가 휘발성이라 pvc mount
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
```

로컬에 프로메테우스 설치 시 아래 value 추가

```jsx
grafana:
  service:
    type: NodePort

prometheus-node-exporter:
  hostRootFsMount: 
    enabled: false
```

- Collector Value
    
    Metrics는 Pod를 프로메테우스에 긁어가도록 정의하는 것 같아서
    
    그냥 전부 다 긁도록 Collector에서 정의하지 않고 프로메테우스가 직접 수집하도록 사용X
    
    ```jsx
    apiVersion: opentelemetry.io/v1alpha1
    kind: OpenTelemetryCollector
    metadata:
      name: my-collector
    spec:
      mode: daemonset
      #mode: sidecar
      hostNetwork: true 
      config: |
        receivers:
          otlp:
            protocols:
              grpc: # on port 4317
              http: # on port 4318
                cors:
                  allowed_origins:
                    - "*"
                  allowed_headers:
                    - "*"
    
          prometheus:
            config:
              scrape_configs:
              - job_name: 'otel-collector'
                scrape_interval: 10s
                static_configs:
                - targets: [ '0.0.0.0:8888' ]
                metric_relabel_configs:
                - action: labeldrop
                  regex: (id|name)
                  replacement: $$1
                - action: labelmap
                  regex: label_(.+)
                  replacement: $$1
    
        processors:
          batch: 
            send_batch_size: 10000 # Size of the batches to send
            timeout: 10s # Timeout for the batch processor
    
          memory_limiter:
            check_interval: 5s
            limit_percentage: 50
            spike_limit_percentage: 15
    
          resource:
            attributes:
            - action: insert
              from_attribute: k8s.pod.uid
              key: service.instance.id
    
        exporters:
          logging:
            # verbosity: normal
            verbosity: detailed
          # traces
          otlp/tempo:
            endpoint: http://tempo.grafana.svc:4317
            tls:
              insecure: true
              #insecure_skip_verify: true
          # logs
          loki:
            endpoint: http://loki-distributed-gateway.grafana.svc:80/loki/api/v1/push
            tls:
              insecure: true
          # metrics
          prometheusremotewrite:
            endpoint: http://kube-prometheus-stack-prometheus.prometheus.svc:9090/api/v1/write
            target_info:
              enabled: true
    
        extensions:
          health_check:
          pprof:
          zpages:
    
        service:
          extensions: [health_check, pprof, zpages]
          pipelines:
            traces:
              receivers: [otlp]
              processors: [batch]
              exporters: [otlp/tempo]
            logs:
              receivers: [otlp]
              processors: [resource]
              exporters: [logging, loki]
            metrics:
              receivers: [prometheus]
              processors: []
              exporters: [logging, prometheusremotewrite]
    ```
    

---

opentelemetry-auto-instrumentation-python라는 init Container가 Fluent 처럼 각 Pod들의 Stdout을 수집하여 (kubectl logs) 

Loki에게 전달(Loki가 log 보관)

네트워크 트래픽 별 트레이싱 정보를

Tempo에게 전달(= Jaeger)

Grafana가 Tempo와 Loki에게 정보를 검색

![Untitled](Untitled%202.png)

Tempo Connection에 Tempo Url 추가 후

Trace to logs에 Loki를 선택하고 Save

![Untitled](Untitled%202.png)

서비스 그래프 활성화 방법

tempo 설치 value에서 metricsGenerator를 활성화

```yaml
tempo:
  metricsGenerator:
    enabled: true
    remoteWriteUrl: "http://kube-prometheus-stack-prometheus.prometheus:9090/api/v1/write"
```

이때 tempo가 생성하는 Metrics 목록

![Untitled](Untitled%202.png)

kube-prometheus-stack에서 enableRemoteWriteReceiver를 활성화

```yaml

prometheus:
  prometheusSpec:
    #Tempo에서 Service Graph 그리기 위해 외부 접근 활성화
    enableRemoteWriteReceiver: true
```

tempo의 connection 설정에서 **Additional settings**을 펼쳐 ****Service graph와 Node graph 활성화

![Untitled](Untitled%202.png)

Span 정보와 Log 검색 

![Untitled](Untitled%202.png)

![Untitled](Untitled%202.png)

서비스 그래프

![Untitled](Untitled%202.png)

---

### ++추가

opentelemetry-instrument 명령어로 자동계측할 때는 Dockerfile에서 uvicorn으로 실행하지 말고

python 으로 실행하고 python이 안에서 uvicorn을 동작시켜야 수집이 됨

- 이렇게 하지 말고

```bash

opentelemetry-instrument \
   --metrics_exporter none \
   --logs_exporter  console,otlp \
   --traces_exporter console,otlp \
   --exporter_otlp_protocol http/protobuf \
   --exporter_otlp_endpoint http://otel-collector.otel.svc:4318 \
uvicorn main:app --root-path /file2text --host=0.0.0.0 --port 8000
```

- 이런 식으로 python으로 실행하기

```bash
opentelemetry-instrument \
   --metrics_exporter none \
   --logs_exporter  otlp \
   --traces_exporter otlp \
   --exporter_otlp_protocol http/protobuf \
   --exporter_otlp_endpoint http://otel-collector.otel.svc:4318 \
  python main.py
```

main.py