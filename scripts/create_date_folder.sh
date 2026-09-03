#!/bin/bash
date_folder=$(date +%Y-%m-%d)
mkdir -p ~/scratch/$date_folder
cd ~/scratch/$date_folder

if [[ " $* " =~ " -n " ]]; then
    if [ ! -f today.md ]; then
        echo "# [$date_folder] Notes" >> today.md
        echo "" >> today.md
    fi

    nvim ./today.md
fi
