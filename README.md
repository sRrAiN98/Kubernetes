## 문서 개선
기존 appofapp 폴더에서는 애플리케이션에 대한 값을 다른 클러스터 변수로 설정할 시 에러가 발생하였습니다.  
때문에 다른 차트를 참조하여 ver 2를 구성하였습니다.

### 구성 방식
- 루트/apps에서 ArgoCD 템플릿 변수를 관리합니다.
- 루트/helm-chart에서 실제로 배포할 차트를 관리합니다.
  
 ### 배포 방식
- /apps/templates에서 ArgoCD applications을 배포합니다.
- /helm-chart에서 실제 차트를 배포합니다.
  
### apps/values.yaml의 변경 사항
- apps: 부분은 원래 range 함수를 사용하여 동일한 네임스페이스,  
  동일한 클러스터에 배포하도록 구성되어 있었습니다.
  
- 하지만, 각 차트마다 네임스페이스를 달리 구성하게 되어서  
  range 템플릿을 제거하고 하나의 파일로 구성하였습니다.
  
- 해당 파일은 templates.yaml에 주석 처리하였습니다.
