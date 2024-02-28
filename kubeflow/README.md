# kubeflow

# 설치

노드의 최소 사양은 8코어 8기가가 필요함

- 기본 KubeFlow 설치 방법
    
    kubeflow github
    
    https://github.com/kubeflow/manifests.git
    
    kubeflow git을 클론해온다.
    
    `git clone https://github.com/kubeflow/manifests.git`
    
    kustomize 최신 버전을 설치한다.
    
    ```bash
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
    cd manifests
    ```
    
    istio를 네트워크 로드밸런서 타입으로 띄우기 위해 아래 파일을 수정한다.
    
    `vim /root/manifests/common/istio-1-17/istio-install/base/patches`
    
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: istio-ingressgateway
      namespace: istio-system
      annotations:
        service.beta.kubernetes.io/ncloud-load-balancer-layer-type: nlb
    spec:
      type: LoadBalancer
    ```
    
    아래 명령어로 클론받은 폴더에서 kustomize로 변경된( 혹은 존재하지 않은) 리소스에 대해서 
    
    재생성한다.
    
    ```bash
    
    while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
    ```
    
- deployKF로 설치 방법
    
    공식 사이트: https://www.deploykf.org/guides/getting-started/
    
    ```bash
    # clone the deploykf
    git clone -b main https://github.com/deployKF/deployKF.git ./deploykf
    
    # 현재 폴더 변경
    cd ./deploykf/argocd-plugin
    
    # argocd 설치 (deploykf plugin 패치된 버전으로 설치)
    # WARNING: this will install into your current kubectl context
    ./install_argocd.sh
    
    ./deploykf/argocd-plugin/example-app-of-apps/app-of-apps.yaml 파일 수정
    deploykf_istio_gateway:
      gateway:
        hostname: deploykf.srrain.kro.kr #도메인 설정 방법
      ports:
        http: 80
        https: 443
    
    #deployKF를 argocd에 배포
    ./apply_apps_of_apps.sh
    ```
    
    ![Untitled](kubeflow_img/Untitled%202.png)
    
    - 스크립트로 deployKF 배포하는 방법
        
        ```bash
        #스크립트 폴더로 이동
        cd ./deploykf/scripts
        
        #argocd 비밀번호 획득
        kubectl -n argocd get secret "argocd-initial-admin-secret" -o jsonpath="{.data.password}"  base64 -d
        
        #스크립트 파일 변경
        vim sync_argocd_apps.sh
        
        #내 도메인 입력
        ARGOCD_SERVER_URL="argocd.srrain.kro.kr"
        #위에서 획득한 비밀번호 입력
        ARGOCD_PASSWORD=""
        
        #스크립트 실행
        ./sync_argocd_apps.sh
        ```
        
        ![Untitled](kubeflow_img/Untitled%202.png)
        
    
    argocd에서 sync버튼 클릭합니다.
    
    ![Untitled](kubeflow_img/Untitled%202.png)
    
    namespace와 app 배포됩니다.
    
    ![Untitled](kubeflow_img/Untitled%202.png)
    
    개별 app을 순서대로 배포합니다.
    
    ```bash
    1, you must sync the app-of-apps application:
    
    **deploykf-app-of-apps**
    **deploykf-namespaces** (will only appear if using a remote destination)
    ```
    
    왼쪽 사이드 바에서 요구하는 labels를 검색하여 sync apps을 클릭하여 배포합니다.
    
    ![Untitled](kubeflow_img/Untitled%202.png)
    
    ```bash
    2, you must sync the applications with the label **app.kubernetes.io/component=deploykf-dependencies**:
    
    **dkf-dep--cert-manager** (may fail on first attempt)
    **dkf-dep--istio
    dkf-dep--kyverno**
    ```
    
    ```bash
    3, you must sync the applications with the label **app.kubernetes.io/component=deploykf-core**:
    
    **dkf-core--deploykf-istio-gateway
    dkf-core--deploykf-auth
    dkf-core--deploykf-dashboard
    dkf-core--deploykf-profiles-generator** (may fail on first attempt)
    ```
    
    ```bash
    4, you must sync the applications with the label **app.kubernetes.io/component=deploykf-opt**:
    
    **dkf-opt--deploykf-minio
    dkf-opt--deploykf-mysql**
    ```
    
    ```bash
    5, you must sync the applications with the label **app.kubernetes.io/component=deploykf-tools**:
    
    (none yet)
    ```
    
    ```bash
    6, you must sync the applications with the label app.kubernetes.io/component=kubeflow-dependencies:
    
    **kf-dep--argo-workflows**
    ```
    
    ```bash
    7, you must sync the applications with the label **app.kubernetes.io/component=kubeflow-tools**:
    
    **kf-tools--katib
    kf-tools--notebooks--jupyter-web-app
    kf-tools--notebooks--notebook-controller
    kf-tools--pipelines
    kf-tools--poddefaults-webhook
    kf-tools--tensorboards--tensorboard-controller
    kf-tools--tensorboards--tensorboards-web-app
    kf-tools--training-operator
    kf-tools--volumes--volumes-web-app**
    ```
    
    리소스 사용량
    
    ![Untitled](kubeflow_img/Untitled%202.png)
    

DNS → istio-ingressgateway → ingress  → gateway → virtualservice → service → pod 순으로 접근

기본 설정으로 접근 도메인이 “*” 로 어떤 도메인이든 서비스에 접근할 수 있게 배포되기 때문에 

ingress만 배포하면 외부에서 바로 접근해 볼 수 있다.

![Untitled](kubeflow_img/Untitled%202.png)

소유하고 있는 DNS에 로드 밸런서의 도메인을 추가한다.

![Untitled](kubeflow_img/Untitled%202.png)

DNS에 추가한 주소를 ingress.host에 기재한다.

![Untitled](kubeflow_img/Untitled%202.png)

잠시 뒤에 해당 주소로 접근할 수 있다.

![Untitled](kubeflow_img/Untitled%202.png)

기본 Email은 user@example.com 

Password는 12341234 으로 설정되어 있다.

이렇게 접근하게 되면 Secure Cookie 관련한 ****CSRF 보안에 걸려서 정상 작동이 되지 않는다.

![Untitled](kubeflow_img/Untitled%202.png)

Secure Cookie 기능을 해제하여 사용할 수 있지만 보안에 취약해지기 때문에 

SSL 인증서를 추가하는 방식이 권장된다.

1. SSL 인증서 추가(권장)

kubeflow 설치 시 self signing 이슈를 같이 배포하기에

![Untitled](kubeflow_img/Untitled%202.png)

수동으로 Certificate를 생성시켜서 self signing된 인증서 Secret을 발급 받아 적용하면 된다.

- 셀프 사인 인증서 생성

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kubeflow-ingressgateway-certs
  namespace: istio-system
spec:
  commonName: DOMAIN_NAME #  Ex) kubeflow.srrain.kro.kr
  issuerRef:
    kind: ClusterIssuer
    name: kubeflow-self-signing-issuer # ClusterIssuer 이름 입력
  secretName: kubeflow-ingressgateway-certs
```

