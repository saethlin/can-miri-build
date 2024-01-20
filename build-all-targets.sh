#!/bin/bash

set -eu

rustup toolchain add nightly
rustup update nightly
rustup component add --toolchain=nightly miri rust-src

FAILS_DIR=failures
export MIRI_NO_STD=1

rm -rf $FAILS_DIR
mkdir $FAILS_DIR

# Try to build every target
for target in $(rustc +nightly --print target-list); do
    echo "Building sysroot for $target"
    # Wipe the cache before every build to minimize disk usage
    rm -rf ~/.cache/miri
    if cargo +nightly miri setup --target $target >failures/$target 2>&1; then
        # If the build succeeds, delete its output. If we have output, a build failed.
        rm $FAILS_DIR/$target
    fi
done

# If we 
if [[ $(ls failures | wc -l) -ne 0 ]]; then
    for target in $(ls failures); do
        cat $FAILS_DIR/$target
    done
    echo "We were not able to build a sysroot for at least one target."
    exit 1
fi
