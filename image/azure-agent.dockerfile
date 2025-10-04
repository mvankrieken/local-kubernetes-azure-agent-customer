FROM ubuntu:22.04

# Also can be "linux-arm", "linux-arm64".
ENV TARGETARCH="linux-x64"
ENV TZ="Europe/Amsterdam"
ENV DEBIAN_FRONTEND="noninteractive"

# Install defaults
RUN apt update &&\
    apt upgrade -y &&\
    apt install -y curl libicu70 software-properties-common git jq

# Install tools
COPY ./build-tools.sh ./
RUN chmod +x ./build-tools.sh
RUN ./build-tools.sh

# WORKDIR
WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

RUN useradd agent &&\
    chown -R agent /azp/ &&\
    mkdir -p /home/agent/ &&\
    chown -R agent /home/agent/
COPY ./pypirc /home/agent/.pypirc

USER agent

ENTRYPOINT ["./start.sh"]