# jupyterhub
설치

```jsx
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm install my-jupyterhub jupyterhub/jupyterhub --version 3.2.2-0.dev.git.6456.hf11f8ea8
```

기본적인 config

```yaml
imagePullSecrets: 
  - imagepullsecret

hub:
  networkPolicy:
    enabled: false
  revisionHistoryLimit: 3
  config:
    #어드민 유저 추가 https://z2jh.jupyter.org/en/stable/administrator/authentication.html#allowed-users-admin-users
    Authenticator:
      admin_users:
        - adminuser1

proxy:
  chp:
    networkPolicy:
      enabled: false
    revisionHistoryLimit: 3
  service:
    type: ClusterIP
singleuser:
  networkPolicy:
    enabled: false
  startTimeout: 3600
  profileList:
    - display_name: "Base environment"
      description: "To avoid too much bells and whistles: Python."
      default: true
    - display_name: "hyper clova X environment"
      description: "사설 라이브러리 pip install 이미지."
      kubespawner_override:
        image: docker-image.kr.ncr.ntruss.com/juypter-image:0.6

  #생성되는 유저마다 관리 설정 21600초 지나면 notebook 꺼지게 300초마다 체크
  extraFiles:
    # jupyter_notebook_config reference: https://jupyter-notebook.readthedocs.io/en/stable/config.html
    jupyter_notebook_config.json:
      mountPath: /etc/jupyter/jupyter_notebook_config.json
      # data is a YAML structure here but will be rendered to JSON file as our
      # file extension is ".json".
      data:
        MappingKernelManager:
          # cull_idle_timeout: timeout (in seconds) after which an idle kernel is
          # considered ready to be culled
          cull_idle_timeout: 21600 # default: 0 (6h)

          # cull_interval: the interval (in seconds) on which to check for idle
          # kernels exceeding the cull timeout value
          cull_interval: 300 # (5m)

          # cull_connected: whether to consider culling kernels which have one
          # or more connections
          cull_connected: fals# default: false

          # cull_busy: whether to consider culling kernels which are currently
          # busy running some code
          cull_busy: false # default: false

# OAuth2 기반 인증 
# https://z2jh.jupyter.org/en/stable/administrator/authentication.html#google

ingress:
  enabled: true
  annotations: 
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/affinity: cookie
    nginx.ingress.kubernetes.io/session-cookie-name: session
    nginx.ingress.kubernetes.io/session-cookie-expires: "172800"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "172800"
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-headers: X-XSRF-TOKEN,Accept,Accept-Encoding,Accept-Language,DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization,Origin,Connection,Content-Length,Content-Type,Host,Referer,User-Agent
    nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
  ingressClassName: nginx
  hosts: 
    - jupyterhub.srrain.kro.kr
  tls: []

# cull. 섹션은 그냥 유저가 삭제됨;;;

debug:
  enabled: false
```

로드밸런서가 아니라 ingress 타고 들어와서 그런지
네트워크 폴리시에 막혀서 내부 pod로 통신이 안되는 이슈로 인해 

  networkPolicy:
    enabled: false 설정

gitlab으로 인증받는 helm values.yaml

