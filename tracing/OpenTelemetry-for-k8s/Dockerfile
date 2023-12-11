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