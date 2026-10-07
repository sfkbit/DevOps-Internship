# Sprint 3 - Ansible Server Hardening

## Overview

This project implements configuration management and essential security hardening on an Ubuntu server using Ansible.

The main objective of Sprint 3 is to automate common server security configurations using an Ansible playbook.

For this implementation, an Ubuntu 24.04 Docker container is used as the managed node, while Ansible is executed from WSL Ubuntu as the controller.

The playbook automates:

- SSH hardening
- UFW firewall configuration
- fail2ban SSH protection
- Idempotent configuration management
- SSH key-based access

---

## Architecture

The project uses Ansible to connect to an Ubuntu Docker container through SSH and apply the required security configuration.

~~~text
                    WSL Ubuntu
                 Ansible Controller
                        |
                        | SSH
                        |
                        v
              Ubuntu 24.04 Container
                  Managed Node
                        |
          +-------------+-------------+
          |             |             |
         SSH           UFW         fail2ban
~~~

The Docker container provides a local Ubuntu server environment for testing the Ansible configuration.

The SSH connection uses:

~~~text
Host: 127.0.0.1
Port: 2222
User: ansible
Authentication: SSH key
~~~

---

## Security Requirements

The playbook implements the following security requirements:

### SSH Hardening

- Disable root SSH login
- Disable SSH password authentication
- Enable SSH public key authentication

### UFW Firewall

- Deny incoming traffic by default
- Allow SSH on port 22
- Allow HTTP on port 80
- Allow HTTPS on port 443
- Allow outgoing traffic

### fail2ban

- Install fail2ban
- Enable the SSH jail
- Protect SSH against repeated failed login attempts
- Configure ban time and retry limits

### Idempotency

The playbook should not make unnecessary changes when it is executed again.

A successful second run should show:

~~~text
changed=0
failed=0
unreachable=0
~~~

---

## Project Structure

~~~text
sprint-3/
├── README.md
├── ansible.cfg
├── inventory.ini
├── site.yml
└── proof/
    ├── 01-first-run.png
    ├── 02-idempotency.png
    ├── 03-ufw-status.png
    ├── 04-ssh-hardening.png
    ├── 05-fail2ban-status.png
    └── 06-ssh-key-login.png
~~~

---

## Requirements

The following tools are required:

- Ubuntu / WSL
- Docker
- Ansible
- SSH

Versions used during development:

~~~text
Ansible Core: 2.16.3
Docker: 29.1.3
~~~

The required Ansible collection was installed using:

~~~bash
ansible-galaxy collection install community.general
~~~

---

## Docker Managed Node

The Ubuntu managed node was created using Docker.

~~~bash
docker run -d \
  --name sprint3-ubuntu \
  --dns 8.8.8.8 \
  -p 2222:22 \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  ubuntu:24.04 \
  sleep infinity
~~~

The `NET_ADMIN` and `NET_RAW` capabilities allow UFW and its required networking operations to work inside the container.

SSH, sudo and Python were installed inside the container.

~~~bash
apt install -y openssh-server sudo python3
~~~

An Ansible user was created and given sudo access.

~~~bash
useradd -m -s /bin/bash ansible
usermod -aG sudo ansible
~~~

SSH was started using:

~~~bash
service ssh start
~~~

---

## SSH Key Setup

An Ed25519 SSH key was generated on the Ansible controller.

~~~bash
ssh-keygen -t ed25519 -f ~/.ssh/sprint3_ansible
~~~

The public key was added to the `ansible` user's `authorized_keys` file inside the Ubuntu container.

The private SSH key is stored on the controller and is not included in this repository.

SSH key login was tested successfully using:

~~~bash
ssh -i ~/.ssh/sprint3_ansible -p 2222 ansible@localhost
~~~

---

## Inventory

The `inventory.ini` file tells Ansible which server to connect to and how to connect to it.

~~~ini
[ubuntu]
sprint3 ansible_host=127.0.0.1 ansible_port=2222 ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/sprint3_ansible
~~~

### Inventory Configuration

~~~text
ubuntu
    Ansible host group

sprint3
    Managed node name

ansible_host
    Server address

ansible_port
    SSH port

ansible_user
    SSH user

ansible_ssh_private_key_file
    SSH private key used for authentication
~~~

The sudo password is not stored in the inventory file.

It is entered during playbook execution using:

~~~bash
--ask-become-pass
~~~

---

## Ansible Configuration

The `ansible.cfg` file contains:

~~~ini
[defaults]
host_key_checking = False
~~~

This is used for the local Docker testing environment.

---

## Playbook

The main Ansible playbook is:

~~~text
site.yml
~~~

The playbook targets the `ubuntu` inventory group:

~~~yaml
hosts: ubuntu
~~~

Administrative privileges are enabled using:

~~~yaml
become: true
~~~

The playbook contains tasks for:

