#빠른 설치

```bash
helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo update
**helm install gitea -n gitea --create-namespace gitea-charts/gitea --set service.http.type=NodePort**
```

#custom 설치

```bash
helm fetch gitea-charts/gitea --untar
cd gitea
```

vi custom.yaml

```bash
gitea:
  admin:
    existingSecret:
    username: admin
    password: qwer1234
    email: "gitea@local.domain"

ingress:
  enabled: false
  className:
  hosts:
    - host: git.srrain.kro.kr
      paths:
        - path: /
          pathType: Prefix

service:
  http:
    type: NodePort
    port: 3000
```

```bash
helm install gitea -n gitea --create-namespace -f custom.yaml .
```