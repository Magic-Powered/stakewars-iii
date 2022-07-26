

# syntax=docker/dockerfile-upstream:experimental

FROM ubuntu:18.04 as build

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y \
    git \
    cmake \
    g++ \
    pkg-config \
    libssl-dev \
    curl \
    llvm \
    clang \
    && rm -rf /var/lib/apt/lists/*

COPY ./rust-toolchain.toml /tmp/rust-toolchain.toml

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- -y --no-modify-path --default-toolchain none

ARG NEARCORE_VERSION=0f81dca95a55f975b6e54fe6f311a71792e21698

RUN git clone https://github.com/near/nearcore /near \
	&& cd /near \
	&& git fetch \
	&& git checkout ${NEARCORE_VERSION}

VOLUME [ /near ]
WORKDIR /near

ENV PORTABLE=ON
ARG make_target=shardnet-release
RUN make CARGO_TARGET_DIR=/tmp/target \
         "${make_target:?make_target not set}"

# Actual image
FROM node:buster-slim

EXPOSE 3030 24567

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y \
    libssl-dev ca-certificates jq awscli cron wget xz-utils curl less\
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g near-cli

COPY --from=build /tmp/target/release/neard /usr/local/bin/
COPY scripts/*.sh /usr/local/bin/

CMD ["/usr/local/bin/run.sh"]