셀프 사인이 아닌 let’s encrypt 를 발급자로 받으면 공인 인증서를 발급 받을 수 있다.

1. 공인 인증

Clusterissuer와 인증 요청 생성

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: jhjang@srrain.kro.kr
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: istio
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kubeflow-ingressgateway-certs
  namespace: istio-system
spec:
  secretName: kubeflow-ingressgateway-certs
  commonName: kubeflow.srrain.kro.kr
  dnsNames:
  - kubeflow.srrain.kro.kr
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
    #group: cert-manager.io
  #usages:
  #- digital signature
  #- key encipherment
```

istio로 트래픽 요청시 무조건 “/dex/“ URI로 리다이텍트 되어 http challenge를 수행할 수 없음

리다이렉트 필터를 임시로 제거 후 재적용하는 방법으로 인증

```yaml
#필터 로컬에 저장하기
k get envoyfilters.networking.istio.io authn-filter -n istio-system -o yaml > authn-filter.yaml

#필터 삭제하기
k delete -f authn-filter.yaml

#필터 재적용하기
k apply -f authn-filter.yaml
```

- 공통사항 (발급 받은 인증서로 https 적용)

kubectl edit gateway kubeflow-gateway -n kubeflow

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kubeflow-gateway
  namespace: kubeflow
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "*"
    port:
      name: http
      number: 80
      protocol: HTTP
    # 여기 아래부분 추가 
    tls:
      httpsRedirect: true
  - hosts:
    - "*"
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: kubeflow-ingressgateway-certs
```

