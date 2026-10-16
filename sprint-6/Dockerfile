FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -o Acquire::ForceIPv4=true update \
    && apt-get -o Acquire::ForceIPv4=true install -y \
       openssh-server python3 sudo \
    && mkdir -p /run/sshd \
    && useradd -m -s /bin/bash ansible \
    && echo 'ansible: Sprint6LabPass123!' | chpasswd \
    && echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible \
    && chmod 440 /etc/sudoers.d/ansible \
    && mkdir -p /home/ansible/.ssh \
    && chown -R ansible:ansible /home/ansible/.ssh \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
