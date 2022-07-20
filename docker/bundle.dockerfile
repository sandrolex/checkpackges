# syntax = docker/dockerfile:1.2
FROM golang:1.16-alpine AS build

# build checkpackages
WORKDIR /src/ 
COPY main.go go.* /src
RUN --mount=type=cache,target=${HOME}/.cache/go-build CGO_ENABLED=0 go build -o /bin/checkpackages


# download dockle release
# TODO: build last version from source
WORKDIR /tmp
RUN wget https://github.com/goodwithtech/dockle/releases/download/v0.3.13/dockle_0.3.13_Linux-64bit.tar.gz && tar xvfz dockle_0.3.13_Linux-64bit.tar.gz

# final image
#FROM scratch
# NOTE: can't use scratch because of certs
FROM alpine:3.13

ENV MONITOR false
ENV NONBLOCKING false
ENV PROFILE prod

COPY --from=build /bin/checkpackages /usr/local/bin/checkpackages
RUN chmod +x /usr/local/bin/checkpackages
COPY --from=build /tmp/dockle /usr/local/bin/dockle
RUN chmod +x /usr/local/bin/dockle 

RUN apk update && apk add --no-cache ca-certificates shadow npm docker-cli

# install snyk snyk 
RUN npm install --global snyk

COPY scripts/security-check.sh /usr/local/bin/security-check.sh
RUN chmod +x /usr/local/bin/security-check.sh

# COPY policies
RUN mkdir -p /opt/runtime/base-images && mkdir -p /opt/runtime/prod-images
COPY policies/dockle/debian-dockle-base-image /opt/runtime/base-images/.dockeignore
COPY policies/dockle/debian-dockle-production-image /opt/runtime/prod-images/.dockleignore
COPY policies/snyk/debian-snyk /opt/runtime/prod-images/.snyk
COPY policies/snyk/debian-snyk /opt/runtime/base-images/.snyk
COPY policies/packages/debian-blacklist.txt /opt/runtime/base-images/blacklist.txt
COPY policies/packages/debian-blacklist.txt /opt/runtime/prod-images/blacklist.txt

ENTRYPOINT ["/usr/local/bin/security-check.sh"]
