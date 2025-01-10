# syntax = docker/dockerfile:1.4.0

ARG PYTHON_VERSION="3.10"
ARG ALPINE_VERSION="3.14"
ARG FROM_IMAGE="moonbuggy2000/alpine-s6-python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}"

ARG MEDUSA_COMMIT_BRANCH="master"
ARG MEDUSA_COMMIT_HASH="c302d8ae089a3c41eb8dda166cb71f9a4b39b79e"

ARG APP_PATH="/app"

# fetch files using the build platform's architecture, benefit from caching
FROM --platform="${BUILDPLATFORM}" moonbuggy2000/fetcher:latest AS fetcher

## get medusa
#
FROM fetcher AS medusa

WORKDIR /fetcher_root/
ARG APP_PATH
ARG MEDUSA_COMMIT_HASH
RUN mkdir ".${APP_PATH}" && cd ".${APP_PATH}" \
	&& git init -q \
	&& git remote add origin https://github.com/pymedusa/Medusa.git \
	&& git fetch --depth=1 origin "${MEDUSA_COMMIT_HASH}" \
	&& git reset --hard FETCH_HEAD \
	&& rm -rf $(cat .dockerignore)


## Get FFprobe
#
FROM fetcher AS ffprobe

WORKDIR /fetcher_root/usr/local/bin/
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
		amd64) FFMPEG_ARCH="amd64" ;; \
		arm64*) FFMPEG_ARCH="arm64" ;; \
		arm|armv5) FFMPEG_ARCH="armel" ;; \
		armv6|armv7) FFMPEG_ARCH="armhf" ;; \
		386) FFMPEG_ARCH="i686" ;; \
		*) unset FFMPEG_ARCH ;; \
	esac; \
	if [ ! -z "${FFMPEG_ARCH}" ]; then \
		mkdir /ffmpeg-temp; \
		wget -qO- "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-${FFMPEG_ARCH}-static.tar.xz" \
			| tar xJf - --strip-components=1 -C /ffmpeg-temp/; \
		mv "/ffmpeg-temp/ffprobe" .; \
		chmod a+x ffprobe; \
		rm -rf /ffmpeg-temp; \
	fi


## build the base image, common to all final targets
#
FROM --platform="${TARGETPLATFORM}" "${FROM_IMAGE}" AS base

COPY root/ /
COPY --from=medusa --chown=medusa:medusa /fetcher_root/ /
COPY --from=ffprobe /fetcher_root/ /

ARG APP_PATH
ARG PGID=1000
ARG PUID=1000
ENV PATH="${APP_PATH}:${PATH}" \
	PUID="${PGID}" \
	PGID="${PUID}"

ARG PYTHON_INTERPRETER="python3"
ARG MEDUSA_COMMIT_BRANCH
ARG MEDUSA_COMMIT_HASH
RUN add-contenv \
		APP_PATH="${APP_PATH}" \
		PYTHON_INTERPRETER="${PYTHON_INTERPRETER}" \
		PYTHONDONTWRITEBYTECODE=1 \
		PYTHONUNBUFFERED=1 \
		MEDUSA_COMMIT_BRANCH="${MEDUSA_COMMIT_BRANCH}" \
		MEDUSA_COMMIT_HASH="${MEDUSA_COMMIT_HASH}"

WORKDIR "${APP_PATH}"

EXPOSE 8081

VOLUME /config /downloads /tv /anime

ENTRYPOINT [ "/init" ]

HEALTHCHECK --start-period=60s --timeout=10s CMD /healthcheck.sh


## build the alpine image
#
FROM base AS alpine

ARG APK_PROXY=""
RUN if [ ! -z "${APK_PROXY}" ]; then \
		alpine_minor_ver="$(grep -o 'VERSION_ID.*' /etc/os-release | grep -oE '([0-9]+\.[0-9]+)')"; \
    mv /etc/apk/repositories /etc/apk/repositories.bak; \
		echo "${APK_PROXY}/alpine/v${alpine_minor_ver}/main" >/etc/apk/repositories; \
		echo "${APK_PROXY}/alpine/v${alpine_minor_ver}/community" >>/etc/apk/repositories; \
	fi \
	&& apk -U add --no-cache \
		git \
		mediainfo \
		shadow \
		tzdata \
		unrar \
	&& addgroup -g ${PGID} medusa \
	&& adduser -DH -u ${PUID} -G medusa medusa \
	&& rm -rf /var/cache/apk/ \
  && (mv /etc/apk/repositories.bak /etc/apk/repositories || true)


## build the alpine-pypy image
#
FROM alpine AS alpine-pypy

RUN ln -s /usr/local/bin/pypy3 /usr/local/bin/python


## build the debian image
#
FROM base AS debian

ARG APT_CACHE=""
RUN export DEBIAN_FRONTEND="noninteractive" \
	&& if [ ! -z "${APT_CACHE}" ]; then \
		echo "Acquire::http { Proxy \"${APT_CACHE}\"; }" > /etc/apt/apt.conf.d/proxy; fi \
	&& apt-get update \
	&& apt-get install -qy --no-install-recommends \
		git-core \
		mediainfo \
		openssl \
		tzdata \
		unrar-free \
		wget \
	&& rm -rf /var/lib/apt/lists/* \
	&& groupadd -g "${PGID}" medusa \
	&& useradd -M -u "${PUID}" -g medusa medusa \
	&& (rm -f /etc/apt/apt.conf.d/proxy 2>&1 || true)


## build the debian-pypy image
#
FROM debian AS debian-pypy

ARG APT_CACHE=""
RUN export DEBIAN_FRONTEND="noninteractive" \
	&& if [ ! -z "${APT_CACHE}" ]; then \
		echo "Acquire::http { Proxy \"${APT_CACHE}\"; }" > /etc/apt/apt.conf.d/proxy; fi \
	&& apt-get update \
	&& apt-get install -qy --no-install-recommends \
		ca-certificates \
		libsqlite3-0 \
	&& rm -rf /var/lib/apt/lists/* \
	&& (rm -f /etc/apt/apt.conf.d/proxy 2>&1 || true)


## make alpine the default target
#
FROM alpine
