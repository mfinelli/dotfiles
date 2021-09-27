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
