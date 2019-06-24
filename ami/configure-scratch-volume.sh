#!/usr/bin/env bash

# This script formats and mounts a device at /docker_scratch.

set -ex

update_packages() {
  sudo yum -y update
}

format_device() {
  sudo mkfs -t ext4 /dev/xvdb
}

mount_device() {
  sudo mkdir /docker_scratch
  sudo echo -e '/dev/xvdb /docker_scratch ext4 defaults 0 0' \
    | sudo tee -a /etc/fstab
  sudo mount -a
  sudo chmod 0777 /docker_scratch
}

stop_ecs() {
  sudo stop ecs
  sudo rm -rf /var/lib/ecs/data/ecs_agent_data.json
}

main() {
  update_packages
  format_device
  mount_device
  stop_ecs
}

main
