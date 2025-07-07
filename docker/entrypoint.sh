#!/bin/bash

USER_NAME=${ENTREPRISE:-entreprise}
USER_PASS=${PASSWORD:-motdepasse}

if ! id "$USER_NAME" &>/dev/null; then
    useradd -m "$USER_NAME"
    echo "$USER_NAME:$USER_PASS" | chpasswd
    adduser "$USER_NAME" sudo
fi

/usr/sbin/sshd -D