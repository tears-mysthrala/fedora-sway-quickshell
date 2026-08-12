#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
dir="$ROOT/.vm"
mkdir -p "$dir"

key="$dir/acceptance_ed25519"
password_file="$dir/demo-password"
[[ -f $key ]] || ssh-keygen -q -t ed25519 -N '' -C fedora-sway-acceptance -f "$key"
if [[ ! -s $password_file ]]; then
  umask 077
  openssl rand -base64 24 >"$password_file"
fi
password=$(<"$password_file")
hash=$(openssl passwd -6 "$password")
public_key=$(<"$key.pub")

cat >"$dir/acceptance.ks" <<EOF
text
lang en_US.UTF-8
keyboard us
timezone Europe/Madrid --utc
network --bootproto=dhcp --device=link --activate --hostname=fedora-sway-demo
rootpw --lock
user --name=demo --groups=wheel --password='$hash' --iscrypted
sshkey --username=demo "$public_key"
firewall --enabled --service=ssh
selinux --enforcing
services --enabled=sshd,NetworkManager,firewalld
zerombr
clearpart --all --initlabel
autopart --type=lvm
reboot

%packages
@core
NetworkManager
firewalld
git
openssh-server
sudo
%end
EOF
chmod 600 "$dir/acceptance.ks" "$password_file" "$key"
printf 'Prepared ignored acceptance credentials and kickstart under %s\n' "$dir"
