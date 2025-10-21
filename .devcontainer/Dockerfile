# ==============================================================================
# ULTIMATE OPEN SOURCE DEVELOPMENT CONTAINER - Rice Monorepo
# ==============================================================================
# Million Dollar Per Hour Developer Environment
# Every language, every framework, every tool - 100% Open Source
# ==============================================================================

FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# ============================================================================
# LOCALE & TIMEZONE
# ============================================================================
RUN apt-get update && apt-get install -y locales tzdata && \
    locale-gen en_US.UTF-8 && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TZ=UTC

# ============================================================================
# SYSTEM DEPENDENCIES - COMPREHENSIVE
# ============================================================================
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    pkg-config \
    cmake \
    ninja-build \
    autoconf \
    automake \
    libtool \
    make \
    m4 \
    # Compilers & Development
    gcc \
    g++ \
    clang \
    llvm \
    gdb \
    valgrind \
    strace \
    ltrace \
    # Version control
    git \
    git-lfs \
    git-flow \
    mercurial \
    subversion \
    # Network tools
    curl \
    wget \
    netcat \
    netcat-openbsd \
    socat \
    telnet \
    nmap \
    iputils-ping \
    dnsutils \
    traceroute \
    whois \
    iproute2 \
    net-tools \
    # Compression & Archives
    zip \
    unzip \
    bzip2 \
    xz-utils \
    p7zip-full \
    tar \
    gzip \
    zstd \
    # Text processing
    jq \
    yq \
    sed \
    awk \
    gawk \
    grep \
    ripgrep \
    fd-find \
    # Text editors
    vim \
    neovim \
    nano \
    emacs-nox \
    # Shell & Terminal
    bash \
    bash-completion \
    zsh \
    fish \
    tmux \
    screen \
    # System monitoring
    htop \
    atop \
    iotop \
    sysstat \
    procps \
    psmisc \
    lsof \
    # File tools
    tree \
    ncdu \
    rsync \
    rclone \
    # SSL/TLS & Crypto
    ca-certificates \
    openssl \
    libssl-dev \
    gnupg \
    gnupg2 \
    # Database clients
    postgresql-client \
    redis-tools \
    sqlite3 \
    mongodb-clients \
    # Libraries for various languages
    libffi-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    libgdbm-dev \
    libbz2-dev \
    liblzma-dev \
    libgmp-dev \
    libmpfr-dev \
    zlib1g-dev \
    # Python dependencies
    python3-dev \
    python3-pip \
    python3-venv \
    pipx \
    # Additional utilities
    bat \
    fzf \
    direnv \
    silversearcher-ag \
    dos2unix \
    hexdump \
    colordiff \
    moreutils \
    parallel \
    bc \
    dc \
    man-db \
    manpages-dev \
    apt-transport-https \
    software-properties-common \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Fix fd and bat commands (Ubuntu naming conflicts)
RUN ln -s $(which fdfind) /usr/local/bin/fd || true
RUN ln -s $(which batcat) /usr/local/bin/bat || true

# ============================================================================
# ASDF - Universal Version Manager
# ============================================================================
ENV ASDF_DIR=/opt/asdf
ENV ASDF_DATA_DIR=/opt/asdf
RUN git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} --branch v0.14.0 && \
    echo '. ${ASDF_DIR}/asdf.sh' >> /etc/bash.bashrc && \
    echo '. ${ASDF_DIR}/asdf.sh' >> /etc/zsh/zshrc

ENV PATH="${ASDF_DIR}/bin:${ASDF_DIR}/shims:${PATH}"

# ============================================================================
# BAZEL BUILD SYSTEM
# ============================================================================
ARG BAZEL_VERSION=7.0.0
RUN curl -fsSL https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh -o /tmp/bazel-installer.sh && \
    chmod +x /tmp/bazel-installer.sh && \
    /tmp/bazel-installer.sh && \
    rm /tmp/bazel-installer.sh && \
    bazel completion > /etc/bash_completion.d/bazel

