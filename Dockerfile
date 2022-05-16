FROM debian:buster

# Environment variables
ENV HOME=/root \
  GOPATH=/root/go \
  PATH=/root/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  GO_VERSION=1.16.6 \
  DEBIAN_FRONTEND=noninteractive \
  rust_version=2018 

RUN mkdir -p /root/go/src \
  # Update 
  && apt-get update && apt-get install -y ca-certificates build-essential  git subversion  curl sudo wget zip  apt-transport-https \
  # get go
  && wget -qO- https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz | tar -C /usr/local -xzf - \

  # golang issue at: https://github.com/golang/go/issues/9344
  # https://github.com/GoogleCloudPlatform/kubernetes/commit/0a538132cf00f105489c0b8205d437b48688a7e1
  # https://github.com/aledbf/deis/commit/7c4fc31dc8565b7f992ac5121f40eecb63193c1a
  #
  # Any builds will need -installsuffix cgo to take advantage of static builds, but will not need to rebuild
  # the standard library any longer
  # TODO: I think that installsuffix is no longer necessary and was a temporary hack for a go tool problem.
  && CGO_ENABLED=0 go install -a -installsuffix cgo std \
  && go get golang.org/x/tools/cmd/goimports \
  # Clean apt, reduce image size
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  # update certs
  && update-ca-certificates -f \

  && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh | yes

# Set working path
WORKDIR /root/go

# Add scripts
ADD scripts /scripts
RUN chmod +x /scripts/*.sh

# Run the build script
# and exit to a shell
CMD bash -C "build/build.sh"
