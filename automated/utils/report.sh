#!/bin/sh -ex

# shellcheck disable=SC1091
. ../lib/sh-test-lib
DIR=$1
OUTPUT=$2

mkdir -p "${OUTPUT}"
for plan in func func-manual enterprise enterprise-manual perf perf-manual ltp libhugetlbfs; do
    if [ -f "${DIR}/${plan}/result.csv" ]; then
        cp "${DIR}/${plan}/result.csv" "${OUTPUT}/${plan}.csv"
    fi

    if [ -f "${DIR}/${plan}/result.json" ]; then
        cp "${DIR}/${plan}/result.json" "${OUTPUT}/${plan}.json"
    fi
done

mkdir -p "${OUTPUT}/context"
# kernel version
uname -a > "${OUTPUT}/context/kernel-version"

# firmware version
command -v dmidecode || install_deps "dmidecode"
dmidecode -t bios > "${OUTPUT}/context/bios-version"

# installed packages
dist_name
# shellcheck disable=SC2154
case "${dist}" in
    Debian|Ubuntu) dpkg-query -l > "${OUTPUT}/context/installed-pkgs" ;;
    CentOS|Fedora) rpm -qa > "${OUTPUT}/context/installed-pkgs" ;;
    *) error_msg "Unsupported distro: ${dist}" ;;
esac