1. Secure Cookie 해제 방법

`vim manifest/apps/jupyter/jupyter-web-app/upstream/base/deployment.yaml`

```yaml
# env에 cookies 해제 환경변수 수정
env:
- name: APP_SECURE_COOKIES
  value: "false"
```

`kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -`

rbac 디나이시 에러 발생 시 권한 추가 방법

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: allow-all
 namespace: kubeflow-user-example-com # 유저가 사용하는 네임스페이스
spec:
 rules:
 - {} # 무조건 트래픽 허용
```

kubeflow notebook 드롭다운 메뉴 추가하기

![Untitled](kubeflow_img/Untitled%202.png)

```yaml
#아래 yaml에 이미지 url 추가하고
apps/jupyter/jupyter-web-app/upstream/base/configs/spawner_ui_config.yaml 

# 다시 yaml 배포
kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -
```

---

# Kubeflow의 Kserve 배포 방식

def 함수 별로 기능 구현 후, Annotations을 메인 def 함수를 통해 Run 실행 시 이름을 지정하여 실행

```jsx
@dsl.pipeline(name='digits-recognizer-pipeline',description='Detect digits')
```

![Untitled](kubeflow_img/Untitled%202.png)

![Untitled](kubeflow_img/Untitled%202.png)

메인에서 output_test를 호출하여 def 함수들을 하나씩 kubeflow에서 실행한다.

```python
#kubeflow host에 세션 로그인 정보로 접근
client = kfp.Client(
        host=f"{HOST}/pipeline",
        cookies=f"authservice_session={session_cookie}",
        namespace=NAMESPACE,
    )
#파이프라인 설정 값 입력
    arguments = {
        "no_epochs" : 1,
        "optimizer": "adam"
    }
# kubeflow 직접 run을 실행할 것인지, 파이프라인을 업로드할 것인지 정하는 변수
    run_directly = 1

# 1이면 kubeflow에 직접 run을 실행 
    if (run_directly == 1):
        client.create_run_from_pipeline_func(output_test,arguments=arguments,experiment_name="test")

# 1이 아니면 파이프라인 yaml으로 변환 출력하여 kubeflow에 등록
    else:
        kfp.compiler.Compiler().compile(pipeline_func=output_test,package_path='output_test.yaml')
        client.upload_pipeline(pipeline_package_path='output_test.yaml',pipeline_name="pipeline-test")
```

1.바로 Run이 실행된 화면

![Untitled](kubeflow_img/Untitled%202.png)

2.pipeline에 등록된 모습

![Untitled](kubeflow_img/Untitled%202.png)

---

# 접근 방법

![Untitled](kubeflow_img/Untitled%202.png)

URL external과 URL internal주소로 접근할 수 있다

모델의 주소는 /v1/models/digits-recognizer:predict가 추가로 붙는데 

InferenceService에 Storage_url이 자동으로 붙는 것처럼 보이는데 

테스트에는 붙어서 나오진 않았던 관계로 url에 수기로 추가하였다.

```yaml
#위 스크린샷의 엔드포인트 객체 이름, 자기가 사용하는 네임스페이스 명
isvc_resp = KServe.get("digits-recognizer", namespace="kubeflow-user-example-com")

#객체에서 위 스크린샷의 내부 url을 얻어오기
isvc_url = isvc_resp['status']['address']['url']

