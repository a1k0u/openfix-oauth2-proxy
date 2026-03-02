FROM debian:13

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        make \
        sudo \
        gpg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