# Bazelisk (Bazel version manager)
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 -o /usr/local/bin/bazelisk && \
    chmod +x /usr/local/bin/bazelisk

# Buildifier (Bazel formatter)
RUN go install github.com/bazelbuild/buildtools/buildifier@latest || true

# ============================================================================
# PYTHON ECOSYSTEM - MULTIPLE VERSIONS
# ============================================================================
# Install Python 3.11 and 3.12
RUN add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Upgrade pip
RUN python3 -m pip install --upgrade pip setuptools wheel

# Poetry - Modern Python packaging
ENV POETRY_HOME=/opt/poetry
ENV PATH="${POETRY_HOME}/bin:${PATH}"
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    poetry --version && \
    poetry config virtualenvs.in-project true

# PDM - Another modern Python package manager
RUN pip3 install --no-cache-dir pdm

# Pipenv
RUN pip3 install --no-cache-dir pipenv

# Python development tools
RUN pip3 install --no-cache-dir \
    # Formatters & Linters
    black \
    ruff \
    isort \
    autopep8 \
    yapf \
    blue \
    # Type checkers
    mypy \
    pyright \
    pyre-check \
    # Linters
    pylint \
    flake8 \
    pyflakes \
    pycodestyle \
    pydocstyle \
    bandit \
    # Testing
    pytest \
    pytest-cov \
    pytest-asyncio \
    pytest-xdist \
    pytest-mock \
    hypothesis \
    tox \
    nox \
    # Documentation
    sphinx \
    mkdocs \
    mkdocs-material \
    pdoc3 \
    # Web frameworks
    fastapi \
    flask \
    django \
    # Data science & ML
    numpy \
    pandas \
    scipy \
    matplotlib \
    scikit-learn \
    jupyter \
    jupyterlab \
    notebook \
    # Other tools
    ipython \
    pre-commit \
    cookiecutter \
    httpie \
    requests \
    aiohttp \
    pydantic \
    typer

# ============================================================================
# RUST ECOSYSTEM
# ============================================================================
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH="${CARGO_HOME}/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable && \
    chmod -R a+w ${RUSTUP_HOME} ${CARGO_HOME}

# Rust toolchains
RUN rustup toolchain install stable nightly && \
    rustup default stable

# Rust components
RUN rustup component add \
    rust-analyzer \
    rustfmt \
    clippy \
    rust-src \
    llvm-tools-preview

# WASM targets
RUN rustup target add \
    wasm32-unknown-unknown \
    wasm32-wasi

# Rust development tools
RUN cargo install \
    cargo-watch \
    cargo-edit \
    cargo-audit \
    cargo-outdated \
    cargo-tree \
    cargo-expand \
    cargo-tarpaulin \
    cargo-flamegraph \
    cargo-bloat \
    cargo-unused-features \
    wasm-pack \
    trunk \
    mdbook \
    tokei \
    hyperfine \
    bottom \
    du-dust \
    procs \
    sd \
    grex \
    just

# ============================================================================
# NODE.JS & JAVASCRIPT ECOSYSTEM
# ============================================================================
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Alternative runtimes
# Deno
RUN curl -fsSL https://deno.land/install.sh | sh
ENV DENO_INSTALL="/root/.deno"
ENV PATH="${DENO_INSTALL}/bin:${PATH}"

# Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL="/root/.bun"
ENV PATH="${BUN_INSTALL}/bin:${PATH}"

# Package managers
RUN npm install -g \
    npm@latest \
    yarn \
    pnpm \
    npm-check-updates \
    npm-check

# Build tools & bundlers
RUN npm install -g \
    webpack \
    webpack-cli \
    vite \
    rollup \
    esbuild \
    parcel \
    turbo \
    nx

# TypeScript & Tools
RUN npm install -g \
    typescript \
    ts-node \
    tsx \
    @types/node \
    tsup \
    tsc-alias

# Linters & Formatters
RUN npm install -g \
    eslint \
    prettier \
    @biomejs/biome \
    stylelint \
    markdownlint-cli