#실제 모델의 api 주소를 수기로 추가
isvc_url = isvc_url+'/v1/models/digits-recognizer:predict'
```

그러면 이 객체의 접근 url은 내부 url과 외부 url을 사용할 수 있다.

```yaml
#내부 접근 주소로 별다른 세션쿠키, 인증정보가 없어도 접근할 수 있다
http://digits-recognizer.kubeflow-user-example-com.svc.cluster.local/v1/models/digits-recognizer:predict
```

![Untitled](kubeflow_img/Untitled%202.png)

외부에서 접근할 때에는 Kubeflow가 사용하고 있는 인증 시스템 dex에 로그인 세션 정보가 필요하다.

```yaml
#외부 접근 주소
http://digits-recognizer.kubeflow-user-example-com.srrain.kro.kr/v1/models/digits-recognizer:predict

#---세션 쿠키 얻는 코드 --- #
HOST = "https://kubeflow.srrain.kro.kr"  # Central Dashboard 접근 주소 (포트 포함)
USERNAME = "user@example.com"
PASSWORD = "12341234"

session = requests.Session()
response = session.get(HOST, verify=False)

headers = {
    "Content-Type": "application/x-www-form-urlencoded",
}

data = {"login": USERNAME, "password": PASSWORD}
session.post(response.url, headers=headers, data=data)
session_cookie = session.cookies.get_dict()

#---아래부터 모델에 접근하는 코드 --- #
KServe = KServeClient()

#inferenceservices 객체의 정보를 가져오기
isvc_resp = KServe.get("digits-recognizer", namespace="kubeflow-user-example-com")

#외부 url
isvc_url = isvc_resp['status']['components']['predictor']['url']

#모델의 full url이 나오지 않는 관계로 수기로 추가
isvc_url = isvc_url+'/v1/models/digits-recognizer:predict'

#머신러닝 코드??
t = np.array(x_number_five)
t = t.reshape(-1,28,28,1)

inference_input = {
  'instances': t.tolist()
}

#외부에서 접근하려면 쿠키로 로그인 정보가 추가로 필요
response = requests.post(isvc_url, **cookies=session_cookie**, json=inference_input)
print(response.text)
r = json.loads(response.text)
print("Predicted: {}".format(np.argmax(r["predictions"])))
```

![Untitled](kubeflow_img/Untitled%202.png)

쿠키를 빼고 통신을 요청하면 404 Not Found를 반환한다.

```yaml
isvc_resp = KServe.get("digits-recognizer", namespace="kubeflow-user-example-com")
```

![Untitled](kubeflow_img/Untitled%202.png)

*.domain.com의 DNS 관리와 인증서를 사용해야 정상적인 서비스가 가능한 것으로 보인다.

---

# AutoML

첫 화면에서 AutoML이 뭘 하는지 정의한다

![Untitled](kubeflow_img/Untitled%202.png)

마지막 8번 Trial Template에서 어떤 이미지를 가져올 것이고 파이썬 실행파일의 args에 반복문을 실행하듯 변수로 정의하여 

지정된 횟수만큼, 목표치만큼 반복하여 python을 실행하여 결과 값을 볼 수 있다.

![Untitled](kubeflow_img/Untitled%202.png)

아래는 예시 코드이며 AutoML을 생성할 때 istio의 side car를 제외하여야 정상적으로 실행된다.

```yaml
apiVersion: batch/v1
kind: Job
spec:
  template:
#--- 이 부분 필수로 들어가야 정상 작동함 
    metadata:
      annotations:
        sidecar.istio.io/inject: 'false'
#---
    spec:
      containers:
				- name: training-container
          image: docker.io/kubeflowkatib/mxnet-mnist:v0.16.0-rc.1
          command:
            - "python3"
            - "/opt/mxnet-mnist/mnist.py"
            - "--batch-size=64"
            - "--lr=${trialParameters.learningRate}"
            - "--num-layers=${trialParameters.numberLayers}"
            - "--optimizer=${trialParameters.optimizer}"
# 위 커맨드를 템플릿 아래에 나오는 UI에서 정의할 수 있다
      restartPolicy: Never
