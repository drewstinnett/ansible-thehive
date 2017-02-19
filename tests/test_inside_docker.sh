#!/bin/bash
set -xe

distribution=$1
version=$2
module=ansible-cortex
if [ "${distribution}" == 'centos' ] && [ "${version}" == '7' ]; then
  init="/usr/lib/systemd/systemd"
  run_opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
elif [ "${distribution}" == 'centos' ] && [ "${version}" == '6' ]; then
  init="/sbin/init"
  run_opts=""
elif [ "$distribution" == "ubuntu" ] && [ ${version} == "14.04" ]; then
  distribution="ubuntu-upstart"
  init="/sbin/init"
  run_opts=""
elif [ "$distribution" == "ubuntu" ] && [ ${version} == "16.04" ]; then
  init="/bin/systemd"
  run_opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
fi


docker pull ${distribution}:${version}
docker build --rm=true --file=tests/Dockerfile.${distribution}-${version} --tag=${distribution}-${version}:ansible tests

container_id=$(mktemp)

# Run container in detached state
docker run --detach --volume="${PWD}":/etc/ansible/roles/${module}:ro ${run_opts} ${distribution}-${version}:ansible "${init}" > "${container_id}"

# Display Ansible version
docker exec --tty "$(cat ${container_id})" env TERM=xterm ansible --version

# Basic role syntax check
docker exec --tty "$(cat ${container_id})" env TERM=xterm ansible-playbook /etc/ansible/roles/${module}/tests/test.yml --syntax-check

# Run the role/playbook with ansible-playbook
docker exec --tty "$(cat ${container_id})" env TERM=xterm ansible-playbook /etc/ansible/roles/${module}/tests/test.yml

docker exec "$(cat ${container_id})" ansible-playbook /etc/ansible/roles/${module}/tests/test.yml \
 | grep -q 'changed=0.*failed=0' \
&& (echo 'Idempotence test: pass' && exit 0) \
|| (echo 'Idempotence test: fail' && exit 1) \

# Clean up
#docker stop "$(cat ${container_id})"
