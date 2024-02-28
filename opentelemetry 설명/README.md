# 그라파나가 수집하는 것

세가지 종류로 모니터링 수집 분류를 나눌 수 있다.

![Untitled](그라파나가-수집하는것_img/Untitled.png)

![Untitled](그라파나가-수집하는것_img/Untitled%201.png)

---

### 메트릭

![Untitled](그라파나가-수집하는것_img/Untitled%202.png)

- Node exporter
    - CPU, mem, 네트워크 등 기존 호스트 관련 측정항목 수집
- Kube-state-metrics
    - 클러스터 수준 지표: Pod 지표, 리소스 정보 등
- **Kubernetes control plane metrics**
    - kubelet, etcd, dns, 스케줄러 등

![Untitled](그라파나가-수집하는것_img/Untitled%203.png)

![Untitled](그라파나가-수집하는것_img/Untitled%204.png)

---

### 로그

PLG스택

![Untitled](그라파나가-수집하는것_img/Untitled%205.png)

![Untitled](그라파나가-수집하는것_img/Untitled%206.png)

EFK 스택

![Untitled](그라파나가-수집하는것_img/Untitled%207.png)

![Untitled](그라파나가-수집하는것_img/Untitled%208.png)

---

### 트레이싱

![Untitled](그라파나가-수집하는것_img/Untitled%209.png)

![Untitled](그라파나가-수집하는것_img/Untitled%2010.png)

![Untitled](그라파나가-수집하는것_img/Untitled%2011.png)

kiali

![Untitled](그라파나가-수집하는것_img/Untitled%2012.png)

pinpoint