```yaml
imagePullSecret:
  create: true
  automaticReferenceInjection: true
  registry: docker-image.kr.ncr.ntruss.com
  username: {액세스 키 삭제}
  password: {시크릿 키 삭제}
  email:

hub:
  networkPolicy:
    enabled: false
  config:
    Authenticator:
      admin_users:
        - jaehee
      allow_all: true
    OAuthenticator:
      enable_auth_state: true
      client_id: 7a1b367689c2464757eda446easdmklasmdkasmdl
      client_secret: gloas-72eb2da15c4be6c080eaasdnasjndjasndajsk
      oauth_callback_url: https://jupyter-dev.srrain.kro.kr/hub/oauth_callback
      scope:
        - openid
        - profile
        - read_user
    GitLabOAuthenticator:
      gitlab_host: https://gitlab.srrain.kro.kr
    JupyterHub:
      authenticator_class: oauthenticator.gitlab.GitLabOAuthenticator
  extraEnv:
    JUPYTERHUB_CRYPT_KEY: "$(openssl rand -hex 32)"
    GITLAB_HOST: https://gitlab.srrain.kro.kr
    # disable TLS verification for self-signed certificates
    OAUTH_TLS_VERIFY: "0"
  extraConfig:
    gitlab-config: |
      c.JupyterHub.spawner_class = 'kubespawner.KubeSpawner'
      c.GitLabOAuthenticator.scope = ['read_user api read_repository write_repository']

      async def add_auth_env(spawner):
         '''
         We set user's id, login and access token on single user image to
         enable repository integration for JupyterHub.
         See: https://gitlab.com/gitlab-org/gitlab-foss/issues/47138#note_154294790
         '''
         auth_state = await spawner.user.get_auth_state()

         if not auth_state:
            spawner.log.warning("No auth state for %s", spawner.user)
            return

         spawner.environment['GITLAB_ACCESS_TOKEN'] = auth_state['access_token']
         spawner.environment['GITLAB_USER_LOGIN'] = auth_state['gitlab_user']['username']
         spawner.environment['GITLAB_USER_ID'] = str(auth_state['gitlab_user']['id'])
         spawner.environment['GITLAB_USER_EMAIL'] = auth_state['gitlab_user']['email']
         spawner.environment['GITLAB_USER_NAME'] = auth_state['gitlab_user']['name']

      c.KubeSpawner.pre_spawn_hook = add_auth_env

singleuser:
  networkPolicy:
    enabled: false
  defaultUrl: "/lab"
  allowPrivilegeEscalation: true
  extraEnv:
    GITLAB_HOST: gitlab.srrain.kro.kr 
  profileList:
    - display_name: "Free"
      description: "사설 라이브러리 cpu 0.5 ~ / 메모리 1G ~ "
      default: true
      kubespawner_override:
        image: docker-image.kr.ncr.ntruss.com/juypter-image:0.10
        cpu_limit: 
        cpu_guarantee: 0.5
        mem_limit: 
        mem_guarantee: 1G

    - display_name: "Small"
      description: "사설 라이브러리 cpu 0.5 ~ 1 / 메모리 1G ~ 2G"
      kubespawner_override:
        image: docker-image.kr.ncr.ntruss.com/juypter-image:0.10
        cpu_limit: 1
        cpu_guarantee: 0.5
        mem_limit: 1G
        mem_guarantee: 2G

    - display_name: "High"
      description: "사설 라이브러리 cpu 1 ~ 4 / 메모리 2G ~ 8G"
      kubespawner_override:
        image: docker-image.kr.ncr.ntruss.com/juypter-image:0.10
        cpu_limit: 4
        cpu_guarantee: 1
        mem_limit: 8G
        mem_guarantee: 2G
  cpu:
    limit: 
    guarantee: 
  memory:
    limit: 
    guarantee: 
  lifecycleHooks:
    postStart:
      exec:
        command:
          - "sh"
          - "-c"
          - >
            git clone https://gitlab.com/gitlab-org/nurtch-demo.git TEST_REPO || true;
            echo "https://oauth2:${GITLAB_ACCESS_TOKEN}@${GITLAB_HOST}" > ~/.git-credentials;
            git config --global http.sslVerify false;
            git config --global credential.helper store;
            git config --global user.email "${GITLAB_USER_EMAIL}";
            git config --global user.name "${GITLAB_USER_NAME}";
            # jupyter serverextension enable --py jupyterlab_git
  extraFiles:
    jupyter_notebook_config.json:
      mountPath: /etc/jupyter/jupyter_notebook_config.json
      data:
        MappingKernelManager:
          cull_idle_timeout: 0 # default: 0 
          cull_interval: 0 # default: 300
          cull_connected: true # default: false
          cull_busy: false # default: false

ingress:
  enabled: true
  annotations:
    cert-manager.io/issuer: letsencrypt-prod
  hosts:
    - jupyter-dev.srrain.kro.kr
  tls:
    - hosts:
      - jupyter-dev.srrain.kro.kr
      secretName: tls-secret

proxy:
  chp:
    networkPolicy:
      enabled: false
  secretToken: "184ae13d4e33c3c77aa66e1c27389d06a78dce9965a5d704d72488f8f2709799"
  https:
    hosts:
      - jupyter-dev.srrain.kro.kr
    letsencrypt:
      contactEmail: hub@srrain.kro.kr
  service:
    type: ClusterIP
cull:
  enabled: true
  users: false # --cull-users
  adminUsers: false # --cull-admin-users
  removeNamedServers: false # --remove-named-servers
  timeout: 2629800 # --timeout 1m
  every: 86400 # --cull-every 1d
  concurrency: 10 # --concurrency
  maxAge: 0 # --max-age

debug:
  enabled: false
```

gitlab admin area → applications 탭 접속

![Untitled](jupyterhub_img/Untitled.png)

```makefile
value에서 적은 oauth_callback_url과 동일한 URI 기재

oauth_callback_url: https://jupyter-dev.srrain.kro.kr/hub/oauth_callback
https://jupyter-dev.srrain.kro.kr/hub/oauth_callback
```

#무효 값

![Untitled](jupyterhub_img/Untitled%201.png)

