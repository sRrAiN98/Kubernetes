# Kubernetes

argocd app of apps 패턴으로 Helm Chart 배포하기

단 이방법은 Helm Chart를 배포하는게 아닌
helm template로 추출된 yaml파일을 배포하는 방식이라 helm list에 존재하지 않음

- 개인 컴퓨터에서 했더니 리소스가 부족해서 다 못 뜸…


# 추가 0906
* helm-jarger.yaml를 추가하였다.
  arogcd ui에서 repo, app을 직접 등록한 것을 -o yaml로 빼내어 만든 파일이며
  values를 parameter가 아닌 오버라이드로 관리할 수 있어 훨씬 편의성이 향상되었다.

* helm을 argocd로 관리하니 리소스들을 한 눈에 볼 수 있어 좋은 것 같다.
  log 쉽게 보는 것은 덤으로 좋고..
