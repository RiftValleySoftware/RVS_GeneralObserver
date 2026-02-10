#!/bin/sh
CWD="$(pwd)"
MY_SCRIPT_PATH=`dirname "${BASH_SOURCE[0]}"`
cd "${MY_SCRIPT_PATH}"
rm -drf docs/*

jazzy   --readme ./README.md \
        --author The\ Great\ Rift\ Valley\ Software\ Company \
        --author_url https://riftvalleysoftware.com \
        --github_url https://github.com/RiftValleySoftware/RVS_GeneralObserver \
        --title RVS_GeneralObserver\ Public\ API\ Doumentation \
        --min_acl public \
        --module RVS_GeneralObserver \
        --theme fullwidth \
        --build-tool-arguments -scheme,"RVS_GeneralObserver"
cp icon.png docs/icon.png

cd "${CWD}"
