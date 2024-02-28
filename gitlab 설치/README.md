gitlab에 접속후 프로젝트 생성

로컬 머신에서 설정 등록

```
git config --global user.name "당신의 이름"
git config --global user.email "당신의 email"
git init
```

원격 저장소와 동기화

```
git pull https://생성한 프로젝트 url
git remote add origin https://프로젝트 url
```

git 업로드 명령어

```
git add .
git commit -m "커밋 메시지"
git push origin master
```

Http 연결

gitlab 레포지토리에 접속시 최상단에 뜨는 http로 로그인 메세지를 클릭하여

비밀번호 설정 후

`git pull url:<port>`

아이디와, 비밀번호 입력

ssh 연결

`ssh-keygen -t rsa -b 2048 -C "<comment>"`

1. 상단 표시줄의 오른쪽 상단에서 아바타를 선택합니다.
2. **기본 설정 을** 선택 합니다.
3. 왼쪽 사이드바에서 **SSH 키 를** 선택 **합니다** .
4. 에서 **키**`ssh-ed25519ssh-rsa`
    
    상자, 공개 키의 내용을 붙여 넣습니다. 키를 수동으로 복사한 경우
    
    `ssh-rsa`로 시작하고 주석으로 끝날 수 있는 전체 키를 복사해야 합니다 .
    

연결확인

`ssh -T git@gitlab.example.com`
<details>
<summary>helm install</summary>
<div markdown="1">

# helm install

#helm repo 등록

```jsx
helm repo add gitlab http://charts.gitlab.io/
```

#helm chart 다운로드 

```jsx
helm fetch gitlab/gitlab --untar
```

#helm custom value 파일 만들기

vim custom.yaml (소유하고 있는 1차 도메인 기입)

```bash
global:
  edition: ce
  hosts:
    domain: [srrain.kro.kr](http://gitlab.srrain.kro.kr/)

certmanager-issuer:
  email: jjh@example.com

gitlab-runner:
  runners:
    privileged: true
```

```bash
helm install -n gitlab --create-namespace -f custom.yaml gitlab gitlab/gitlab
 or
helm install -n gitlab --create-namespace -f custom.yaml gitlab .
```

#기본 root 비밀번호 확인
```jsx
kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d ; echo
```
</div>
</details>