```makefile
생성된 키 값을 value에 기재
client_id: 애플리케이션 ID
client_secret: 비밀
```

![Untitled](jupyterhub_img/Untitled%202.png)

![Untitled](jupyterhub_img/Untitled%203.png)

![alt text](image.png)

![Untitled](jupyterhub_img/Untitled%205.png)

![Untitled](jupyterhub_img/Untitled%206.png)

---

주피터 허브에서 vscode 사용하는 방법

~~근데 이러면 주피터가 안올라옴 ;; 쓸모 없음…~~

찾아본 결과 spawner를 이중으로 사용하는 게 불가능해서 효용성 없음

오버라이드 기능 미제공

```yaml
# Configuration file for the vscode-jupyterhub helm installation
# See the README.md for information on how to apply it

singleuser:
  # Use the code-server image
  image:
    name: "codercom/code-server"
    tag: "3.6.2"

  # Mount the persistant volume claim
  # directly inside the home folder of
  # the coder user
  storage:
    homeMountPath: "/home/coder"

proxy:
  chp:
    # Make sure the code server does never get to know about
    # the user-specific prefixes and thinks "it runs by itself"
    extraCommandLineFlags:
    - "--no-include-prefix"
  # secret token
  secretToken: # TODO: Fill with the result of `openssl rand -hex 32`

hub:
  # The code-server needs different arguments
  # than the jupyter notebook image
  extraConfig:
    code_spawner.py: |
      from kubespawner.spawner import KubeSpawner
      from jupyterhub.spawner import _quote_safe

      class VSCodeKubeSpawner(KubeSpawner):
          def get_args(self):
              """Custom args function for the coder"""

              # Turn off authentication (happens via jupyterhub)
              args = ["--auth", "none"]
              # Turn off telemetry
              args += ["--disable-telemetry"]

              # set port and ip if given
              ip = "0.0.0.0"
              if self.ip:
                  ip = _quote_safe(self.ip)

              port = 8888
              if self.port:
                  port = self.port
              elif self.server and self.server.port:
                  self.log.warning(
                      "Setting port from user.server is deprecated as of JupyterHub 0.7."
                  )
                  port = self.server.port

              args += ["--bind-addr", f"{ip}:{port}"]

              # set startup folder
              if self.notebook_dir:
                  notebook_dir = self.format_string(self.notebook_dir)
                  args += ["--user-data-dir", _quote_safe(notebook_dir)]

              if self.debug:
                  args += ["-vvv"]

              args.extend(self.args)
              return args

      # Use the configured spawner
      c.JupyterHub.spawner_class = VSCodeKubeSpawner

    code_settings.py: |
      # The working dir is by default set to
      # /home/coder in the VSCode image
      c.VSCodeKubeSpawner.working_dir = "/home/coder"

      # By default, the cmd includes the call to "jupyterhub-singleserver"
      # However, the docker image already comes with the correct
      # VSCode command to call, so we just set it to an empty string here
      c.VSCodeKubeSpawner.cmd = ""
```

---

### dockerfile

```docker
# syntax = docker/dockerfile:1.3
# VULN_SCAN_TIME=2023-12-06_12:46:58

# The build stage
# ---------------
# This stage is building Python wheels for use in later stages by using a base
# image that has more pre-requisites to do so, such as a C++ compiler.
#
# NOTE: If the image version is updated, also update it in ci/refreeze and
#       hub's Dockerfile!
#
FROM python:3.11-bullseye as build-stage

# Build wheels
#
# We set pip's cache directory and expose it across build stages via an
# ephemeral docker cache (--mount=type=cache,target=${PIP_CACHE_DIR}). We use
# the same technique for the directory /tmp/wheels.
#
COPY requirements.txt requirements.txt
ARG PIP_CACHE_DIR=/tmp/pip-cache
RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    pip install build \
 && pip wheel \
        --wheel-dir=/tmp/wheels \
        -r requirements.txt

# The final stage
# ---------------
#
FROM python:3.11-slim-bullseye
ENV DEBIAN_FRONTEND=noninteractive

ENV NB_USER=jovyan \
    NB_UID=1000 \
    HOME=/home/jovyan

RUN apt-get update \
 && apt-get upgrade --yes \
 && apt-get install --yes --no-install-recommends \
        ca-certificates \
        dnsutils \
        iputils-ping \
        tini \
        postgresql-client \
        build-essential \
        curl \
        locales \
        git \
        sudo \
        vim \
        wget \
        zip \
        python3-pip \
        python3-setuptools \
        # requirement for nbgitpuller
        git \
 && rm -rf /var/lib/apt/lists/*

RUN adduser \
        --disabled-password \
        --gecos "Default user" \
        --uid ${NB_UID} \
        --home ${HOME} \
        --force-badname \
        ${NB_USER} && \
        usermod -aG sudo ${NB_USER}
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN pip install poetry --no-cache-dir && \
    poetry config virtualenvs.create false && \
    git clone https://token:glpat-hrhTLjcccSR7L_3XSk8Y@gitlab.srrain.kro.kr/srrain98/langchain.git && \
    cd langchain && \
    chown ${NB_USER}:${NB_USER} . -R && \
    poetry install --no-interaction --no-ansi --only main || true

RUN python3 -m pip install --no-cache-dir \
    git+https://token:glpat-hrhTLjcccSR7L_3XSk8Y@gitlab.srrain.kro.kr/srrain98/hcxai-main.git
#    git+https://token:glpat-hrhTLjcccSR7L_3XSk8Y@gitlab.srrain.kro.kr/srrain98/langchain.git

# install wheels built in the build-stage
COPY requirements.txt /tmp/requirements.txt
ARG PIP_CACHE_DIR=/tmp/pip-cache
RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    --mount=type=cache,from=build-stage,source=/tmp/wheels,target=/tmp/wheels \
    pip install \
        --find-links=/tmp/wheels/ \
        -r /tmp/requirements.txt

WORKDIR ${HOME}
USER ${NB_USER}

EXPOSE 8888
ENTRYPOINT ["tini", "--"]
CMD ["jupyter", "lab"]
```

