#!/bin/bash
cd /usr/src/app

#이걸로 실행해야 추적이 됨 마치 java의 -agnet 느낌을 바이너리로 실행한 느낌
opentelemetry-instrument \
    --exporter_jaeger_grpc_insecure true \
    uvicorn main:app --host=0.0.0.0 --port 8000
    
#마지막 줄은 쓰고싶은 명령어 그대로 쓰면