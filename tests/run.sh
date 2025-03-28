#!/usr/bin/env bash

IMG=${1}
DASH=${2}

running_in_docker() {
  awk -F/ '$2 == "docker"' /proc/self/cgroup 2> /dev/null | read || return
}

errors=0
ntest=0

ok() {
  ((ntest++))
  echo "$chk | ✅"
}
no() {
  ((ntest++))
  ((errors++))
  echo "$chk | ❌"
}

if running_in_docker; then
  # if we are running in docker, then our dashboard is assumed to be in the 
  # current working directory
  PREAMBLE="render.sh"
  TMP=$(pwd)
else
  TMP=$(mktemp -d)
  git clone "https://github.com/${DASH}.git" ${TMP}
  PREAMBLE="docker run --rm --platform=linux/amd64 -v \"${TMP}\":\"/site\" ${IMG} render.sh"
fi


echo "${PREAMBLE}"

chk="Help works"
n=$(eval "${PREAMBLE} -h" | grep -c render.sh)
[[ $n -gt 1 ]] && ok || no

chk="Arguments must be paired: -u"
n=$(eval "${PREAMBLE} -u reichlab" | grep -c "ERROR: The correct pair of arguments are REQUIRED")
[[ $n -gt 0 ]] && ok || no

chk="Arguments must be paired: -r"
n=$(eval "${PREAMBLE} -r flusight-dashboard" | grep -c "ERROR: The correct pair of arguments are REQUIRED")
[[ $n -gt 0 ]] && ok || no

chk="Arguments must be paired: -p"
n=$(eval "${PREAMBLE} -p data/ptc" | grep -c "ERROR: The correct pair of arguments are REQUIRED")
[[ $n -gt 0 ]] && ok || no

chk="Arguments must be paired: -e"
n=$(eval "${PREAMBLE} -p data/evals" | grep -c "ERROR: The correct pair of arguments are REQUIRED")
[[ $n -gt 0 ]] && ok || no

echo "Site can be built with remote data"
chk="    Process reports success"
n=$(eval "${PREAMBLE} -u reichlab -r flusight-dashboard" | grep -c "done")
[[ $n -gt 0 ]] && ok || no
chk="    pages/_site/ folder exists"
[[ -f "${TMP}/pages/_site/index.html" ]] && ok || no
chk="    forecast page exists"
[[ -f "${TMP}/pages/_site/forecast.html" ]] && ok || no
chk="    eval page exists"
[[ -f "${TMP}/pages/_site/eval.html" ]] && ok || no

chk="    Data are not embedded in predtimechart"
n=$(grep -c githubusercontent "${TMP}/pages/_site/resources/predtimechart.js")
[[ $n -gt 0 ]] && ok || no
chk="    Data are not embedded in predevals"
n=$(grep -c githubusercontent "${TMP}/pages/_site/resources/predevals_interface.js")
[[ $n -gt 0 ]] && ok || no

chk="    Process reports success writing to other folder"
n=$(eval "${PREAMBLE} -u reichlab -r flusight-dashboard -o remote" | grep -c "done")
[[ $n -gt 0 ]] && ok || no
chk="    remote/ folder exists"
[[ -f "${TMP}/remote/index.html" ]] && ok || no
chk="    forecast page exists"
[[ -f "${TMP}/remote/forecast.html" ]] && ok || no
chk="    eval page exists"
[[ -f "${TMP}/remote/eval.html" ]] && ok || no

chk="    Data are not embedded in predtimechart"
n=$(grep -c githubusercontent "${TMP}/remote/resources/predtimechart.js")
[[ $n -gt 0 ]] && ok || no
chk="    Data are not embedded in predevals"
n=$(grep -c githubusercontent "${TMP}/remote/resources/predevals_interface.js")
[[ $n -gt 0 ]] && ok || no

echo "Site can be built with local data"

git -C "${TMP}" worktree add --checkout data/ptc ptc/data > /dev/null 2>&1
git -C "${TMP}" worktree add --checkout data/evals predevals/data > /dev/null 2>&1


chk="    Process reports success"
n=$(eval "${PREAMBLE} -p data/ptc -e data/evals -o local" | grep -c "done")
[[ $n -gt 0 ]] && ok || no
chk="    local/ folder exists"
[[ -f "${TMP}/local/index.html" ]] && ok || no
chk="    forecast page exists"
[[ -f "${TMP}/local/forecast.html" ]] && ok || no
chk="    eval page exists"
[[ -f "${TMP}/local/eval.html" ]] && ok || no

chk="    Data are embedded in predtimechart"
n=$(grep -c githubusercontent "${TMP}/local/resources/predtimechart.js")
[[ $n -eq 0 ]] && ok || no
chk="    Data are embedded in predevals"
n=$(grep -c githubusercontent "${TMP}/local/resources/predevals_interface.js")
[[ $n -eq 0 ]] && ok || no

echo "Site can be built without visualizations"

rm -rf ${TMP}/predevals-config.yml ${TMP}/predtimechart-config.yml
chk="    Process reports success"
n=$(eval "${PREAMBLE} -u reichlab -r flusight -o novis" | grep -c "done")
[[ $n -gt 0 ]] && ok || no
chk="    novis/ folder exists"
[[ -f "${TMP}/novis/index.html" ]] && ok || no
chk="    forecast page is gone"
[[ ! -f "${TMP}/novis/forecast.html" ]] && ok || no
chk="    eval page is gone"
[[ ! -f "${TMP}/novis/eval.html" ]] && ok || no

rm -rf "${TMP}" > /dev/null 2>&1  || echo "note: unable to remove ${TMP}"

echo
if [[ $errors -eq 0 ]]; then
  echo "🎉 All tests pass (n=$ntest)!"
  exit 0
else
  echo "❌ ${errors}/${ntest} errors found"
  fi
  exit 1
fi
