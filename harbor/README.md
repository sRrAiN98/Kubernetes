# harbor

# 도커 이미지 개인 레지스트리 저장소

#helm 가져오기

```bash
helm repo add harbor https://helm.goharbor.io
helm fetch harbor/harbor —untar
```

#공인 tls 인증서 발급 받아와서 발급 받은, (개인 키)와 (중간자 인증서 + 내 인증서)로 secret 생성

순서는 아래 순서로 합쳐서 작성한다

1. 중급인증 1
2. 루트 인증서

```bash
k create secret tls harbor-tls --key="private.key" --cert="certificate.crt" -n harbor
```

vim values.yaml

```bash
expose:
  type: loadBalancer
  enabled: ture
  certSource: secret 
  secretName: "harbor-tls"
  notarySecretName: "harbor-tls"

ingress:
  hosts:
    core: core.harbor.srrain.kro.kr
    notary: notary.harbor.srrain.kro.kr

externalURL: https://core.harbor.srrain.kro.kr
```

#공인 인증서 등록 확인에 걸리는 시간 1분 이상 소요될 수 있음

admin

q1w2e3r4!@#$

새로운 프로젝트 생성 후 Push Command를 볼 수 있다.

“spring” 이름으로 프로젝트를 생성 했을 시

```bash
docker tag image:[TAG] 20.41.114.112/spring/image:[TAG]
docker push 20.41.114.112/spring/image:[TAG]
```

ex)

```bash
docker tag nginx:0.1 20.41.114.112/spring/nginx:0.1
docker push 20.41.114.112/spring/nginx:0.1
```

이와 같이 이미지를 넣을 수 있다