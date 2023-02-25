FROM debian:bullseye

ARG GITHUB_RUNNER_VERSION="2.301.1"

ENV GITHUB_PAT ""
ENV GITHUB_OWNER "fabianishere"
ENV GITHUB_REPOSITORY "pve-edge-kernel"
ENV RUNNER_WORKDIR "_work"

RUN apt-get update \
    && apt-get install -y \
        curl \
        sudo \
        git \
        jq \
        devscripts \
        debhelper \
        equivs \
        asciidoc \
        bc \
        bison \
        cpio \
        dwarves \
        flex \
        kmod \
        libdw-dev \
        libelf-dev \
        libiberty-dev \
        libnuma-dev \
        libslang2-dev \
        libssl-dev \
        lz4 \
        quilt \
        rsync \
        xmlto \
        zlib1g-dev \
        zstd \
        python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m github \
    && usermod -aG sudo github \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER github
WORKDIR /home/github

RUN curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz

COPY --chown=github:github entrypoint.sh ./entrypoint.sh
RUN sudo chmod u+x ./entrypoint.sh

ENTRYPOINT ["/home/github/entrypoint.sh"]
