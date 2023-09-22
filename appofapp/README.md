# application.yaml -> apps -> chart
```
1.helm chart 여러 개를 생성한 것을 Chart에 넣어두고
2.apps 에서 argocd에서 app create 할 때 나오는 yaml파일을 넣어두고
3.application.yaml가 해당 yaml파일을 create 해주는 것과 동일한 역할을 함  
```

![Alt text](image.png)

- 근데 문제가 있음...
github 이 레포에서 테스트 한 게 아니고 사설 gitlab에서 테스트 했기에
경로가 달라서 application.yaml을 create하면 에러가 나는데
귀찮아서 수정을 안 했음..
test-spring/sample-spring-microservices-kubernetes-helm 에 있는 차트가 
이 차트 다음으로 테스트하여 올린 차트라 저쪽 거는 에러 없음..
  
- 어케어케 잘 하면 app of apps 패턴으로 배포가 되는 것까지 확인했고
- 변수로 한번에 적용하는 건 테스트 예정   
  
  