- Installing UFW and fail2ban
- SSH hardening
- UFW firewall configuration
- fail2ban SSH configuration
- Starting and enabling fail2ban

---

## SSH Hardening

The playbook configures SSH with the following settings:

~~~text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
~~~

This means:

- Root cannot directly log in through SSH.
- SSH password authentication is disabled.
- SSH key authentication is enabled.

The effective SSH configuration was verified after running the playbook.

---

## UFW Firewall

UFW is configured as the firewall.

The default incoming policy is:

~~~text
deny
~~~

The default outgoing policy is:

~~~text
allow
~~~

The following ports are explicitly allowed:

~~~text
22  - SSH
80  - HTTP
443 - HTTPS
~~~

This means incoming connections are blocked unless they are explicitly allowed by the firewall rules.

---

## fail2ban

fail2ban is installed and configured to protect SSH.

The SSH jail uses:

~~~text
bantime = 10m
findtime = 10m
maxretry = 5
~~~

This means repeated failed SSH authentication attempts can result in the source IP being temporarily banned.

The `sshd` jail was verified successfully after configuration.

---

## Running the Playbook

Navigate to the Sprint 3 directory:

~~~bash
cd ~/DevOps-Internship/sprint-3
~~~

Run the playbook:

~~~bash
ansible-playbook -i inventory.ini site.yml --ask-become-pass
~~~

Enter the sudo password when prompted.

---

## Testing Ansible Connectivity

Ansible connectivity can be tested using:

~~~bash
ansible -i inventory.ini ubuntu -m ping
~~~

A successful connection returns:

~~~text
pong
~~~

---

## Verification

### UFW Status

Check the firewall using:

~~~bash
docker exec sprint3-ubuntu ufw status
~~~

The expected result is:

~~~text
Status: active
~~~

The firewall should allow ports:

~~~text
22
80
443
~~~

### SSH Configuration

The effective SSH configuration can be checked using:

~~~bash
ansible -i inventory.ini ubuntu -b -m shell -a "sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication'"
~~~

Expected output:

~~~text
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
~~~

### fail2ban

Check the SSH jail using:

~~~bash
docker exec sprint3-ubuntu fail2ban-client status sshd
~~~

The output should show:

~~~text
Status for the jail: sshd
~~~

### SSH Key Login

Test SSH key-based access using:

~~~bash
ssh -i ~/.ssh/sprint3_ansible -p 2222 ansible@localhost
~~~

A successful login confirms that SSH key authentication is working.

---

## Idempotency Testing

The playbook was executed once to apply the required configuration.

It was then executed again without changing the configuration.

The second execution returned:

~~~text
changed=0
failed=0
unreachable=0
~~~

This confirms that the playbook is idempotent and does not make unnecessary changes when the server is already configured correctly.

---

## Proof of Work

The `proof` directory contains screenshots demonstrating the implementation and verification.

### Initial Playbook Run

`01-first-run.png`

Shows the successful initial execution of the Ansible playbook and the configuration changes applied to the Ubuntu node.

### Idempotency

`02-idempotency.png`

Shows the second playbook execution with:

~~~text
changed=0
~~~

### UFW Status

`03-ufw-status.png`

Shows that UFW is active and that ports 22, 80 and 443 are allowed.

### SSH Hardening

`04-ssh-hardening.png`

Shows the configured SSH security settings.

### fail2ban

`05-fail2ban-status.png`

Shows the active SSH fail2ban jail.

### SSH Key Login

`06-ssh-key-login.png`

Shows successful SSH login using the configured SSH key.

---

## Design Decisions

### Local Docker Implementation

A Docker Ubuntu container was used instead of a cloud server.

This provides a local and repeatable environment for testing the Ansible playbook without requiring an AWS or GCP instance.

### SSH Key Authentication

SSH keys are used instead of password-based SSH authentication.

This supports the required SSH hardening configuration.

### Idempotent Configuration

Ansible modules are used so that the configuration can be applied repeatedly without making unnecessary changes.

### Separate Inventory and Playbook

The inventory defines the target server and connection details, while `site.yml` contains the configuration tasks.

This keeps the server information separate from the configuration logic.

---

## Cleanup

The Docker container can be removed after testing using:

~~~bash
docker rm -f sprint3-ubuntu
~~~

---

## Key Concepts Covered

This sprint covers:

- Ansible inventory
- Ansible playbooks
- Ansible tasks
- SSH connections
- SSH key authentication
- `become` / sudo
- Server hardening
- UFW firewall
- fail2ban
- Idempotency
- Configuration management
- Local Docker-based server configuration

---

## Sprint Status

Sprint 3 focuses on Configuration Management and Server Hardening using Ansible.

The Ubuntu node has been configured and tested with:

- SSH hardening
- UFW firewall rules
- fail2ban SSH protection
- SSH key-based access
- Idempotent Ansible execution

The source code, documentation and proof of work are included under the `sprint-3` directory.
