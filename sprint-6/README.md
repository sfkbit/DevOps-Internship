# Sprint 6: Dynamic Configuration Management & Automated Host Discovery

## Overview

This project demonstrates dynamic host discovery and automated configuration management using Ansible and Docker. Containers are discovered automatically and grouped according to their Docker labels.

## Technologies Used

- Ansible
- Docker
- Ubuntu 24.04
- Python 3
- YAML

## Project Structure

- `Dockerfile` — builds the Ansible target container image.
- `ansible.cfg` — Ansible configuration.
- `inventory.docker.yml` — dynamic Docker inventory and filtering.
- `test-playbook.yml` — configures web containers.
- `production-playbook.yml` — configures production containers.
- `proof/` — screenshots showing tests and successful execution.

## Target Containers

| Container | Environment | Role |
|---|---|---|
| `s6-dev-web` | dev | web |
| `s6-prod-web` | prod | web |
| `s6-prod-db` | prod | db |

## Dynamic Inventory

The `community.docker.docker_containers` inventory plugin discovers the three Sprint 6 containers. The inventory filters out unrelated Docker containers and creates groups based on their labels:

- `env_dev`
- `env_prod`
- `role_web`
- `role_db`

## Playbooks

- `test-playbook.yml` targets `role_web` and configures the MOTD message.
- `production-playbook.yml` targets `env_prod` and configures the production warning message.

## Validation Results

- Dynamic inventory lists only the three Sprint 6 containers.
- Inventory groups were verified using `ansible-inventory --graph`.
- Ansible ping succeeded on all three containers.
- Both playbooks completed with zero failed or unreachable hosts.

## Implementation Note

This project uses local Docker containers instead of cloud virtual machines. Ansible uses the Docker connection plugin to execute tasks inside the containers without publishing SSH ports to the host.

The project demonstrates host discovery and configuration management. Container provisioning and cloud infrastructure creation are outside the current implementation.

## Conclusion

Sprint 6 demonstrates automated Docker host discovery, label-based grouping, and environment-specific configuration using Ansible.
