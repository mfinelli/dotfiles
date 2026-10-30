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
vm-console() { virsh console "${1:?usage: vm-console NAME}"; }
vm-view()    { virt-viewer "${1:?usage: vm-view NAME}"; }

_vm_ssh_opts=(-o IdentitiesOnly=yes -o StrictHostKeyChecking=no
              -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR
              -o AddKeysToAgent=yes )
if [[ $(uname) == Darwin ]]; then
  _vm_ssh_opts=("${_vm_ssh_opts[@]}" -o UseKeychain=yes)
fi

_vm_target() {
  local ip
  ip=$(vm-ip "$1")
  [[ -n "$ip" ]] || { echo "no IP for '$1' (not running, or no lease yet)" >&2; return 1; }
  echo "mario@$ip"
}

# vm-scp NAME [scp options] SRC DST     (prefix paths on the VM with ':')
#
# vm-scp test1 ./notes.txt :/tmp/            # to the VM
# vm-scp test1 -r :~/results ./results       # from the VM
vm-scp() {
  local name="${1:?usage: vm-scp NAME [scp options] SRC DST   (VM paths start with ':')}" target a
  local args=()
  shift
  target=$(_vm_target "$name") || return 1
  for a in "$@"; do
    if [[ "$a" == :* ]]; then args+=("$target$a"); else args+=("$a"); fi
  done
  scp -J "$VM_HOST" -i "${VM_SSH_KEY%.pub}" "${_vm_ssh_opts[@]}" "${args[@]}"
}

# vm-rsync NAME [rsync options] SRC DST   (prefix paths on the VM with ':')
#
# vm-rsync test1 -avz ./project/ :~/project/
vm-rsync() {
  local name="${1:?usage: vm-rsync NAME [rsync options] SRC DST   (VM paths start with ':')}" target a
  local args=()
  shift
  target=$(_vm_target "$name") || return 1
  for a in "$@"; do
    if [[ "$a" == :* ]]; then args+=("$target$a"); else args+=("$a"); fi
  done
  rsync -e "ssh -J $VM_HOST -i ${VM_SSH_KEY%.pub} ${_vm_ssh_opts[*]}" "${args[@]}"
}

vm-ssh() {
  local target
  target=$(_vm_target "${1:?usage: vm-ssh NAME}") || return 1
  ssh -J "$VM_HOST" -i "${VM_SSH_KEY%.pub}" "${_vm_ssh_opts[@]}" "$target"
}

# Shutdown is asynchronous: `vm-stop` returns immediately. Check `vm-ls` or
# `virsh domstate NAME` to see when it reaches "shut off"
vm-stop()    { virsh shutdown "${1:?usage: vm-stop NAME}"; }
vm-kill()    { virsh destroy  "${1:?usage: vm-kill NAME}"; }   # hard power-off, keeps the VM
vm-start()   { virsh start    "${1:?usage: vm-start NAME}"; }
vm-reboot()  { virsh reboot   "${1:?usage: vm-reboot NAME}"; }
vm-reset()   { virsh reset    "${1:?usage: vm-reset NAME}"; }  # hard reset
vm-ls()      { virsh list --all; }

export VM_BASE_PREFIX="debian-13-base-"
export VM_DESKTOP_BASE_PREFIX="debian-13-generic-base-"

_vm_vols()  { virsh vol-list default | awk 'NR>2 && NF {print $1}'; }
_vm_base_prefixes() { printf '%s\n' "$VM_BASE_PREFIX" "$VM_DESKTOP_BASE_PREFIX"; }

# base volumes for one prefix, oldest first (literal prefix match)
_vm_bases_for() {
  _vm_vols | awk -v p="$1" 'index($0, p) == 1 && $0 ~ /\.qcow2$/' | sort
}

_vm_bases() {
  local p
  _vm_base_prefixes | while read -r p; do _vm_bases_for "$p"; done
}

# prints "overlay-volume base-volume" for every volume that has a backing file
_vm_backing_map() {
  local v p
  _vm_vols | while read -r v; do
    p=$(virsh vol-dumpxml --pool default "$v" 2>/dev/null |
      sed -n '/<backingStore>/,/<\/backingStore>/s:.*<path>\(.*\)</path>.*:\1:p' | head -n1)
    [[ -n "$p" ]] && echo "$v ${p##*/}"
  done
}

