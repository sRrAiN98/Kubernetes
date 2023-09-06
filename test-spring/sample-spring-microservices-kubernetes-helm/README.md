# 설명
- application.yaml을
- kubectl apply -f application.yaml 하면
  - templates에 있는 하위 application이 argocd에 배포된다.
  - 하위 app들은 설정에 따라 charts에 있는 helm chart들을 배포한다.

# 설명2
- application.yaml을 values.yaml에 값을 적용시켜서 templates에 있는 app들을 변수로 한번에 repoURL를 묶고 싶었는데
- 잘 안 됐음.. value를 오버라이드 시켜야하나..? 
