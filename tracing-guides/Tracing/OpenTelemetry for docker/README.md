# OpenTelemetry for docker

https://opentelemetry.io/docs/instrumentation/python/automatic/

Dockerfile

```yaml
FROM python:3.11.6-slim
WORKDIR /usr/src/app

## Copy all src files
COPY . .

# 기본적인 패키지 설치
RUN pip install --upgrade pip \
        &&pip install -r requirements.txt

# opentelemetry 추적 관련 설치
RUN pip install opentelemetry-distro opentelemetry-exporter-otlp opentelemetry-exporter-jaeger \
        && opentelemetry-bootstrap -a install

# opentelemetry 호환 에러 해결
RUN pip install protobuf==3.20.*

## Run the application on the port 8080
EXPOSE 8000

#ENTRYPOINT ["/usr/src/app/entrypoint.sh"]

CMD ["sh", "entrypoint.sh"]
```

entrypoint.sh

```yaml
#!/bin/bash
cd /usr/src/app

#이걸로 실행해야 추적이 됨 마치 java의 -agnet 느낌을 바이너리로 실행한 느낌
opentelemetry-instrument \
    --exporter_jaeger_grpc_insecure true \
    #이런 식으로 옵션을 추가하면 되는데 이 부분을 환경변수로 할 수 있어서 pod env로 설정
    python main.py 
```

중요한 부분이 파이썬 실행 방식인데

uvicorn main:app --root-path /file2text --host=0.0.0.0 --port 8000 << 이렇게 직접 실행하면 수집이 안되고

python main.py으로 실행해야지만 내부에서 uvicorn이 실행되어야 프로세스가 꼬이지 않고 정상적으로 opentelemetry가 수집할 수 있음

![Untitled](Untitled%202.png)

![Untitled](Untitled%202.png)

![Untitled](Untitled%202.png)

main.py

```yaml
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def read_root():
    return {"Hello": "World"}

if __name__ == "__main__":
    import uvicorn
 
    # FastAPI 애플리케이션 실행
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

requirements.txt

```yaml
fastapi==0.68.0
uvicorn==0.15.0

#아래 항목들이 dockerfile의 opentelemetry 추적 관련 설치 섹션에서 설치됨.
#opentelemetry-instrumentation==0.42b0
#opentelemetry-distro==0.42b0
#opentelemetry-exporter-otlp-proto-grpc==1.21.0
#opentelemetry-instrumentation-fastapi==0.42b0
#opentelemetry-instrumentation-requests==0.42b0
```

deployment에서 env를 추가하면 opentelemetry-instrument 바이너리 실행 시 해당 환경 변수가 args로 인식되어 셋팅 됨

```yaml
#helm chart에 values.yaml 참조하도록 수정한 값
          env:
          {{- range $key, $val := .Values.env }}
            - name: {{ $key }}
              value: {{ $val | quote }}
          {{- end }}
```

```yaml
#사용한 변수
OTEL_SERVICE_NAME: django
  OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED: 'true'
  OTEL_EXPORTER_OTLP_ENDPOINT: 'http://otel-collector.otel.svc:4318'
  OTEL_METRICS_EXPORTER: none
  OTEL_LOGS_EXPORTER: otlp
  OTEL_TRACES_EXPORTER: otlp
  OTEL_TRACES_SAMPLER: parentbased_traceidratio
  OTEL_TRACES_SAMPLER_ARG: '1'
  OTEL_PROPAGATORS: 'tracecontext,baggage'

#-- 실제로 변환된 env
- env:
	  - name: OTEL_RESOURCE_ATTRIBUTES_POD_NAME
	    valueFrom:
	      fieldRef:
	        apiVersion: v1
	        fieldPath: metadata.name
	  - name: OTEL_RESOURCE_ATTRIBUTES_NODE_NAME
	    valueFrom:
	      fieldRef:
	        apiVersion: v1
	        fieldPath: spec.nodeName
	  - name: OTEL_EXPORTER_OTLP_ENDPOINT
	    value: 'http://otel-collector.otel.svc:4318'
	  - name: OTEL_LOGS_EXPORTER
	    value: otlp
	  - name: OTEL_METRICS_EXPORTER
	    value: none
	  - name: OTEL_PROPAGATORS
	    value: 'tracecontext,baggage'
	  - name: OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED
	    value: 'true'
	  - name: OTEL_SERVICE_NAME
	    value: django
	  - name: OTEL_TRACES_EXPORTER
	    value: otlp
	  - name: OTEL_TRACES_SAMPLER
	    value: parentbased_traceidratio
	  - name: OTEL_TRACES_SAMPLER_ARG
	    value: '1'
	  - name: TZ
	    value: Asia/Seoul
```

ps. 도커의 instrumentation를 바이너리로 실행한 방식의 차이인지.

쿠버네티스의 instrumentation 사이드 카 방식 차이인지

아니면 django와 python의 차이인지 OTEL_LOGS_EXPORTER 값이 다름

django를 도커의 instrumentation 바이너리로 실행했을 때는 otlp로 실행해야 오류가 없었고

pod의 fastapi를 사이드카로 실행했을 때는 PROTOCOL이 http/protobuf 여야 오류가 없이 정상 실행됨

- django(docker)
    - protocol: otlp
- fastapi(sidecar)
    - protocol: http/protobuf