# Testing frameworks
RUN npm install -g \
    jest \
    vitest \
    playwright \
    @playwright/test

# Development servers & tools
RUN npm install -g \
    nodemon \
    pm2 \
    concurrently \
    npm-run-all

# Framework CLIs
RUN npm install -g \
    @angular/cli \
    create-next-app \
    create-react-app \
    @vue/cli \
    nuxi \
    @sveltejs/kit \
    @remix-run/dev \
    gatsby-cli \
    @nestjs/cli \
    create-t3-app

# API & Backend tools
RUN npm install -g \
    json-server \
    http-server \
    serve \
    express-generator

# Code generators
RUN npm install -g \
    yo \
    generator-code \
    plop \
    hygen

# Documentation
RUN npm install -g \
    jsdoc \
    typedoc \
    docusaurus

# ============================================================================
# GO ECOSYSTEM
# ============================================================================
ARG GO_VERSION=1.22.0
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf -
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:${PATH}"
RUN mkdir -p ${GOPATH}/{src,bin,pkg}

# Go tools
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install github.com/cosmtrek/air@latest && \
    go install github.com/swaggo/swag/cmd/swag@latest && \
    go install github.com/google/wire/cmd/wire@latest && \
    go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest && \
    go install entgo.io/ent/cmd/ent@latest && \
    go install github.com/99designs/gqlgen@latest

# ============================================================================
# JVM ECOSYSTEM - JAVA, KOTLIN, SCALA, CLOJURE
# ============================================================================
# Install Java 17 and 21
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    openjdk-21-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set Java 17 as default
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Maven
ARG MAVEN_VERSION=3.9.6
RUN curl -fsSL https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | tar -C /opt -xzf - && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven
ENV PATH="/opt/maven/bin:${PATH}"

# Gradle
ARG GRADLE_VERSION=8.5
RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o /tmp/gradle.zip && \
    unzip /tmp/gradle.zip -d /opt && \
    ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle && \
    rm /tmp/gradle.zip
ENV PATH="/opt/gradle/bin:${PATH}"

# Kotlin
ARG KOTLIN_VERSION=1.9.22
RUN curl -fsSL https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip -o /tmp/kotlin.zip && \
    unzip /tmp/kotlin.zip -d /opt && \
    rm /tmp/kotlin.zip
ENV PATH="/opt/kotlinc/bin:${PATH}"

# Scala
ARG SCALA_VERSION=3.3.1
RUN curl -fsSL https://github.com/scala/scala3/releases/download/${SCALA_VERSION}/scala3-${SCALA_VERSION}.tar.gz | tar -C /opt -xzf -
ENV PATH="/opt/scala3-${SCALA_VERSION}/bin:${PATH}"

