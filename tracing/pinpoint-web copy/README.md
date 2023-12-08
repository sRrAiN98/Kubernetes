# fastapi - opentelemetry - jaeger 자동 메트릭 수집방법
3일 걸림... 

```
docker build -t test:0.1 .
helm install pp ./helm
```

fastapi에서 자동 수집시 메트릭 수집이 부족한 것이 있을 수도 있다.
여러 문서중에 자동 수집시 상세 메트릭 수집이 불가하다고 써있는 것도 있고
똑같이 수집한다는 말도 있었다.

자동 수집 시 fastapi에서 추가해야할 코드는 없고

pip install opentelemetry-distro opentelemetry-exporter-otlp
명령어로 opentelemetry-instrument 바이너리가 설치되고

opentelemetry-exporter-jaeger 설치해야
"--traces_exporter jaeger" args가 정상적으로 동작한다.

근데.. 안 쓰는듯..? jaeger가 아니고 otel 메트릭으로 수집하는 것처럼 보임

opentelemetry-bootstrap -a install 명령어로 opentelemetry 관련 pip가 여러개 설치된다.
설치 목록을 보고싶다면 opentelemetry-bootstrap -a requirement 명령어로 확인할 수 있다.

entrypoint.sh에서
opentelemetry-instrument \
    --exporter_jaeger_grpc_insecure true \ <-처럼 명령어를 추가할 수도 있지만 유연성을 위해 deployment의 env로 설정하였다.
    uvicorn main:app --host=0.0.0.0 --port 8000 

env로 환경 변수를 설정 시 위와 같은 args를 사용한 것과 같은 동작을 함.