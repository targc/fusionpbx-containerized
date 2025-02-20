FROM golang:1.23.2-alpine3.20 AS builder

WORKDIR /src

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

ARG TARGET

RUN go build -ldflags="-s -w -extldflags -static" -v -o app ${TARGET}
    
FROM alpine3.20

ENV TZ=UTC

WORKDIR /app

USER nonroot:nonroot

COPY --from=builder /src/app /app/app

CMD ["/app/app"]
