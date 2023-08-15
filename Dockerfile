FROM golang:1.20 as builder

RUN go install github.com/jsha/minica@latest && go install github.com/go-acme/lego/v4/cmd/lego@latest

FROM nginx:latest

COPY --from=builder /go/bin/minica /usr/local/bin/minica
COPY --from=builder /go/bin/lego /usr/local/bin/lego

VOLUME /work
WORKDIR /work

COPY nginx.conf /etc/nginx/nginx.conf.tmpl
COPY entrypoint.sh /entrypoint.sh
COPY index.html /var/www/index.html

ENTRYPOINT ["/entrypoint.sh"]
