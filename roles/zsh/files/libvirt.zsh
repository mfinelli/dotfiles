export VM_HOST="mario@iris.mario.casa"
export LIBVIRT_DEFAULT_URI="qemu+ssh://${VM_HOST}/system"
export VM_SSH_KEY="$HOME/.ssh/home.pub"
export VM_OSINFO="${VM_OSINFO:-debian13}"
export VM_BASE_PREFIX="debian-13-base-"
export VM_DESKTOP_BASE_PREFIX="debian-13-generic-base-"
export VM_CONSOLE_PASSWORD=123 # ephemeral, throwaway vm so this is fine
export VM_VNC_PASSWORD=desktop1 # this is fine auth already happened over ssh
export VM_REMOTE_ROOT="${VM_REMOTE_ROOT:-src}" # projects live in ~/src/NAME in the guest

# Secrets pushed into a guest by vm-provision, at /dev/shm/secrets/<name>.
# agentvm.bash consumes and then removes them.
export VM_SECRET_DIR=/dev/shm/secrets
# Directory of GPG-encrypted secrets, one file per secret, named <secret>.asc
# (or .gpg).
export VM_SECRET_SRC="${VM_SECRET_SRC:-$HOME/.local/share/vm-secrets}"

_vm_new_usage() {
  cat <<'EOF'
Usage: vm-new [options] NAME

Create an ephemeral VM on the libvirt host from the newest Debian base image.

Options:
  -m MB     memory in MiB            (default: 2048, desktop: 4096)
  -c N      vCPUs                    (default: 2, desktop: 2)
  -d GB     disk size in GiB         (default: 20, desktop: 30)
  -b FILE   base image volume name   (default: newest matching image in the pool)
  -n NET    libvirt network          (default: isolated-nat)
  -u        boot with UEFI instead of BIOS
  -D        desktop guest: full-kernel image, GNOME, GDM auto-login, virtio video
  -h        show this help

Environment:
  LIBVIRT_DEFAULT_URI, VM_HOST, VM_SSH_KEY, VM_BASE_PREFIX,
  VM_DESKTOP_BASE_PREFIX, VM_OSINFO, VM_CONSOLE_PASSWORD (optional)

Related commands: vm-rm, vm-ip, vm-ssh, vm-scp, vm-rsync, vm-console, vm-vnc,
                  vm-provision
EOF
}

vm-new() {
  local OPTIND=1 opt
  local mem="" cpus="" disk="" base="" net=isolated-nat uefi=0 desktop=0
  local pool=default

  while getopts "m:c:d:b:n:uDh" opt; do
    case "$opt" in
      m) mem="$OPTARG" ;;
      c) cpus="$OPTARG" ;;
      d) disk="$OPTARG" ;;
      b) base="$OPTARG" ;;
      n) net="$OPTARG" ;;
      u) uefi=1 ;;
      D) desktop=1 ;;
      h) _vm_new_usage; return 0 ;;
      *) _vm_new_usage >&2; return 2 ;;
    esac
  done
  shift $((OPTIND - 1))

  local name="$1"
  if [[ -z "$name" ]]; then _vm_new_usage >&2; return 2; fi

  if (( desktop )); then
    : "${mem:=4096}" "${cpus:=2}" "${disk:=30}"
  else
    : "${mem:=2048}" "${cpus:=2}" "${disk:=20}"
  fi

  if [[ -z "$base" ]]; then
    local prefix="$VM_BASE_PREFIX"
    (( desktop )) && prefix="$VM_DESKTOP_BASE_PREFIX"
    base=$(_vm_bases_for "$prefix" | tail -n1)
    if [[ -z "$base" ]]; then
      echo "vm-new: no base image matching ${prefix}*.qcow2 in pool '$pool'" >&2
      return 1
    fi
  fi
  echo "Using base image: $base"

  local tmp rc pw_line pkgs mb
  local -a boot_args video_args
  local desktop_ud=""
  tmp=$(mktemp -d) || return 1
  (( uefi )) && boot_args=(--boot uefi)

  pkgs="qemu-guest-agent, rsync"
  if (( desktop )); then
    pkgs="$pkgs, gnome-core, gdm3"
    video_args=(--video virtio)
    desktop_ud=$(cat <<'EOF'
write_files:
  - path: /usr/local/sbin/setup-desktop
    permissions: "0755"
    content: |
      #!/bin/sh
      set -e
      f=/etc/gdm3/daemon.conf
      [ -f "$f" ] || f=/etc/gdm3/custom.conf
      grep -q '^\[daemon\]' "$f" 2>/dev/null || printf '[daemon]\n' >> "$f"
      sed -i '/^\[daemon\]/a AutomaticLoginEnable=true\nAutomaticLogin=mario' "$f"
      systemctl set-default graphical.target
      systemctl enable gdm3
runcmd:
  - /usr/local/sbin/setup-desktop
power_state:
  mode: reboot
  message: desktop setup finished, rebooting into the graphical session
  timeout: 30
  condition: true
EOF
)
  fi

  pw_line="lock_passwd: true"
  if [[ -n "$VM_CONSOLE_PASSWORD" ]]; then
    # quote it: cloud-init's schema rejects a bare number here
    pw_line="lock_passwd: false
    plain_text_passwd: \"$VM_CONSOLE_PASSWORD\""
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
packages: [$pkgs]
$desktop_ud
EOF

  cat > "$tmp/meta-data" <<EOF
