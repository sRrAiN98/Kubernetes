## postgesql

helm chart 배포

```yaml
#custom value.yaml

#컨테이너의 보안 설정 해제 - root권한으로 실행
primary:
  containerSecurityContext:
    enabled: true
    runAsUser: 0
    runAsNonRoot: false
    privileged: true
    readOnlyRootFilesystem: false
    allowPrivilegeEscalation: true
readReplicas:
  podSecurityContext:
    enabled: true
    fsGroup: 0
```

```yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-postgresql bitnami/postgresql -f custom.yaml --version 13.2.15 
```

패스워드 확인

```yaml
kubectl get secrets -n postgresql postgresql -o jsonpath='{.data.postgres-password}' | base64 -d && echo

#  b9rSiEuQxM
```

외부로 노출하기 위해 ingress-nginx의 설정 변경

```yaml
tcp:
  5432: "postgresql/postgresql:5432"
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1963d13b-cc2f-40c8-b422-332972ae6ce6/e0a98ae2-6f3f-4c69-996d-a2a02059c431/Untitled.png)

컨테이너 안에서 필요한 시스템 명령어 설치

```bash
#컨테이너 접속
kubectl exec -it -n postgresql postgresql-0 bash

#명령어 설치
apt update
apt install git gcc make -y

## -- pgvector에서 제공하는 설치 명령어 --
cd /tmp
git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git
cd pgvector
make
make install # may need sudo
## -- --

## sql 접속

psql -U postgres -h postgre.srrain.kro.kr
  password 입력: tWfzfpekd1

# 확장기능 활성화
CREATE EXTENSION vector;
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1963d13b-cc2f-40c8-b422-332972ae6ce6/523505f6-3d46-413f-874a-cf18682f0723/Untitled.png)

---

### Dockfile build

pod 재시작시 컨테이너가 초기화되는 문제로 

새로 docker build를 진행하여

플러그인이 설치된 postgresql로 이미지를 변환

Dockerfile

```bash
FROM bitnami/postgresql:16.1.0-debian-11-r9

USER root

# 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    git \
    gcc \
    make

# 확장 기능의 소스 코드 내려받기
RUN cd /tmp \
    && git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git

RUN cd /tmp/pgvector \
    && make \
    && make install

RUN chown -R 1000:1000 /bitnami
```

```bash
docker build -t docker-image.kr.ncr.ntruss.com/postgres-pgvector:1 .
docker push docker-image.kr.ncr.ntruss.com/postgres-pgvector:1
```

helm chart 옵션 변경(위에 유저 변경 제거 후 이미지만 변경)

```bash
image:
  registry: docker-image.kr.ncr.ntruss.com
  repository: postgres-pgvector 
  tag: 1

  pullSecrets: 
    - imagepullsecret
```

imagepullsecret은 명령어로 ncp 이미지 레지스트리 접근 액세스 키를 정의