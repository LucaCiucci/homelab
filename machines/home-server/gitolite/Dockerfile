FROM alpine:3.21

RUN apk add --no-cache openssh gitolite && \
    ssh-keygen -A && \
    mkdir -p /etc/ssh/keys

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
