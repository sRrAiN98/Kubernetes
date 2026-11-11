# PostgreSQL + pgvector 벡터 데이터베이스 구축 가이드

LLM 임베딩 벡터 저장 및 시맨틱 유사도 검색(RAG)을 위해 **PostgreSQL**에 **`pgvector`** 확장을 설치하고, 파드 재시작 시에도 확장이 유지되도록 커스텀 컨테이너 이미지를 빌드하여 Helm으로 배포하는 실무 가이드입니다.

---

## 1. 아키텍처 및 커스텀 이미지 제작 이유

* **기존 방식의 한계**:
  * 실행 중인 Bitnami PostgreSQL 파드에 `kubectl exec`로 들어가 `pgvector`를 소스 컴파일(`make install`)할 경우, 파드가 재기동되거나 롤링 업데이트될 때 컨테이너 루트 파일시스템이 초기화되면서 설치한 확장이 날아갑니다.
* **해결책**:
  * `bitnami/postgresql`을 베이스로 삼고 빌드 시점에 `pgvector`를 컴파일하여 포함시킨 전용 이미지를 빌드한 뒤, Helm Chart의 `image` 설정으로 배포합니다.

---

## 2. pgvector 포함 Dockerfile 빌드

```dockerfile
FROM bitnami/postgresql:16.1.0-debian-11-r9

USER root

# 컴파일에 필요한 필수 빌드 도구 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gcc \
    make \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# pgvector 소스 코드 클론 및 빌드/설치
RUN cd /tmp \
    && git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make \
    && make install \
    && rm -rf /tmp/pgvector

# 권한 복구
RUN chown -R 1000:1000 /bitnami

USER 1000
```

### 이미지 빌드 및 레지스트리 푸시
```bash
docker build -t cr.example.com/postgres-pgvector:16-v0.5.1 .
docker push cr.example.com/postgres-pgvector:16-v0.5.1
```

---

## 3. Bitnami PostgreSQL Helm 배포

### `values.yaml` 작성
```yaml
image:
  registry: cr.example.com
  repository: postgres-pgvector 
  tag: 16-v0.5.1
  pullSecrets: 
    - imagepullsecret

auth:
  username: admin
  password: "<YOUR_POSTGRES_PASSWORD>"
  database: vectordb

primary:
  persistence:
    enabled: true
    size: 20Gi
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
```

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install postgresql bitnami/postgresql -n postgresql -f values.yaml --create-namespace
```

---

## 4. Ingress NGINX TCP 포트 포워딩 (5432 외부 노출)

PostgreSQL은 HTTP가 아닌 TCP 프로토콜을 사용하므로, Ingress NGINX의 `tcp-services` ConfigMap을 통해 외부로 노출합니다.

```yaml
# ingress-nginx-controller의 tcp 설정
tcp:
  5432: "postgresql/postgresql:5432"
```

---

## 5. DB 접속 및 pgvector 확장 활성화 확인

```bash
# 로컬 또는 클라이언트 파드에서 psql 접속
psql -h postgres.example.com -p 5432 -U admin -d vectordb

# pgvector 확장 기능 활성화
vectordb=> CREATE EXTENSION vector;

# 확장 설치 확인
vectordb=> SELECT * FROM pg_extension WHERE extname = 'vector';

# 벡터 테이블 테스트 생성
vectordb=> CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
vectordb=> INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
vectordb=> SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 1;
```