instance-id: $name
local-hostname: $name
EOF

  mkisofs -quiet -output "$tmp/seed.iso" -volid cidata -joliet -rock \
    "$tmp/user-data" "$tmp/meta-data" || { rm -rf "$tmp"; return 1; }

  mb=$(( $(wc -c < "$tmp/seed.iso") / 1048576 + 1 ))

  local graphics="vnc"
  [[ -n "$VM_VNC_PASSWORD" ]] && graphics="vnc,password=$VM_VNC_PASSWORD"

  virsh vol-create-as "$pool" "$name-seed.iso" "${mb}M" --format raw &&
  virsh vol-upload --pool "$pool" "$name-seed.iso" "$tmp/seed.iso" &&
  virsh vol-create-as "$pool" "$name.qcow2" "${disk}G" --format qcow2 \
    --backing-vol "$base" --backing-vol-format qcow2 &&
  virt-install --name "$name" --memory "$mem" --vcpus "$cpus" \
    --osinfo "$VM_OSINFO" --import "${boot_args[@]}" "${video_args[@]}" \
    --disk "vol=$pool/$name.qcow2" \
    --disk "vol=$pool/$name-seed.iso,device=cdrom" \
    --network "network=$net" \
    --graphics "$graphics" --noautoconsole
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

vm-ip() {
  local name="${1:?usage: vm-ip NAME}" addr
  # addresses actually configured in the guest (needs qemu-guest-agent)
  addr=$(virsh domifaddr "$name" --source agent 2>/dev/null </dev/null |
    awk '$3=="ipv4" && $4 !~ /^127\./ && $4 !~ /^169\.254\./ {split($4,a,"/"); print a[1]; exit}')
  # fall back to DHCP leases
  [[ -n "$addr" ]] || addr=$(virsh domifaddr "$name" 2>/dev/null </dev/null |
    awk '/ipv4/ {split($4,a,"/"); print a[1]; exit}')
  echo "$addr"
}

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

# ssh to an already-resolved target (the "mario@ip" that _vm_target prints)
_vm_ssh_target() {
  local target="$1"; shift
  ssh -J "$VM_HOST" -i "${VM_SSH_KEY%.pub}" "${_vm_ssh_opts[@]}" "$target" "$@"
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
  target=$(_vm_target "${1:?usage: vm-ssh NAME [command...]}") || return 1
  shift
  _vm_ssh_target "$target" "$@"
}

_vm_provision_usage() {
  cat <<'EOF'
Usage: vm-provision NAME

Push the operator's secrets into a running VM's /dev/shm/secrets, where the
agentvm setup script consumes and then removes them. Run this after the VM has
booted (vm-ip must return an address) and before running the setup script.

Secrets come from $VM_SECRET_SRC, one GPG-encrypted file per secret:
git-name.asc, git-email.asc, ... The filename without its .asc/.gpg suffix is
the secret name.

  VM_SECRET_SRC   default: ~/.local/share/vm-secrets
  VM_SECRET_GPG   default: gpg (override to pin a homedir or binary)

Each secret is decrypted on the fly, piped over ssh, and never written to the
guest's disk: /dev/shm is RAM, and the guest script deletes them after use.
EOF
}

