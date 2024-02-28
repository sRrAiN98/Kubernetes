```bash
#helm repo 등록
 helm repo add jenkinsci https://charts.jenkins.io/

#helm repo 업데이트
 helm repo update

#helm chart 압축 풀기
 helm fetch jenkinsci/jenkins --untar

#jenkins 공식 홈페이지에서 제공하는 serviceAccount와 pv를 미리 생성시켜두는 yaml파일
wget https://raw.githubusercontent.com/jenkins-infra/jenkins.io/master/content/doc/tutorials/kubernetes/installing-jenkins-on-kubernetes/jenkins-sa.yaml
wget https://raw.githubusercontent.com/jenkins-infra/jenkins.io/master/content/doc/tutorials/kubernetes/installing-jenkins-on-kubernetes/jenkins-volume.yaml
```

```bash
#namespace 생성
kubectl create ns jenkins

#volume yaml파일의 sc 이름 정의와 hostpath 마운트 경로 항목 생성 및 정의
jenkins-volume.yaml
  storageClassName: jenkins-pv
  hostPath:
    path: /Users/kb01-wkdwogml159/Documents/data
    type: DirectoryOrCreate

kubectl apply -f jenkins-sa.yaml
kubectl apply -f jenkins-volume.yaml
```

  local환경이므로 hostpath, nodeport사용

위에서 미리 생성시킨 serviceaccount와 pv를 사용하여 설치(pv는 데이터 보존용)

```yaml
vim config.yaml
controller:
  serviceType: NodePort
persistence:
  storageClass: jenkins-pv
  size: "10Gi" # pv volume에 정의된 용량과 같거나 작게
serviceAccount:
  create: false
  name: jenkins
```

```jsx
helm install -n jenkins -f config.yaml jenkins jenkinsci/jenkins
```

```jsx
export NODE_PORT=$(kubectl get --namespace jenkins -o jsonpath="{.spec.ports[0].nodePort}" services jenkins)
export NODE_IP=$(kubectl get nodes --namespace jenkins -o jsonpath="{.items[0].status.addresses[0].address}")
echo http://$NODE_IP:$NODE_PORT/login

kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
```