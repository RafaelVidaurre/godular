#!/usr/bin/env bash
# Re-vendors addons/gd_promise from the tag pinned in tests/dependencies.lock.
#
# GdPromise is developed in its own repository and copied in here, because the
# Asset Store forbids submodules: GitHub archives, and therefore Asset Store
# downloads, do not carry submodule content. Copying keeps every download
# working while the lock file keeps the version explicit.
#
# To bump: edit gd_promise_tag and gd_promise_commit in the lock, run this,
# then commit the result.
set -euo pipefail

# Fix collation so the checksum file has the same line order on every machine.
export LC_ALL=C

repository_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repository_root"

lock=tests/dependencies.lock
read_pin() {
	local key=$1 value
	value=$(sed -n "s/^${key}=//p" "$lock" | head -n 1)
	if [[ -z $value ]]; then
		echo "error: $key is missing from $lock" >&2
		exit 1
	fi
	printf '%s' "$value"
}

url=$(read_pin gd_promise_url)
tag=$(read_pin gd_promise_tag)
commit=$(read_pin gd_promise_commit)

checkout=$(mktemp -d)
trap 'rm -rf "$checkout"' EXIT

git clone --quiet --depth 1 --branch "$tag" "$url" "$checkout"

actual_commit=$(git -C "$checkout" rev-parse HEAD)
if [[ $actual_commit != "$commit" ]]; then
	echo "error: $tag is $actual_commit, but the lock pins $commit" >&2
	echo "The tag moved, or the lock is wrong. Resolve it before vendoring." >&2
	exit 1
fi

source=$checkout/addons/gd_promise
if [[ ! -d $source ]]; then
	echo "error: $tag has no addons/gd_promise directory" >&2
	exit 1
fi

rm -rf addons/gd_promise
cp -R "$source" addons/gd_promise

# The checksum file guards the vendored copy against local edits. Test runs
# verify it, so regenerate it here whenever the content changes.
find addons/gd_promise -type f -print0 | sort -z | xargs -0 shasum -a 256 \
	> tests/dependencies.sha256

echo "Vendored gd_promise $tag ($commit)"
