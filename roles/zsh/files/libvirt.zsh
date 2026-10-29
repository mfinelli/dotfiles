export VM_HOST="mario@iris.mario.casa"
export LIBVIRT_DEFAULT_URI="qemu+ssh://${VM_HOST}/system"
export VM_SSH_KEY="$HOME/.ssh/home.pub"
export VM_BASE_PREFIX="debian-13-"
export VM_OSINFO="${VM_OSINFO:-debian13}"

_vm_new_usage() {
  cat <<'EOF'
Usage: vm-new [options] NAME

Create an ephemeral VM on the libvirt host from the newest Debian base image.

Options:
  -m MB     memory in MiB            (default: 2048)
  -c N      vCPUs                    (default: 2)
  -d GB     disk size in GiB         (default: 20)
  -b FILE   base image volume name   (default: newest "$VM_BASE_PREFIX*.qcow2" in the pool)
  -n NET    libvirt network          (default: isolated-nat)
  -u        boot with UEFI instead of BIOS
  -h        show this help

Environment:
  LIBVIRT_DEFAULT_URI, VM_HOST, VM_SSH_KEY, VM_BASE_PREFIX,
  VM_CONSOLE_PASSWORD (optional), VM_OSINFO (optional)

Related commands: vm-rm NAME, vm-ip NAME, vm-ssh NAME, vm-console NAME, vm-view NAME
EOF
}

vm-new() {
  local OPTIND=1 opt
  local mem=2048 cpus=2 disk=20 base="" net=isolated-nat uefi=0
  local pool=default

  while getopts "m:c:d:b:n:uh" opt; do
    case "$opt" in
      m) mem="$OPTARG" ;;
      c) cpus="$OPTARG" ;;
      d) disk="$OPTARG" ;;
      b) base="$OPTARG" ;;
      n) net="$OPTARG" ;;
      u) uefi=1 ;;
      h) _vm_new_usage; return 0 ;;
      *) _vm_new_usage >&2; return 2 ;;
    esac
  done
  shift $((OPTIND - 1))

  local name="$1"
  if [[ -z "$name" ]]; then _vm_new_usage >&2; return 2; fi

  if [[ -z "$base" ]]; then
    base=$(virsh vol-list "$pool" | awk -v p="$VM_BASE_PREFIX" \
      '$1 ~ "^" p ".*\\.qcow2$" {print $1}' | sort | tail -n1)
    if [[ -z "$base" ]]; then
      echo "vm-new: no base image matching ${VM_BASE_PREFIX}*.qcow2 in pool '$pool'" >&2
      return 1
    fi
  fi
  echo "Using base image: $base"

  local tmp rc pw_line mb boot_args=()
  tmp=$(mktemp -d) || return 1
  (( uefi )) && boot_args=(--boot uefi)

  pw_line="lock_passwd: true"
  if [[ -n "$VM_CONSOLE_PASSWORD" ]]; then
    pw_line="lock_passwd: false
    plain_text_passwd: $VM_CONSOLE_PASSWORD"
  fi

  cat > "$tmp/user-data" <<EOF
#cloud-config
users:
  - name: mario
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    $pw_line
    ssh_authorized_keys:
      - $(cat "$VM_SSH_KEY")
package_update: true
packages: [qemu-guest-agent]
EOF

  cat > "$tmp/meta-data" <<EOF
instance-id: $name
local-hostname: $name
EOF

  mkisofs -quiet -output "$tmp/seed.iso" -volid cidata -joliet -rock \
    "$tmp/user-data" "$tmp/meta-data" || { rm -rf "$tmp"; return 1; }

  mb=$(( $(wc -c < "$tmp/seed.iso") / 1048576 + 1 ))

  virsh vol-create-as "$pool" "$name-seed.iso" "${mb}M" --format raw &&
  virsh vol-upload --pool "$pool" "$name-seed.iso" "$tmp/seed.iso" &&
  virsh vol-create-as "$pool" "$name.qcow2" "${disk}G" --format qcow2 \
    --backing-vol "$base" --backing-vol-format qcow2 &&
  virt-install --name "$name" --memory "$mem" --vcpus "$cpus" \
    --osinfo "$VM_OSINFO" --import "${boot_args[@]}" \
    --disk "vol=$pool/$name.qcow2" \
    --disk "vol=$pool/$name-seed.iso,device=cdrom" \
    --network "network=$net" \
    --graphics vnc --noautoconsole
  rc=$?
  rm -rf "$tmp"
  return $rc
}

vm-rm() {
  local name="${1:?usage: vm-rm NAME}" nvram=()
  virsh dumpxml "$name" 2>/dev/null | grep -q '<nvram' && nvram=(--nvram)
  virsh destroy "$name" 2>/dev/null
  virsh undefine "$name" --remove-all-storage "${nvram[@]}"
}

vm-ip()      { virsh domifaddr "${1:?usage: vm-ip NAME}" | awk '/ipv4/ {split($4,a,"/"); print a[1]}'; }
vm-ssh()     { ssh -J "$VM_HOST" "mario@$(vm-ip "${1:?usage: vm-ssh NAME}")"; }
vm-console() { virsh console "${1:?usage: vm-console NAME}"; }
vm-view()    { virt-viewer "${1:?usage: vm-view NAME}"; }

# Shutdown is asynchronous: `vm-stop` returns immediately. Check `vm-ls` or
# `virsh domstate NAME` to see when it reaches "shut off"
vm-stop()    { virsh shutdown "${1:?usage: vm-stop NAME}"; }
vm-kill()    { virsh destroy  "${1:?usage: vm-kill NAME}"; }   # hard power-off, keeps the VM
vm-start()   { virsh start    "${1:?usage: vm-start NAME}"; }
vm-reboot()  { virsh reboot   "${1:?usage: vm-reboot NAME}"; }
vm-reset()   { virsh reset    "${1:?usage: vm-reset NAME}"; }  # hard reset
vm-ls()      { virsh list --all; }
