#! /bin/bash

#NOOP='true'
#DO_PUSH='true'
#NO_BUILD='true'

DOCKER_REPO="${DOCKER_REPO:-moonbuggy2000/medusa}"

all_tags='alpine alpine-pypy debian debian-pypy'
default_tag='latest'

. "hooks/.build.sh"