# SBT (Scala Build Tool)
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823 | apt-key add - && \
    apt-get update && apt-get install -y sbt && \
    rm -rf /var/lib/apt/lists/*

# Leiningen (Clojure build tool)
RUN curl -fsSL https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein -o /usr/local/bin/lein && \
    chmod +x /usr/local/bin/lein && \
    lein version

# ============================================================================
# RUBY ECOSYSTEM
# ============================================================================
ARG RUBY_VERSION=3.3.0
RUN apt-get update && apt-get install -y \
    ruby-full \
    && rm -rf /var/lib/apt/lists/*

# Bundler
RUN gem install bundler

# Ruby tools
RUN gem install \
    rubocop \
    solargraph \
    rails \
    sinatra \
    rake \
    rspec

# ============================================================================
# PHP ECOSYSTEM
# ============================================================================
RUN add-apt-repository -y ppa:ondrej/php && \
    apt-get update && apt-get install -y \
    php8.3 \
    php8.3-cli \
    php8.3-common \
    php8.3-curl \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-zip \
    php8.3-mysql \
    php8.3-pgsql \
    php8.3-sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ============================================================================
# .NET ECOSYSTEM
# ============================================================================
RUN wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet && \
    rm /tmp/dotnet-install.sh

ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="${DOTNET_ROOT}:${PATH}"

# ============================================================================
# ERLANG & ELIXIR
# ============================================================================
RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
    dpkg -i erlang-solutions_2.0_all.deb && \
    apt-get update && apt-get install -y \
    esl-erlang \
    elixir \
    && rm -rf /var/lib/apt/lists/* erlang-solutions_2.0_all.deb

# Hex & Phoenix
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix archive.install hex phx_new --force

# ============================================================================
# HASKELL
# ============================================================================
RUN curl -sSL https://get.haskellstack.org/ | sh

# GHCup (Haskell toolchain installer)
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# ============================================================================
# OCAML
# ============================================================================
RUN apt-get update && apt-get install -y \
    opam \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# PERL
# ============================================================================
RUN apt-get update && apt-get install -y \
    perl \
    cpanminus \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# LUA
# ============================================================================
RUN apt-get update && apt-get install -y \
    lua5.4 \
    luarocks \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# ZIG
# ============================================================================
ARG ZIG_VERSION=0.11.0
RUN curl -fsSL https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz | tar -C /opt -xJf - && \
    ln -s /opt/zig-linux-x86_64-${ZIG_VERSION} /opt/zig
ENV PATH="/opt/zig:${PATH}"

# ============================================================================
# NIM
# ============================================================================
RUN curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y
ENV PATH="/root/.nimble/bin:${PATH}"

# ============================================================================
# CRYSTAL
# ============================================================================
RUN curl -fsSL https://crystal-lang.org/install.sh | bash

# ============================================================================
# ANDROID DEVELOPMENT
# ============================================================================
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

ARG ANDROID_CMDLINE_VERSION=11076708
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_VERSION}_latest.zip -o /tmp/cmdline-tools.zip && \
    unzip /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Accept licenses
RUN yes | sdkmanager --licenses || true

# Install essential Android SDK packages
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "emulator"

# ============================================================================
# FLUTTER & DART DEVELOPMENT
# ============================================================================
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 ${FLUTTER_HOME} && \
    flutter precache && \
    flutter config --no-analytics && \
    flutter doctor || true

# ============================================================================
# PROTOCOL BUFFERS & gRPC
# ============================================================================
ARG PROTOC_VERSION=25.2
RUN curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o /tmp/protoc.zip && \
    unzip /tmp/protoc.zip -d /usr/local && \
    rm /tmp/protoc.zip && \
    chmod +x /usr/local/bin/protoc

# Protocol buffer plugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && \
    npm install -g grpc-tools grpc_tools_node_protoc_ts || true

# Buf (modern protobuf tooling)
ARG BUF_VERSION=1.29.0
RUN curl -fsSL https://github.com/bufbuild/buf/releases/download/v${BUF_VERSION}/buf-Linux-x86_64 -o /usr/local/bin/buf && \
    chmod +x /usr/local/bin/buf

# grpcurl
RUN go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# Evans (gRPC client)
RUN go install github.com/ktr0731/evans@latest

# ============================================================================
# BLOCKCHAIN & WEB3 DEVELOPMENT
# ============================================================================
# Solidity development
RUN npm install -g \
    hardhat \
    @nomicfoundation/hardhat-toolbox \
    ethers \
    @openzeppelin/contracts \
    truffle \
    ganache

# Foundry (Forge, Cast, Anvil, Chisel)
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN /root/.foundry/bin/foundryup || true

# Solana CLI
RUN sh -c "$(curl -sSfL https://release.solana.com/stable/install)" && \
    echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> /etc/bash.bashrc
ENV PATH="/root/.local/share/solana/install/active_release/bin:${PATH}"

# ============================================================================
# DOCKER & CONTAINER TOOLS
# ============================================================================
RUN apt-get update && apt-get install -y \
    docker.io \
    docker-compose \
    && rm -rf /var/lib/apt/lists/*

# Dive (Docker image explorer)
RUN curl -fsSL https://github.com/wagoodman/dive/releases/download/v0.12.0/dive_0.12.0_linux_amd64.tar.gz | tar -C /usr/local/bin -xzf -

# Hadolint (Dockerfile linter)
RUN curl -fsSL https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint && \
    chmod +x /usr/local/bin/hadolint

# Trivy (Security scanner)
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# ============================================================================
# KUBERNETES TOOLS
# ============================================================================
# kubectl
RUN curl -fsSL https://dl.k8s.io/release/v1.29.1/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# k9s (Kubernetes TUI)
RUN curl -fsSL https://github.com/derailed/k9s/releases/download/v0.31.7/k9s_Linux_amd64.tar.gz | tar -C /usr/local/bin -xzf -

# kubectx & kubens
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
    ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
    ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# stern (multi-pod log tailing)
RUN curl -fsSL https://github.com/stern/stern/releases/download/v1.28.0/stern_1.28.0_linux_amd64.tar.gz | tar -C /usr/local/bin -xzf -

# kind (Kubernetes in Docker)
RUN curl -fsSL https://kind.sigs.k8s.io/dl/v0.21.0/kind-linux-amd64 -o /usr/local/bin/kind && \
    chmod +x /usr/local/bin/kind

# kustomize
RUN curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.3.0/kustomize_v5.3.0_linux_amd64.tar.gz | tar -C /usr/local/bin -xzf -

# skaffold
RUN curl -fsSL https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 -o /usr/local/bin/skaffold && \
    chmod +x /usr/local/bin/skaffold

# ============================================================================
# TERRAFORM & IAC TOOLS
# ============================================================================
ARG TERRAFORM_VERSION=1.7.0
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    rm /tmp/terraform.zip

# Terragrunt
RUN curl -fsSL https://github.com/gruntwork-io/terragrunt/releases/download/v0.54.20/terragrunt_linux_amd64 -o /usr/local/bin/terragrunt && \
    chmod +x /usr/local/bin/terragrunt

# tflint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# tfsec
RUN curl -fsSL https://github.com/aquasecurity/tfsec/releases/download/v1.28.5/tfsec-linux-amd64 -o /usr/local/bin/tfsec && \
    chmod +x /usr/local/bin/tfsec

# Packer
ARG PACKER_VERSION=1.10.1
RUN curl -fsSL https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip -o /tmp/packer.zip && \
    unzip /tmp/packer.zip -d /usr/local/bin && \
    rm /tmp/packer.zip

# ============================================================================
# ANSIBLE
# ============================================================================
RUN pip3 install --no-cache-dir \
    ansible \
    ansible-lint \
    molecule \
    yamllint

# ============================================================================
# CLOUD CLI TOOLS
# ============================================================================
# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws*

# Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install -y google-cloud-cli && \
    rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# ============================================================================
# TESTING & LOAD TESTING
# ============================================================================
# k6
RUN gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69 && \
    echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | tee /etc/apt/sources.list.d/k6.list && \
    apt-get update && apt-get install -y k6 && \
    rm -rf /var/lib/apt/lists/*

# Playwright browsers
RUN npx playwright install --with-deps chromium firefox webkit || true

# ============================================================================
# GIT TOOLS
# ============================================================================
# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') && \
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
    tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit && \
    rm /tmp/lazygit.tar.gz

# lazydocker
RUN curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# pre-commit
RUN pip3 install --no-cache-dir pre-commit

# gitleaks (secret scanner)
RUN curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz | tar -C /usr/local/bin -xzf -

# ============================================================================
# MONITORING & OBSERVABILITY TOOLS
# ============================================================================
# Grafana Loki - LogCLI
RUN curl -fsSL https://github.com/grafana/loki/releases/download/v2.9.4/logcli-linux-amd64.zip -o /tmp/logcli.zip && \
    unzip /tmp/logcli.zip -d /tmp && \
    mv /tmp/logcli-linux-amd64 /usr/local/bin/logcli && \
    chmod +x /usr/local/bin/logcli && \
    rm /tmp/logcli.zip

# ============================================================================
# DATABASE TOOLS
# ============================================================================
# DBeaver CLI (if available) - skip for now as it's GUI focused
# usql (universal database CLI)
RUN curl -fsSL https://github.com/xo/usql/releases/download/v0.17.5/usql_static-0.17.5-linux-amd64.tar.bz2 | tar -C /tmp -xjf - && \
    mv /tmp/usql_static /usr/local/bin/usql && \
    chmod +x /usr/local/bin/usql

# ============================================================================
# API DEVELOPMENT & TESTING
# ============================================================================
# HTTPie (already installed via pip)
# Postman CLI
RUN curl -o- "https://dl-cli.pstmn.io/install/linux64.sh" | sh || true

# ============================================================================
# DOCUMENTATION TOOLS
# ============================================================================
# Hugo (static site generator)
ARG HUGO_VERSION=0.122.0
RUN curl -fsSL https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz | tar -C /usr/local/bin -xzf -

# ============================================================================
# SHELL ENHANCEMENTS
# ============================================================================
# Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true

# Starship prompt
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# zoxide (better cd)
RUN curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# ============================================================================
# MISC PRODUCTIVITY TOOLS
# ============================================================================
# delta (better git diff)
RUN curl -fsSL https://github.com/dandavison/delta/releases/download/0.16.5/delta-0.16.5-x86_64-unknown-linux-gnu.tar.gz | tar -C /tmp -xzf - && \
    mv /tmp/delta-0.16.5-x86_64-unknown-linux-gnu/delta /usr/local/bin/ && \
    rm -rf /tmp/delta-*

# eza (modern ls replacement)
RUN wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list && \
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
    apt-get update && apt-get install -y eza && \
    rm -rf /var/lib/apt/lists/*

# ============================================================================
# MACHINE LEARNING & AI
# ============================================================================
# Ollama (for running LLMs locally)
RUN curl -fsSL https://ollama.ai/install.sh | sh || true

# MLflow
RUN pip3 install --no-cache-dir mlflow

# DVC (Data Version Control)
RUN pip3 install --no-cache-dir dvc dvc-s3

# ============================================================================
# BENCHMARKING & PROFILING
# ============================================================================
# hyperfine (already installed via cargo)
# hey (HTTP load generator)
RUN curl -fsSL https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -o /usr/local/bin/hey && \
    chmod +x /usr/local/bin/hey

# ============================================================================
# USER SETUP & PERMISSIONS
# ============================================================================
# Create vscode user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash && \
    apt-get update && \
    apt-get install -y sudo && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    rm -rf /var/lib/apt/lists/*

# Give user access to all installed tools
RUN mkdir -p /workspace && \
    chown -R $USERNAME:$USERNAME \
    /workspace \
    /usr/local/cargo \
    /usr/local/rustup \
    ${FLUTTER_HOME} \
    ${ANDROID_HOME} \
    /go \
    ${ASDF_DIR} || true

# ============================================================================
# WORKSPACE SETUP
# ============================================================================
WORKDIR /workspace

# Set up git-safe directory
RUN git config --global --add safe.directory /workspace

# Switch to vscode user
USER $USERNAME

# User-specific configurations
RUN git config --global init.defaultBranch main && \
    git config --global core.editor "vim" && \
    git config --global pull.rebase false

# Install user-level Python packages
RUN pip3 install --user virtualenv pipenv

# Setup direnv for the user
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bashrc && \
    echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc || true

# Setup starship prompt
RUN mkdir -p ~/.config && \
    echo 'eval "$(starship init bash)"' >> ~/.bashrc && \
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc || true

# ============================================================================
# HEALTHCHECK
# ============================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 --version && node --version && go version && cargo --version || exit 1

# ============================================================================
# DEFAULT COMMAND
# ============================================================================
CMD ["/bin/bash"]

# ==============================================================================
# END OF ULTIMATE DEVELOPMENT CONTAINER
# ==============================================================================