vm-images() {
  local map base size users
  map=$(_vm_backing_map)
  printf '%-48s %-10s %s\n' BASE_IMAGE DISK_USED USED_BY
  _vm_bases | while read -r base; do
    size=$(virsh vol-info --pool default "$base" | awk '/^Allocation/ {print $2 $3}')
    users=$(printf '%s\n' "$map" | awk -v b="$base" '$2==b {print $1}' | tr '\n' ' ')
    printf '%-48s %-10s %s\n' "$base" "$size" "${users:--}"
  done
}

# Usage:
# vm-images                    # list bases, their size on disk, and which volumes use them
# vm-images-clean              # dry run
# vm-images-clean -y           # delete the unused old ones, keeping the newest
# vm-images-clean -k 2 -y      # keep the two newest
_vm_images_clean_usage() {
  cat <<'EOF'
Usage: vm-images-clean [-k N] [-y]

Delete old base images that no volume depends on. Each flavor (cloud and
desktop base images) is handled separately.

  -k N   always keep the newest N images of each flavor (default: 1)
  -y     actually delete (default is a dry run that only prints)
  -h     show this help

Images that any overlay disk still uses as its backing file are never deleted.
EOF
}

vm-images-clean() {
  local OPTIND=1 opt keep=1 yes=0 map prefix base i
  while getopts "k:yh" opt; do
    case "$opt" in
      k) keep="$OPTARG" ;;
      y) yes=1 ;;
      h) _vm_images_clean_usage; return 0 ;;
      *) _vm_images_clean_usage >&2; return 2 ;;
    esac
  done

  map=$(_vm_backing_map)
  while read -r prefix; do
    [[ -z "$prefix" ]] && continue
    i=0
    while read -r base; do
      [[ -z "$base" ]] && continue
      i=$((i + 1))
      if (( i <= keep )); then
        echo "keep (newest $keep of ${prefix}*): $base"; continue
      fi
      if printf '%s\n' "$map" | awk -v b="$base" '$2==b {f=1} END {exit !f}'; then
        echo "keep (in use): $base"; continue
      fi
      if (( yes )); then
        echo "delete: $base"
        virsh vol-delete --pool default "$base" </dev/null
      else
        echo "would delete: $base"
      fi
    done <<< "$(_vm_bases_for "$prefix" | sort -r)"   # newest first
  done <<< "$(_vm_base_prefixes)"
}

# basenames of every disk/cdrom source attached to any defined domain
_vm_domain_disks() {
  local d
  virsh list --all --name | while read -r d; do
    [[ -z "$d" ]] && continue
    virsh domblklist --details "$d" 2>/dev/null </dev/null |
      awk 'NR>2 && NF && $4 != "-" {print $4}'
  done | sed 's:.*/::' | sort -u
}

_vm_orphans_usage() {
  cat <<'EOF'
Usage: vm-orphans [-y]

List volumes in the default pool that no VM uses: not a base image,
not attached to any defined VM, and not a backing file of another volume.
Typically leftovers from a failed or interrupted vm-new.

  -y   delete them (default is a dry run that only prints)
  -h   show this help

Do not run while vm-new is in progress: its volumes exist briefly
before the VM is defined and would look like orphans.
EOF
}

vm-orphans() {
  local OPTIND=1 opt yes=0 used backing bases v found=0
  while getopts "yh" opt; do
    case "$opt" in
      y) yes=1 ;;
      h) _vm_orphans_usage; return 0 ;;
      *) _vm_orphans_usage >&2; return 2 ;;
    esac
  done

  used=$(_vm_domain_disks)
  backing=$(_vm_backing_map | awk '{print $2}')
  bases=$(_vm_bases)

  while read -r v; do
    [[ -z "$v" ]] && continue
    printf '%s\n' "$bases"   | grep -Fxq -- "$v" && continue
    printf '%s\n' "$used"    | grep -Fxq -- "$v" && continue
    printf '%s\n' "$backing" | grep -Fxq -- "$v" && continue
    found=1
    if (( yes )); then
      echo "delete: $v"
      virsh vol-delete --pool default "$v" </dev/null
    else
      echo "orphan: $v"
    fi
  done <<< "$(_vm_vols)"

  (( found )) || echo "no orphans"
}
