#/bin/bash

[[ $# -ne 1 ]] && echo "Please provide a title" && exit 1

title=$1
title_bad=$(echo $title | tr ' ' '_')
file=$(date "+%Y-%m-%d-$title_bad.md")

cat<<EOF >> $file
---
layout: default
title:  $title
date:   $(date)
---
EOF

vim $file
