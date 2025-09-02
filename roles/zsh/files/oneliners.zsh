function chartcheck() {
  # example: chartcheck https://helm.elastic.co filebeat
  # example: chartcheck https://helm.elastic.co filebeat-7.14

  if [[ $# -ne 2 ]]; then
    echo >&2 "usage: ${funcstack[1]} CHARTHOST SEARCH"
    return 1
  fi

  if ! command -v xmllint > /dev/null 2>&1; then
    echo >&2 "error: please install xmllint"
    return 1
  fi

  curl -Ls "${1}" | xmllint --format - | grep "${2}"
}

function azvmipfind() {
  # example: azvmipfind
  # example: azvmipfind '^vm-'
  # example: azvmipfind '^vm-' prd

  if ! command -v az > /dev/null 2>&1; then
    echo >&2 "error: please install the azure-cli"
    return 1
  fi

  local query="'[].{Name:name, IP:ipConfigurations[0].privateIpAddress}'"
  local cmd="az network nic list -o table --query $query"

  for s in ${@}; do
    cmd="$cmd | grep '${s}'"
  done

  # set -x
  eval $cmd
}

function prunelocalgitbranches() {
  # some variation of this could potentially work to avoid needing to
  # enumerate the "skip" branches directly
  # git branch --list --format \
  #   "%(if:equals=[gone])%(upstream:track)%(then)%(refname)%(end)" |
  #   sed 's|^refs/heads/||' | grep .

  git fetch -p # prune remote branches first
  git branch --merged | # only delete _merged_ branches
    grep -v '^*' | # ignore the current branch
    awk '{print $1}' | # trim leading whitespace
    grep -v '^devel\|develop\|main\|master$' | # skip well known branches
    xargs git branch -d # do the needful
}

function k8spodswithoutcontroller() {
  # https://stackoverflow.com/a/58613732

  kubectl get pods --all-namespaces -o json |
    jq -r ".items | map(select(.metadata.ownerReferences == null) |\
      .metadata.name) | .[]"
}

function k8sallimagesmatch() {
  kubectl get deploy,statefulset,daemonset -A -o json \
    | jq -r "
      .items[]
      | {ns: .metadata.namespace,
         kind: .kind,
         name: .metadata.name,
         images: (
           .spec.template.spec.containers[]?.image,
           .spec.template.spec.initContainers[]?.image,
           .spec.template.spec.ephemeralContainers[]?.image
         )}
      | select(.images | test(\"$1\"))
      | \"\\(.ns)\\t\\(.kind)\\t\\(.name)\\t\\(.images)\""
}

function currentdirmd5sum() {
  if ! command -v fd > /dev/null 2>&1; then
    echo >&2 "error: requires 'fd' tool"
  fi

  fd --type file --print0 --strip-cwd-prefix=always | sort -z |
    xargs -0 md5sum
}

function currentdirmd5sumb() {
  if ! command -v fd > /dev/null 2>&1; then
    echo >&2 "error: requires 'fd' tool"
  fi

  fd --type file --print0 --strip-cwd-prefix=always | sort -z |
    xargs -0 md5sum -b
}

function urlencode() {
  /usr/bin/env python3 -c \
    "import sys, urllib.parse as ul; print(ul.quote(sys.argv[1]))" "$1"
}
