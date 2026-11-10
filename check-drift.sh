#!/bin/bash
# Report upstream dev-images changes that these mirrors do not have yet.
#
# The mirrors copy many files from upstream by hand. This script compares
# them with the pinned upstream commit, and shows what upstream changed
# after that commit.
set -euo pipefail

UPSTREAM_URL="https://gitlab.wikimedia.org/repos/releng/dev-images.git"
CACHE=".upstream"
PINFILE="upstream.pin"

cd "$(dirname "$0")"

# Files copied verbatim from upstream. Format: "<local path> <upstream path>".
COPIED="
files/mediawiki-trixie/php_entrypoint.sh trixie/php_entrypoint.sh
files/mediawiki-trixie/composer.phar.sha256sum trixie/composer.phar.sha256sum
files/mediawiki-trixie/docker/install.sh trixie/install.sh
files/mediawiki-trixie/docker/PlatformSettings.php trixie/PlatformSettings.php
files/mediawiki-trixie/docker/xdebug.ini trixie/xdebug.ini
files/mediawiki-apache2/ports.conf trixie-apache2/ports.conf
files/mediawiki-apache2/envvars trixie-apache2/envvars
files/mediawiki-apache2/000-default.conf trixie-apache2/000-default.conf
files/mediawiki-fpm/php-fpm.conf trixie-php85-fpm/php-fpm.conf
files/mediawiki-jobrunner/entrypoint.sh trixie-php85-jobrunner/entrypoint.sh
files/mediawiki-jobrunner/docker/PlatformSettings.php trixie-php85-jobrunner/PlatformSettings.php
files/mediawiki-php-sury/debsuryorg-archive-keyring.deb trixie-php-sury/debsuryorg-archive-keyring.deb
"

# Files kept different on purpose. Upstream changes to these need a manual
# decision, so the script only reports them.
LOCAL="
files/mediawiki-trixie/docker/www.conf trixie/www.conf
files/mediawiki-apache2/apache2.conf trixie-apache2/apache2.conf
files/mediawiki-apache2/entrypoint.sh trixie-apache2/entrypoint.sh
"

# Upstream templates that the local Dockerfiles follow by hand.
TEMPLATES="
trixie/Dockerfile.template
trixie-php-sury/Dockerfile.template
trixie-php85/Dockerfile.template
trixie-php85-fpm/Dockerfile.template
trixie-php85-jobrunner/Dockerfile.template
trixie-apache2/Dockerfile.template
"

# Upstream image versions, and the build.sh variable that mirrors each one.
# Format: "<upstream image dir> <build.sh variable>". A "-" means the local
# build does not tag that image.
IMAGES="
trixie -
trixie-php-sury suryTag
trixie-apache2 apache2Tag
trixie-php85 phpTag
trixie-php85-fpm phpFpmTag
trixie-php85-jobrunner phpJobRunnerTag
"

sync_cache() {
    local out
    if [ -d "$CACHE/.git" ]; then
        out=$(git -C "$CACHE" fetch origin 2>&1) || {
            echo "error: cannot fetch $UPSTREAM_URL" >&2
            echo "$out" >&2
            exit 2
        }
    else
        # Blobless clone: quick, but every commit stays reachable.
        out=$(git clone --quiet --filter=blob:none "$UPSTREAM_URL" "$CACHE" 2>&1) || {
            echo "error: cannot clone $UPSTREAM_URL" >&2
            echo "$out" >&2
            exit 2
        }
    fi
}

# Remove "." and ".." parts from a path.
normalize_path() {
    local part out=()
    local IFS=/
    for part in $1; do
        case "$part" in
            ""|".") ;;
            "..") unset 'out[${#out[@]}-1]' ;;
            *) out+=("$part") ;;
        esac
    done
    echo "${out[*]}"
}

# Find the real path of one upstream file at a given commit. Upstream keeps
# shared files as symlinks into common/, so follow the link. Print nothing
# if the file does not exist.
upstream_resolve() {
    local ref="$1" path="dockerfiles/$2" mode target
    for _ in 1 2 3 4 5; do
        mode=$(git -C "$CACHE" ls-tree "$ref" -- "$path" | awk '{print $1}')
        [ -z "$mode" ] && return 0
        [ "$mode" != 120000 ] && break
        target=$(git -C "$CACHE" show "${ref}:${path}")
        path=$(normalize_path "${path%/*}/${target}")
    done
    echo "$path"
}

# Read one file out of the upstream cache at a given commit.
upstream_file() {
    local path
    path=$(upstream_resolve "$1" "$2")
    [ -z "$path" ] && return 0
    git -C "$CACHE" show "${1}:${path}" 2>/dev/null || true
}

# Read the mode of one upstream file, after the symlinks.
upstream_mode() {
    local path
    path=$(upstream_resolve "$1" "$2")
    [ -z "$path" ] && return 0
    git -C "$CACHE" ls-tree "$1" -- "$path" | awk '{print $1}'
}

# Read the mode that this repository records for a local file. Git keeps only
# the execute bit, which is the part that COPY puts into the image.
local_mode() {
    git ls-files -s -- "$1" | awk '{print $1}'
}

# Read the mode of a local file on disk. This is the mode that docker build
# copies. It can differ from the index after "git update-index --chmod".
disk_mode() {
    [ -e "$1" ] || return 0
    if [ -x "$1" ]; then
        echo 100755
    else
        echo 100644
    fi
}

