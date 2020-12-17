ARG ALPINE_VERSION=3.11.3
ARG PYTHON_VERSION=3.8

ARG MEDUSA_COMMIT_BRANCH=master
ARG MEDUSA_COMMIT_HASH=552f1199853dfce905f9ba6e27194da67070ea6a

# get the source code
#
FROM moonbuggy2000/fetcher:latest as source

ARG MEDUSA_COMMIT_BRANCH
ARG MEDUSA_COMMIT_HASH

WORKDIR /source

RUN git init \
	&& git remote add origin https://github.com/pymedusa/Medusa.git \
	&& git fetch --depth=1 origin ${MEDUSA_COMMIT_HASH} \
	&& git reset --hard FETCH_HEAD \
	&& rm -rf $(cat .dockerignore)


# build the image
#
FROM moonbuggy2000/alpine-s6:${ALPINE_VERSION}

ARG PYTHON_VERSION
ARG APP_PATH=/app
ARG PUID=1000
ARG PGID=1000

ARG MEDUSA_COMMIT_BRANCH
ARG MEDUSA_COMMIT_HASH

ENV PATH="${APP_PATH}:${PATH}" \
	PUID=${PUID} \
	PGID=${PGID}

WORKDIR ${APP_PATH}

RUN \
	# Set some environment variables via cont-init.d
	add-contenv \
		APP_PATH=${APP_PATH} \
		PYTHON_INTERPRETER=python3 \
		PYTHONDONTWRITEBYTECODE=1 \
		PYTHONUNBUFFERED=1 \
		MEDUSA_COMMIT_BRANCH="${MEDUSA_COMMIT_BRANCH}" \
		MEDUSA_COMMIT_HASH="${MEDUSA_COMMIT_HASH}" \
	# Install packages
	&& apk --update add --no-cache \
		git \
		mediainfo \
		python3=~${PYTHON_VERSION} \
		shadow \
#		tzdata \
		unrar \
	# Link Python
	&& ln -sf /usr/bin/python3 /usr/bin/python \
	# Add user and group
	&& addgroup -g ${PGID} medusa \
	&& adduser -DH -u ${PUID} -G medusa medusa \
	# Cleanup
	&& apk del --no-cache git \
	&& rm -rf /var/cache/apk/

COPY --from=source --chown=medusa:medusa /source/ ./
COPY ./etc /etc

EXPOSE 8081

VOLUME /config /downloads /tv /anime

ENTRYPOINT [ "/init" ]

HEALTHCHECK --start-period=10s --timeout=10s \
	CMD wget --quiet --tries=1 http://127.0.0.1:8081/ -O /dev/null || exit 1
