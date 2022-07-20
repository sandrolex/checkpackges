# syntax = docker/dockerfile:1.2
FROM golang:1.16-alpine AS build

WORKDIR /src/ 
COPY main.go go.* /src/
RUN --mount=type=cache,target=${HOME}/.cache/go-build CGO_ENABLED=0 go build -o /bin/checkpackages

# final image
FROM scratch
COPY --from=build /bin/checkpackages /bin/checkpackages

ENTRYPOINT ["/bin/checkpackages"]
