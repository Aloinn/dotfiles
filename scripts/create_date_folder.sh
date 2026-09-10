#!/bin/bash
date_folder=$(date +%Y-%m-%d)
mkdir -p ~/scratch/$date_folder
cd ~/scratch/$date_folder

if [[ " $* " =~ " -n " ]]; then
    if [ ! -f today.md ]; then
        echo "# [$date_folder] Notes" >> '~/scratch/today.md'
        echo "" >> '~/scratch/today.md'
    fi

    if [[ " $* " =~ " -p " ]]; then
       echo "/home/alainlam/scratch/$date_folder/today.md"
    else 
        nvim ./today.md
    fi
fi