# secret name for a file in the secrets directory: basename minus .asc/.gpg
_vm_secret_name() {
  local n=${1##*/}
  n=${n%.asc}
  n=${n%.gpg}
  print -r -- "$n"
}

vm-provision() {
  local OPTIND=1 opt
  while getopts "h" opt; do
    case "$opt" in
      h) _vm_provision_usage; return 0 ;;
      *) _vm_provision_usage >&2; return 2 ;;
    esac
  done
  shift $((OPTIND - 1))

  local name="${1:?usage: vm-provision NAME}"
  local target f s pushed=0 rc
  local gpg=${VM_SECRET_GPG:-gpg}

  if [[ ! -d $VM_SECRET_SRC ]]; then
    echo "vm-provision: no secrets directory at $VM_SECRET_SRC" >&2
    return 1
  fi

  target=$(_vm_target "$name") || return 1

  # 0700 on the directory: /dev/shm is 1777, so a world-readable directory
  # would expose every secret to all users in the guest.
  ssh -J "$VM_HOST" -i "${VM_SSH_KEY%.pub}" "${_vm_ssh_opts[@]}" "$target" \
    "umask 077 && mkdir -p '$VM_SECRET_DIR' && chmod 700 '$VM_SECRET_DIR'" || return 1

  # N glob qualifier: expand to nothing instead of erroring when there are no
  # .asc/.gpg files, so the "no secrets found" message below can be reached.
  for f in "$VM_SECRET_SRC"/*.asc(N) "$VM_SECRET_SRC"/*.gpg(N); do
    [[ -f $f ]] || continue
    s=$(_vm_secret_name "$f")

    # decrypt locally and stream: no plaintext lands on the operator's disk,
    # and ssh's remote umask 077 keeps the file 0600 as it is created.
    #
    # The exit status is taken from pipestatus rather than $?, because a
    # pipeline reports only its last command unless pipefail is set, and this
    # file is sourced into an interactive shell whose options vary. A missing
    # or locked gpg key must abort, not leave an empty secret behind.
    # pipestatus has to be captured as the very next statement: any command in
    # between (even a [[ ]] test) resets it.
    $gpg --batch --quiet --decrypt "$f" |
      ssh -J "$VM_HOST" -i "${VM_SSH_KEY%.pub}" "${_vm_ssh_opts[@]}" "$target" \
        "umask 077 && cat > '$VM_SECRET_DIR/$s'"
    local -a st=("${pipestatus[@]}")

    if (( st[1] != 0 || st[2] != 0 )); then
      echo "vm-provision: failed to provision $s (is your gpg key unlocked?)" >&2
      # drop any empty or partial file the failed stream created
      ssh -J "$VM_HOST" -i "${VM_SSH_KEY%.pub}" "${_vm_ssh_opts[@]}" "$target" \
        "rm -f '$VM_SECRET_DIR/$s'"
      return 1
    fi
    pushed=$((pushed + 1))
    echo "  $s"
  done

  if (( pushed == 0 )); then
    echo "vm-provision: no .asc/.gpg secrets found in $VM_SECRET_SRC" >&2
    return 1
  fi

  ssh -J "$VM_HOST" -i "${VM_SSH_KEY%.pub}" "${_vm_ssh_opts[@]}" "$target" \
    "chmod 600 '$VM_SECRET_DIR'/*" || return 1

  echo "provisioned $pushed secret(s) into $name:$VM_SECRET_DIR"
}

vm-vnc() {
  local name="${1:?usage: vm-vnc NAME}" d port lport pid
  d=$(virsh vncdisplay "$name") || return 1
  [[ -n "$d" ]] || { echo "no VNC display for '$name' (is it running?)" >&2; return 1; }
  port=$((5900 + ${d##*:}))
  lport=$((15000 + port - 5900))
  ssh -N -L "$lport:127.0.0.1:$port" -o ExitOnForwardFailure=yes "$VM_HOST" &
  pid=$!
  sleep 2

  if [[ $(uname) == Darwin ]]; then
    open "vnc://localhost:$lport"
  elif command -v vncviewer >/dev/null; then
    vncviewer "localhost::$lport" &
  elif command -v remmina >/dev/null; then
    remmina -c "vnc://localhost:$lport" &
  else
    xdg-open "vnc://localhost:$lport"
  fi

  echo "Tunnel open on localhost:$lport. Press Enter to close it."
  read -r
  kill "$pid"
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

_vm_gitinfo_script() {
  cat <<'EOF'
dir="$1"
cd "$dir" 2>/dev/null || { echo "err=no such directory: $dir"; exit 0; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "err=not a git repository: $dir"; exit 0; }
[ -z "$(git rev-parse --show-prefix)" ] || { echo "err=not the top level of a git repository: $dir"; exit 0; }
echo "branch=$(git symbolic-ref --short -q HEAD || echo DETACHED)"
echo "head=$(git rev-parse -q --verify HEAD || echo NONE)"
echo "roots=$(git rev-list --max-parents=0 HEAD 2>/dev/null | sort | tr '\n' ' ')"
echo "shallow=$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)"
echo "origin=$(git remote get-url origin 2>/dev/null | sed -E 's#^(https?|ssh|git)://##; s#^[^@/]*@##; s#:#/#; s#\.git$##; s#/$##')"
echo "dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
EOF
}

_vm_kv() { printf '%s\n' "$2" | awk -F= -v k="$1" '$1==k {sub(/^[^=]*=/, ""); print; exit}'; }

# paths git ignores locally (all sources), anchored for rsync
_vm_local_ignored() {
  git -C "$1" ls-files --others --ignored --exclude-standard --directory | sed 's#^#/#'
}

_vm_sync_usage() {
  cat <<'EOF'
Usage: vm-sync [options] NAME

One-way sync of a git project from the guest NAME into a local clone.
Copies the working tree only (intentionally skips .git) and mirrors file
additions and deletions.

Run it from inside the local repository. The project is chosen by that repo's
directory name: from ~/code/myproj, it syncs ~/src/myproj on the VM into
~/code/myproj. VM_NAME is only the VM to connect to.

Examples:
  cd ~/code/myproj && vm-sync omp-project      # preview, then confirm
  vm-sync -n omp-project                       # dry run only
  vm-sync -r src/other omp-project             # remote dir has a different name
  vm-sync -l ~/code/myproj omp-project         # without cd-ing first

Options:
  -l DIR   local repository top level   (default: the repo containing the
           current directory)
  -r DIR   project directory in the guest, relative to its home
           (default: $VM_REMOTE_ROOT/<basename of the local repo>, i.e.
           src/NAME)
  -n       dry run: show what would change and stop
  -y       apply without asking for confirmation
  -k       keep local files that don't exist in the guest (no deletions)
  -f       proceed even if the local working tree has uncommitted changes
  -h       show this help

Refuses to run unless both sides are the same repository (same initial commits,
or same origin URL when a clone is shallow) on the same branch.
Anything git ignores locally, and anything a .gitignore matches, is neither
copied nor deleted.
EOF
}

# Notes:
#  - Files and directories INSIDE the project can have any name, including spaces.
#  - The project directory paths themselves (-l, -r, the default remote path) must
#    not contain spaces or single quotes: the remote path goes through the remote
#    shell, and older rsync versions (such as macOS's bundled one) word-split it.
#    The path in VM_SSH_KEY must not contain spaces either (it goes into rsync -e).
#
# Usage:
# cd ~/code/myproj
# vm-sync omp            # checks, shows the plan, asks before applying
# vm-sync -n omp         # dry run only
# vm-sync -y omp         # no prompt
# vm-sync -r work/myproj omp
vm-sync() {
  local OPTIND=1 opt ldir="" rdir="" yes=0 dry=0 keep=0 force=0
  while getopts "l:r:nykfh" opt; do
    case "$opt" in
      l) ldir="$OPTARG" ;;
      r) rdir="$OPTARG" ;;
      n) dry=1 ;;
      y) yes=1 ;;
      k) keep=1 ;;
      f) force=1 ;;
      h) _vm_sync_usage; return 0 ;;
      *) _vm_sync_usage >&2; return 2 ;;
    esac
  done
  shift $((OPTIND - 1))
  local name="$1"
  [[ -n "$name" ]] || { _vm_sync_usage >&2; return 2; }

  if [[ -n "$ldir" ]]; then
    ldir=$(cd "$ldir" 2>/dev/null && pwd -P) || { echo "vm-sync: no such directory: $ldir" >&2; return 1; }
  else
    ldir=$(git rev-parse --show-toplevel 2>/dev/null) ||
      { echo "vm-sync: not inside a git repository (use -l DIR)" >&2; return 1; }
  fi
  [[ -n "$rdir" ]] || rdir="$VM_REMOTE_ROOT/$(basename "$ldir")"

  local target linfo rinfo
  target=$(_vm_target "$name") || return 1
  linfo=$(_vm_gitinfo_script | bash -s -- "$ldir")
  rinfo=$(_vm_gitinfo_script | _vm_ssh_target "$target" "bash -s -- '$rdir'")
  [[ -n "$rinfo" ]] || { echo "vm-sync: could not query $name over ssh" >&2; return 1; }

  local lerr rerr
  lerr=$(_vm_kv err "$linfo"); rerr=$(_vm_kv err "$rinfo")
  [[ -z "$lerr" ]] || { echo "vm-sync: local: $lerr" >&2; return 1; }
  [[ -z "$rerr" ]] || { echo "vm-sync: $name: $rerr" >&2; return 1; }

  # same repository?
  local lroots rroots lshallow rshallow lorigin rorigin
  lroots=$(_vm_kv roots "$linfo");     rroots=$(_vm_kv roots "$rinfo")
  lshallow=$(_vm_kv shallow "$linfo"); rshallow=$(_vm_kv shallow "$rinfo")
  lorigin=$(_vm_kv origin "$linfo");   rorigin=$(_vm_kv origin "$rinfo")
  if [[ -z "$lroots" || -z "$rroots" ]]; then
    echo "vm-sync: a repository has no commits, cannot verify identity" >&2; return 1
  elif [[ "$lroots" == "$rroots" ]]; then
    :
  elif [[ ( "$lshallow" == true || "$rshallow" == true ) && -n "$lorigin" && "$lorigin" == "$rorigin" ]]; then
    echo "note: shallow clone, matched by origin URL ($lorigin)" >&2
  else
    echo "vm-sync: these are different repositories (initial commits differ)" >&2; return 1
  fi

  # same branch?
  local lbranch rbranch lhead rhead
  lbranch=$(_vm_kv branch "$linfo"); rbranch=$(_vm_kv branch "$rinfo")
  [[ "$lbranch" == "$rbranch" ]] ||
    { echo "vm-sync: branch mismatch: local '$lbranch', $name '$rbranch'" >&2; return 1; }
  lhead=$(_vm_kv head "$linfo"); rhead=$(_vm_kv head "$rinfo")
  [[ "$lhead" == "$rhead" ]] ||
    echo "warning: HEAD differs (local ${lhead:0:8}, $name ${rhead:0:8}); the result includes those commit differences" >&2

  # local changes that the sync would clobber
  local ldirty
  ldirty=$(_vm_kv dirty "$linfo")
  if (( ldirty > 0 && ! force )); then
    echo "vm-sync: local working tree has $ldirty uncommitted change(s); the sync could overwrite or delete them:" >&2
    git -C "$ldir" status --short | head -10 >&2
    echo "Commit or stash them first, or use -f to continue anyway." >&2
    return 1
  fi

  # what would change?
  local rs=(-rlpt -i --exclude=.git --filter=':- .gitignore'
            -e "ssh -J $VM_HOST -i ${VM_SSH_KEY%.pub} ${_vm_ssh_opts[*]}")
  (( keep )) || rs+=(--delete)
  local src="$target:$rdir/" dst="$ldir/" raw plan ndel nchg
  raw=$(rsync "${rs[@]}" --exclude-from=<(_vm_local_ignored "$ldir") -n "$src" "$dst") ||
    { echo "vm-sync: rsync failed" >&2; return 1; }
  plan=$(printf '%s\n' "$raw" | grep -v '^\.d' || true)
  if [[ -z "$plan" ]]; then echo "already in sync"; return 0; fi
  ndel=$(printf '%s\n' "$plan" | grep -c '^\*deleting')
  nchg=$(printf '%s\n' "$plan" | grep -vc '^\*deleting')
  printf '%s\n' "$plan"
  echo "--- $nchg added/changed, $ndel deleted locally ($name:$rdir -> $ldir)"

  (( dry )) && { echo "(dry run, nothing changed)"; return 0; }
  if (( ! yes )); then
    printf 'Apply? [y/N] '; read -r ans
    [[ "$ans" == [yY]* ]] || { echo "aborted"; return 1; }
  fi
  rsync "${rs[@]}" --exclude-from=<(_vm_local_ignored "$ldir") "$src" "$dst" >/dev/null ||
    { echo "vm-sync: rsync failed" >&2; return 1; }
  echo "synced. Review with: git -C '$ldir' status"
}
