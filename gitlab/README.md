# GitLab 자체 구축 및 프로젝트 연동 가이드 (Helm)

Kubernetes 클러스터 상에 **GitLab CE(Community Edition)**를 Helm으로 배포하고, 초기 관리자 계정 설정 및 프로젝트 로컬 Git 연동(HTTP/SSH)을 진행하는 가이드입니다.

---

## 1. Helm으로 GitLab CE 배포

### 1) Helm Repository 등록 및 차트 다운로드
```bash
helm repo add gitlab http://charts.gitlab.io/
helm repo update
helm fetch gitlab/gitlab --untar
cd gitlab
```

### 2) `custom-values.yaml` 작성
보유하고 있는 도메인과 관리자 이메일을 설정합니다.

```yaml
global:
  edition: ce
  hosts:
    domain: example.com

certmanager-issuer:
  email: admin@example.com

gitlab-runner:
  install: true
  runners:
    privileged: true
```

### 3) 설치 실행
```bash
helm install -n gitlab gitlab gitlab/gitlab --create-namespace -f custom-values.yaml
```

### 4) 초기 root 비밀번호 확인
배포 후 자동으로 생성된 초기 root 관리자 패스워드를 Secret에서 조회합니다.

```bash
kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d ; echo
```

---

## 2. 프로젝트 생성 및 로컬 Git 연동

GitLab Web UI(`https://gitlab.example.com`)에 `root`로 로그인한 뒤 프로젝트를 생성합니다.

### 1) 로컬 Git 기본 설정
```bash
git config --global user.name "당신의 이름"
git config --global user.email "당신의 email"
git init
```

### 2) 원격 저장소 연결 및 업로드
```bash
git remote add origin https://gitlab.example.com/username/project.git
git add .
git commit -m "feat: initial commit"
git push -u origin main
```

---

## 3. SSH Key를 통한 안전한 접속 설정

매번 비밀번호를 입력하지 않고 SSH 키 쌍을 이용해 인증하는 방식입니다.

### 1) 로컬에서 SSH Key 생성
```bash
ssh-keygen -t rsa -b 2048 -C "admin@example.com"
```

### 2) GitLab에 공개 키 등록
1. GitLab 우측 상단 아바타 클릭 → **Preferences (기본 설정)** 선택
2. 좌측 메뉴에서 **SSH Keys** 선택
3. `~/.ssh/id_rsa.pub` 파일의 내용을 복사하여 **Key** 입력란에 붙여넣고 등록

### 3) SSH 연결 테스트
```bash
ssh -T git@gitlab.example.com
# "Welcome to GitLab, @username!" 메시지가 나오면 성공
```
