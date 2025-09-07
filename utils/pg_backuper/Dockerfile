FROM alpine:3.19

RUN apk add --no-cache \
	 postgresql16-client \
	 gzip \
	 curl \
     gnupg \
	 rclone

COPY backup.sh /backup.sh
RUN chmod +x /backup.sh \
    && mkdir -p /root/.gnupg && chmod 700 /root/.gnupg && gpg --list-keys >/dev/null 2>&1 || true

ENTRYPOINT ["/backup.sh"]
