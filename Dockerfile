FROM nimlang/nim:latest
MAINTAINER UCASZ <nope@233.com>

RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    apt update && \
    apt install -y mingw-w64 nim vim && \
    useradd -ms /bin/bash app

USER app    

RUN git config --global http.proxy 'http://192.168.109.1:1081' && \
    git config --global https.proxy 'http://192.168.109.1:1081' && \
    nimble install -y winim && \
    git config --global --unset http.proxy && \
    git config --global --unset https.proxy

WORKDIR /usr/src/app