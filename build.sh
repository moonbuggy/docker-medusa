#! /bin/bash
# shellcheck disable=SC2034

DOCKER_REPO="${DOCKER_REPO:-moonbuggy2000/medusa}"

all_tags='alpine alpine-pypy debian debian-pypy'
default_tag='latest'

[ x"${1}" = x"all" ] || TARGET_VERSION_TYPE='custom'

custom_source_latest () {
  echo "$(git_latest_release ${MEDUSA_REPO})" | sed -e 's|v||'
}

custom_versions () { docker_api_latest ${DOCKER_REPO} | sed -e 's|v||'; }
custom_repo_latest () { custom_versions; }

# create a new variable because $all_tags is overwitten by the builder
update_all_tags="${all_tags}"
custom_updateable_tags () {
  # shellcheck disable=SC2154
  [ ! -n "${updateable}" ] && return
  this_ver="$(custom_source_latest)"
  for this_build_tag in ${update_all_tags}; do
    printf "${this_ver}-${this_build_tag} "
  done
  echo
}

. "hooks/.build.sh"
