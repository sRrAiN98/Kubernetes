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

# 추가 0920
* istio를 helm chart로 손쉽게 배포하긴 좀 무리가 있는 거 같다
* istio에서 공식 가이드한 helm chart로 yaml를 구성했는데 실질적으로 옵션 값을 설정하기엔 가이드가 너무 부족하다
* istioctl이 제일 괜찮다고 생각함.