# Compare the mode of a local file with the upstream file at the pin. Check
# the index, which a clone gets, and then the disk, which docker build
# copies. Print nothing if the modes agree.
mode_reason() {
    local lpath="$1" upath="$2" umode lmode dmode
    umode=$(upstream_mode "$PIN" "$upath")
    [ -z "$umode" ] && return 0
    lmode=$(local_mode "$lpath")
    dmode=$(disk_mode "$lpath")
    if [ -n "$lmode" ] && [ "$lmode" != "$umode" ]; then
        echo "mode $lmode, upstream $umode"
    elif [ -n "$dmode" ] && [ "$dmode" != "$umode" ]; then
        echo "mode $dmode on disk, upstream $umode"
    fi
}

# Compare two files. Return 0 if they are the same and 1 if they differ.
# Stop on an error: if a compare cannot run, every file looks changed.
same_file() {
    local rc=0
    cmp -s "$1" "$2" || rc=$?
    if [ "$rc" -gt 1 ]; then
        echo "error: cannot compare $1 and $2" >&2
        cmp "$1" "$2" >&2 || true
        exit 2
    fi
    return "$rc"
}

# Read the version from the first line of an upstream changelog.
upstream_version() {
    upstream_file "$1" "${2}/changelog" | head -1 | sed -n 's/.*(\(.*\)).*/\1/p'
}

# Some sandboxes do not let diff or cmp read stdin or /dev/fd, so write
# the upstream files to disk before the compare.
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

sync_cache
PIN=$(grep -v '^#' "$PINFILE" | tr -d '[:space:]')
HEAD_SHA=$(git -C "$CACHE" rev-parse origin/HEAD)

if [ "${1:-}" = "--update-pin" ]; then
    { grep '^#' "$PINFILE"; printf '%s\n' "$HEAD_SHA"; } > "$PINFILE.new"
    mv "$PINFILE.new" "$PINFILE"
    echo "Pin moved to $HEAD_SHA"
    exit 0
fi

echo "pinned:   $(git -C "$CACHE" log -1 --format='%h %ad %s' --date=short "$PIN")"
echo "upstream: $(git -C "$CACHE" log -1 --format='%h %ad %s' --date=short "$HEAD_SHA")"
echo

drift=0
found=0

echo "== Files that no longer match the pin =="
while read -r lpath upath; do
    [ -z "$lpath" ] && continue
    reason=""
    upstream_file "$PIN" "$upath" > "$TMP/pin"
    if [ ! -e "$lpath" ]; then
        reason="missing"
    elif ! same_file "$TMP/pin" "$lpath"; then
        reason="content"
    fi
    mreason=$(mode_reason "$lpath" "$upath")
    [ -n "$mreason" ] && reason="${reason:+$reason, }$mreason"
    if [ -n "$reason" ]; then
        echo "  $lpath ($reason)"
        found=1
    fi
done <<< "$COPIED"

# The LOCAL files hold different content on purpose, but the mode must still
# agree with upstream.
while read -r lpath upath; do
    [ -z "$lpath" ] && continue
    mreason=$(mode_reason "$lpath" "$upath")
    if [ -n "$mreason" ]; then
        echo "  $lpath ($mreason)"
        found=1
    fi
done <<< "$LOCAL"
[ "$found" = 0 ] && echo "  (none)" || drift=1
echo

# Say how upstream changed one file after the pin. Print nothing if it is
# the same.
upstream_change() {
    local upath="$1" pinmode newmode reason=""
    upstream_file "$PIN" "$upath" > "$TMP/pin"
    upstream_file "$HEAD_SHA" "$upath" > "$TMP/head"
    if ! same_file "$TMP/pin" "$TMP/head"; then
        reason="content"
    fi
    pinmode=$(upstream_mode "$PIN" "$upath")
    newmode=$(upstream_mode "$HEAD_SHA" "$upath")
    if [ -n "$pinmode" ] && [ -n "$newmode" ] && [ "$pinmode" != "$newmode" ]; then
        reason="${reason:+$reason, }mode $pinmode -> $newmode"
    fi
    echo "$reason"
}

report_pairs() {
    local action="$1" pairs="$2" lpath upath reason
    while read -r lpath upath; do
        [ -z "$lpath" ] && continue
        reason=$(upstream_change "$upath")
        if [ -n "$reason" ]; then
            echo "  [$action] $upath -> $lpath ($reason)"
            found=1
        fi
    done <<< "$pairs"
}

echo "== Upstream changes after the pin =="
found=0
report_pairs copy "$COPIED"
report_pairs review "$LOCAL"
while read -r tpl; do
    [ -z "$tpl" ] && continue
    reason=$(upstream_change "$tpl")
    if [ -n "$reason" ]; then
        echo "  [review] $tpl ($reason)"
        found=1
    fi
done <<< "$TEMPLATES"
[ "$found" = 0 ] && echo "  (none)" || drift=1
echo

echo "== Image versions =="
printf '  %-26s %-11s %-11s %s\n' IMAGE PINNED UPSTREAM LOCAL
while read -r dir var; do
    [ -z "$dir" ] && continue
    pinv=$(upstream_version "$PIN" "$dir")
    newv=$(upstream_version "$HEAD_SHA" "$dir")
    if [ "$var" = "-" ]; then
        localv="-"
    else
        localv=$(sed -n "s/^${var}=\"\(.*\)\"$/\1/p" build.sh)
        localv="${localv%-arm1}"
    fi
    mark=""
    [ "$pinv" != "$newv" ] && mark=" <- upstream bumped"
    [ "$var" != "-" ] && [ "$localv" != "$pinv" ] && mark="$mark <- build.sh differs from pin"
    [ -n "$mark" ] && drift=1
    printf '  %-26s %-11s %-11s %s%s\n' "$dir" "${pinv:--}" "${newv:--}" "${localv:--}" "$mark"
done <<< "$IMAGES"

echo
if [ "$drift" = 0 ]; then
    echo "No drift."
else
    echo "Drift found. Apply the changes, then run: $0 --update-pin"
fi
exit "$drift"