```

여기에 적어야 할 것은 6번에 있는 하이퍼 파라미터의 변수 이름을 적으면 된다.

![Untitled](kubeflow_img/Untitled%202.png)

![Untitled](kubeflow_img/Untitled%202.png)

![Untitled](kubeflow_img/Untitled%202.png)

결과

![Untitled](kubeflow_img/Untitled%202.png)

---

# 플러그인 관리

_example: |  안에 적는 것이 아님 밖에 빼서 설정할 옵션을 적는 것

모델 배포 도메인 관리

kubectl edit cm config-domain -n knative-serving

```yaml

#InferenceService에서 생성할 때 붙는 도메인 정의하기
  srrain.kro.kr: ""
```

생성될 도메인 규칙 관리

kubectl edit cm config-network -n knative-serving

```yaml
  #InferenceService 에서 생성될때 도메인 규칙
  domain-template: "{{.Name}}.{{.Namespace}}.{{.Domain}}"
  # Cert-Manager로 인증서를 자동으로 추가하는 옵션
  auto-tls: "Enabled"
```

모니터링 연계 옵션 관리

kubectl edit cm config-observability -n knative-serving

```yaml

#모델들 트레이싱 span 보낼 주소 정의
  zipkin-endpoint: "http://zipkin.istio-system.svc.cluster.local:9411/api/v2/spans"

# span을 보낼 양을 정의 0.1%만 추적
  sample-rate: "0.1"
```

배포될 때 virtualservice 옵션 관리 ??

kubectl edit cm -n kubeflow inferenceservice-config

![Untitled](kubeflow_img/Untitled%202.png)

---

# kubeflow 삭제

```bash
for labels in app.kubernetes.io/part-of=kubeflow kustomize.component; do
  kubectl api-resources --verbs=list -o name  | grep -v '^componentstatuses$' \
    | xargs -n 1 kubectl delete --all-namespaces --ignore-not-found -l app.kubernetes.io/part-of=kubeflow
done

kubectl delete clusterroles        katib-controller katib-ui ml-pipeline-persistenceagent ml-pipeline-viewer-controller-role pipeline-runner
kubectl delete clusterrolebindings katib-controller katib-ui ml-pipeline-persistenceagent ml-pipeline-scheduledworkflow ml-pipeline-viewer-crd-role-binding pipeline-runner
kubectl delete admission-webhook-mutating-webhook-configuration experiment-mutating-webhook-config istio-sidecar-injector mutating-webhook-configuration

kubectl get mutatingwebhookconfiguration -o name | egrep 'kubeflow|katib'|xargs kubectl delete

kubectl get crd -o name| egrep 'kubeflow|dex|istio|certmanager|cert-manager|applications.app.k8s.io'|xargs kubectl delete
kubectl get clusterrole -o name| egrep 'kubeflow|dex|istio'|xargs kubectl delete
kubectl get clusterrolebinding -o name| egrep 'kubeflow|dex|istio'|xargs kubectl delete
```

이걸로 다 안 지워짐..

```yaml
kustomize build example | kubectl delete -f -
```

```bash
kubectl patch crd/inferenceservices.serving.kserve.io -p '{"metadata":{"finalizers":[]}}' --type=merge
```

---

# tip

### istio host 설정 방법

gateway에서 관리하기

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kubeflow-gateway
  namespace: kubeflow
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "*.example.com"
    port:
      name: http
      number: 80
      protocol: HTTP

```

VirtualService에서 2차 도메인을 기입해 나가는 식으로 관리

```yaml
kind: VirtualService
metadata:
  name: centraldashboard
  namespace: kubeflow
spec:
  gateways:
  - kubeflow-gateway
  hosts:
  - 'centraldashboard.example.com'
  http:
  - match:
    - uri:
        prefix: /
    rewrite:
      uri: /
    route:
    - destination:
        host: centraldashboard.kubeflow.svc.cluster.local
        port:
          number: 80
```

### Self sign 인증서일 때 생겼던 문제

 dex 인증이 되지 않아 URL에 접근하지 못하는 경우로 세션 값에 로그인 정보를 넣어 접근하였더니

인증서가 유효하지 않은 인증서로 kubeflow에 접근이 되지 않았다.

Cert manager를 통해 인증서를 추가 후 api를 동작 시킬 수 있었다.