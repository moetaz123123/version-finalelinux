FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y openssh-server sudo && \
    mkdir /var/run/sshd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]