---

### vscode를 jupyter의 plugin으로 추가한 dockerfile

Dockerfile

```docker
# Use the official Jupyter base notebook image as a parent image
FROM jupyter/base-notebook:latest

# Switch to root to install new packages
USER root

# Install dependencies for code-server
RUN apt-get update && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \ 
        ca-certificates \
        dnsutils \
        iputils-ping \
        tini \
        postgresql-client \
        build-essential \
        curl \
        locales \
        git \
        sudo \
        vim \
        wget \
        zip \
        python3-pip \
        python3-setuptools \
        git \
        make \
        cmake \
        g++ \
        clang \
        htop \
        libopencv-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN usermod -aG sudo $NB_USER \
 && echo "$NB_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$NB_USER \
 && chmod 0440 /etc/sudoers.d/$NB_USER

USER ${NB_USER}

#langchain
RUN pip install poetry --no-cache-dir && \
    poetry config virtualenvs.create false && \
    git clone https://token:glpat-hrhTLjcccSR7L_3XSk8Y@gitlab.srrain.kro.kr/srrain98/langchain.git && \
    cd langchain && \
    chown ${NB_USER} . -R && \
    poetry install --no-interaction --no-ansi --only main || true

#hcx
RUN python3 -m pip install --no-cache-dir \
    git+https://token:glpat-hrhTLjcccSR7L_3XSk8Y@gitlab.srrain.kro.kr/srrain98/hcxai-main.git

USER root

# Install code-server
ARG CODE_SERVER_VERSION=4.18.0
ARG CODE_BUILTIN_EXTENSIONS_DIR=/opt/code-server/lib/vscode/extensions

ENV PATH=/opt/code-server/bin:$PATH \
    CS_DISABLE_GETTING_STARTED_OVERRIDE=1

# Create the code-server directory
ENV CODE_VERSION=4.20.0
ENV PYTHON=/opt/conda/bin/python

RUN ARCH=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) \
    && curl -fOL https://github.com/coder/code-server/releases/download/v$CODE_VERSION/code-server_${CODE_VERSION}_${ARCH}.deb \
    && dpkg -i code-server_${CODE_VERSION}_${ARCH}.deb \
    && curl -sL https://upload.wikimedia.org/wikipedia/commons/9/9a/Visual_Studio_Code_1.35_icon.svg -o /opt/vscode.svg \
    && rm -f code-server_${CODE_VERSION}_${ARCH}.deb

RUN pip install oauthenticator \
    dockerspawner \
    jupyterhub-nativeauthenticator \
    jupyter-server-proxy \
    jupyter-vscode-proxy

RUN code-server --install-extension ms-ceintl.vscode-language-pack-ko 
    # Add more extensions as needed

RUN fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}" 

# Expose the code-server port, jupyter port
EXPOSE 8080
EXPOSE 8888

# Set the default command to launch both code-server and notebook server
ENTRYPOINT ["tini", "-g", "--"]
CMD ["/usr/local/bin/start-code-server.sh"]

# Switch back to the notebook user
USER $NB_UID
WORKDIR ${HOME}
```

![Untitled](jupyterhub_img/Untitled%207.png)

![Untitled](jupyterhub_img/Untitled%208.png)