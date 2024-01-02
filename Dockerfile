FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ARG TARGETARCH
ARG GOFLAGS="'-ldflags=-w -s'"

WORKDIR /go/src/github.com/jmorganca/ollama
RUN apt-get update && apt-get install -y git build-essential cmake
ADD https://dl.google.com/go/go1.21.3.linux-$TARGETARCH.tar.gz /tmp/go1.21.3.tar.gz
RUN mkdir -p /usr/local && tar xz -C /usr/local </tmp/go1.21.3.tar.gz

COPY . .
ENV GOARCH=$TARGETARCH
ENV GOFLAGS=$GOFLAGS
RUN /usr/local/go/bin/go generate ./... \
    && /usr/local/go/bin/go build .

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=0 /go/src/github.com/jmorganca/ollama/ollama /bin/ollama
# EXPOSE 11434
ENV OLLAMA_HOST 127.0.0.1
EXPOSE 3000
# set some environment variable for better NVIDIA compatibility
ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Set the CUDA_VISIBLE_DEVICES environment variable
ENV CUDA_VISIBLE_DEVICES=0

# Install curl and add the NodeSource repositories
RUN apt-get update && apt-get install -y curl && \
    curl -sL https://deb.nodesource.com/setup_18.x | bash -

# Install git, protobuf-compiler, unzip, nodejs, and npm
RUN apt-get install -y git protobuf-compiler unzip nodejs tmux xdg-utils

WORKDIR /usr/src/


# Clone the repository
RUN git clone https://github.com/huggingface/chat-ui.git

# create file .env.local to chat-ui
COPY models_config /usr/src/chat-ui/models_config
COPY run.sh /usr/src/chat-ui/run.sh
RUN chmod +x /usr/src/chat-ui/run.sh

RUN npm install -g npm@10.2.5
RUN npm install @sveltejs/kit
RUN npm install --save-dev vite

WORKDIR /usr/src/chat-ui


ENTRYPOINT /bin/ollama serve & /usr/src/chat-ui/run.sh