#!/bin/sh

set -o errexit

# lynx needed to get version number in next step
if ! command -v lynx >/dev/null 2>&1; then
    echo "error: 'lynx' is not installed or not in PATH." >&2
    exit 1
fi

# get actual version number of "latest-stable" for filename
V=`lynx -dump https://dl-cdn.alpinelinux.org/alpine/ | \
	sed -n '/^References/,$p' | \
	awk '$1 ~ /^[0-9]/ {print $2}' | \
	grep --color=never 'alpine/v' | \
	xargs basename -s"/" | \
	sort -Vr | \
	sed 1q`

# date in UTC
F=alpine-virt-image-${V}-$(date -u +%Y-%m-%d-%H%M)

if [ "$CI" = "true" ]
then
    echo "Running under CI"
    echo $F > version
fi

./alpine-make-vm-image/alpine-make-vm-image \
	--branch "${V}"
	--packages "openssh e2fsprogs-extra" \
	--script-chroot \
	--image-format qcow2 \
	$F.qcow2 \
	-- \
	./setup.sh

bzip2 -z $F.qcow2
