FROM golang:buster as build
RUN apt-get update && apt-get install -y libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev build-essential git
RUN git clone https://github.com/containers/skopeo /go/src/github.com/containers/skopeo && cd /go/src/github.com/containers/skopeo && make binary-local


# Toolbox Container fuer Docker Debugging / CI
FROM debian:buster-slim

COPY --from=build /go/src/github.com/containers/skopeo/skopeo /usr/local/bin/skopeo

# Tool Versions to pull, kubectl will use 'stable'
#ARG KUBECTL_VERSION= 
ARG RANCHER_VERSION=2.3.2
ARG HELM3_VERSION=3.1.0
ARG HELM2_VERSION=2.16.3
ARG VAULT_VERSION=1.3.2
ARG ARGOCD_VERSION=1.4.2
ARG FLUXCTL_VERSION=1.18.0

# Additional Tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        git wget ca-certificates gnupg2 unzip jq vim \
        python3-rados python3-pip python3-yaml python3-setuptools python3-wheel python3-dev \
        curl rpm openssh-client build-essential autoconf automake autotools-dev libtool && \
        apt-get clean


# Python Stuff
# - yq = jq for yaml
RUN pip3 install yq

# Buildah & Podman
# source: https://github.com/containers/buildah/blob/master/install.md
# source: https://podman.io/getting-started/installation
#
RUN echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/ /' >> /etc/apt/sources.list && \
    wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/Debian_10/Release.key -O- | apt-key add - && \
    apt-get update && apt-get install -y buildah podman && apt-get clean

# Helm v3
RUN wget -nv https://get.helm.sh/helm-v${HELM3_VERSION}-linux-amd64.tar.gz && tar -xf helm-v*-linux-amd64.tar.gz && rm -f helm-v*-linux-amd64.tar.gz && \
    mkdir -p /usr/local/bin && mv linux-amd64/helm /usr/local/bin/

# Helm v2 (legacy)
RUN wget -nv https://get.helm.sh/helm-v${HELM2_VERSION}-linux-amd64.tar.gz && tar -xf helm-v*-linux-amd64.tar.gz && rm -f helm-v*-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm2 && mv linux-amd64/tiller /usr/local/bin/ && rm -rf --one-file-system linux-amd64

# Vault Secret Management
RUN wget -nv https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && unzip vault_*.zip && mv vault /usr/local/bin \
    && rm -f vault*.zip
    
# Rancher CLI
RUN wget -nv https://releases.rancher.com/cli2/v${RANCHER_VERSION}/rancher-linux-amd64-v${RANCHER_VERSION}.tar.gz && tar -xvf rancher-*.tar.gz \
    && mv rancher-v${RANCHER_VERSION}/rancher /usr/local/bin/ && rm -rf rancher*

# ArgoCD CLI
RUN wget -O /usr/local/bin/argocd -nv https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64

# Kubectl 'stable'
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    mv kubectl /usr/local/bin/

RUN wget -O /usr/local/bin/fluxctl https://github.com/fluxcd/flux/releases/download/${FLUXCTL_VERSION}/fluxctl_linux_amd64

# Make all executable
RUN chmod +x /usr/local/bin/*
