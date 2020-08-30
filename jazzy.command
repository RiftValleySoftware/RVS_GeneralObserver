#!/bin/sh
CWD="$(pwd)"
MY_SCRIPT_PATH=`dirname "${BASH_SOURCE[0]}"`
cd "${MY_SCRIPT_PATH}"
rm -drf docs/*

jazzy   --readme ./README-API.md \
        --github_url https://github.com/RiftValleySoftware/RVS_GeneralObserver \
        --title RVS_BTDriver\ Public\ API\ Doumentation \
        --min_acl public \
        --build-tool-arguments -scheme,RVS_GeneralObserver
cp icon.png docs/icon.png

cd "${CWD}"
