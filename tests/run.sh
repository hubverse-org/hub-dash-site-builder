#!/usr/bin/env bash

IMG=${1}
DIR=${2}

running_in_docker() {
  awk -F/ '$2 == "docker"' /proc/self/cgroup 2> /dev/null | read || return
}

if running_in_docker; then
  PREAMBLE="render.sh"
else
  TMP=$(mktemp -d)
  cp -R ${DIR} ${TMP}
  PREAMBLE="docker run --rm -it --platform=linux/amd64 -v \"${TMP}\":\"/site\" ${IMG} render.sh"
fi

ok="✅"
no="❌"

echo "${PREAMBLE}"

chk="Help works"
n=$(eval "${PREAMBLE} -h" | grep -c render.sh)
[[ $n -gt 1 ]] && echo "$chk | $ok" || echo "$chk | $no"

chk="Arguments must be paired: -u"
n=$(eval "${PREAMBLE} -u reichlab" | grep -c "ERROR: The correct pair of arguments are REQUIRED")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"

chk="Arguments must be paired: -r"
n=$(eval "${PREAMBLE} -r flusight-dashboard" | grep -c "ERROR: The correct pair of arguments are REQUIRED")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"

chk="Arguments must be paired: -p"
n=$(eval "${PREAMBLE} -p data/ptc" | grep -c "ERROR: The correct pair of arguments are REQUIRED")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"

chk="Arguments must be paired: -e"
n=$(eval "${PREAMBLE} -p data/evals" | grep -c "ERROR: The correct pair of arguments are REQUIRED")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"

echo "Site can be built with remote data"
chk="    Process reports success"
n=$(eval "${PREAMBLE} -u reichlab -r flusight-dashboard" | grep -c "done")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"
chk="    pages/_site/ folder exists"
[[ -f "${TMP}/pages/_site/index.html" ]] && echo "$chk | $ok" || echo "$chk | $no"

chk="    Data are not embedded in predtimechart"
n=$(grep -c githubusercontent "${TMP}/pages/_site/resources/predtimechart.js")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"
chk="    Data are not embedded in predevals"
n=$(grep -c githubusercontent "${TMP}/pages/_site/resources/predevals_interface.js")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"

chk="    Process reports success writing to other folder"
n=$(eval "${PREAMBLE} -u reichlab -r flusight-dashboard -o remote" | grep -c "done")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"
chk="    remote/ folder exists"
[[ -f "${TMP}/remote/index.html" ]] && echo "$chk | $ok" || echo "$chk | $no"

chk="    Data are not embedded in predtimechart"
n=$(grep -c githubusercontent "${TMP}/remote/resources/predtimechart.js")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"
chk="    Data are not embedded in predevals"
n=$(grep -c githubusercontent "${TMP}/remote/resources/predevals_interface.js")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"

echo "Site can be built with local data"

git -C "${TMP}" worktree add --checkout data/ptc ptc/data
git -C "${TMP}" worktree add --checkout data/evals predevals/data

chk="    Process reports success"
n=$(eval "${PREAMBLE} -p data/ptc -e data/evals -o local" | grep -c "done")
[[ $n -gt 0 ]] && echo "$chk | $ok" || echo "$chk | $no"
chk="    local/ folder exists"
[[ -f "${TMP}/local/index.html" ]] && echo "$chk | $ok" || echo "$chk | $no"

chk="    Data are embedded in predtimechart"
n=$(grep -c githubusercontent "${TMP}/local/resources/predtimechart.js")
[[ $n -eq 0 ]] && echo "$chk | $ok" || echo "$chk | $no"
chk="    Data are embedded in predevals"
n=$(grep -c githubusercontent "${TMP}/local/resources/predevals_interface.js")
[[ $n -eq 0 ]] && echo "$chk | $ok" || echo "$chk | $no"

rm -rf "${TMP}"
