#! /bin/sh

wget -q http://localhost:8081/ -O /dev/null && echo 'Status: Okay' || exit 1
