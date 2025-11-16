FROM alpine:3.19

RUN apk add --no-cache \
	 postgresql16-client \
	 gzip \
	 curl \
     gnupg \
     findutils \
	 rclone \
    sqlite

RUN mkdir -p /root/.gnupg && chmod 700 /root/.gnupg && gpg --list-keys >/dev/null 2>&1 || true

WORKDIR /backuper
COPY backuper.sh .
ENTRYPOINT [ "/backuper/backuper.sh" ]
