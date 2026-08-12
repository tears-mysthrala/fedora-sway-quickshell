#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
PROJECT_ROOT=$ROOT
source "$ROOT/scripts/lib/common.sh"

name="fedora-sway-demo-f${SUPPORTED_FEDORA_RELEASE}"
vm_dir="$ROOT/.vm"
iso="$vm_dir/Fedora-Server-dvd-x86_64-${SUPPORTED_FEDORA_RELEASE}-1.7.iso"
checksum="$vm_dir/Fedora-Server-${SUPPORTED_FEDORA_RELEASE}-1.7-x86_64-CHECKSUM"
disk="$vm_dir/$name.qcow2"
kickstart="$vm_dir/acceptance.ks"
dry_run=false
[[ ${1:-} == --dry-run ]] && dry_run=true

if $dry_run; then
  printf 'VM: %s\nISO: %s\nAction: verify checksum, create dedicated qcow2, run virt-install\n' "$name" "$(basename "$iso")"
  exit 0
fi

[[ -f $iso && -f $checksum && -f $kickstart ]] || { printf 'Fetch media and run prepare-kickstart.sh first.\n' >&2; exit 1; }
(cd "$vm_dir" && sha256sum --ignore-missing -c "$(basename "$checksum")")
[[ ! -e $disk ]] || { printf 'Refusing to overwrite %s\n' "$disk" >&2; exit 1; }
! virsh dominfo "$name" >/dev/null 2>&1 || { printf 'Refusing to replace existing VM %s\n' "$name" >&2; exit 1; }

qemu-img create -f qcow2 "$disk" 28G
virt-install \
  --name "$name" \
  --memory 3072 \
  --vcpus 2 \
  --cpu host-passthrough \
  --disk "path=$disk,format=qcow2,bus=virtio" \
  --location "$iso" \
  --initrd-inject "$kickstart" \
  --extra-args 'inst.ks=file:/acceptance.ks console=ttyS0,115200n8 serial' \
  --network network=default,model=virtio \
  --graphics vnc,listen=127.0.0.1 \
  --video virtio \
  --channel spicevmc \
  --os-variant fedora-unknown \
  --boot uefi \
  --console pty,target.type=serial \
  --noautoconsole

printf 'Created %s. Open it with: virt-viewer %s\n' "$name" "$name"
