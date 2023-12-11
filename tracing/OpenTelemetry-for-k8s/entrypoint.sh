#!/bin/bash
cd /usr/src/app
#opentelemetry-instrument \ --exporter_jaeger_grpc_insecure true \    uvicorn main:app --host=0.0.0.0 --port 8000

uvicorn main:app --host=0.0.0.0 --port 8000
