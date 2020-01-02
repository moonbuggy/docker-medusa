ARG ALPINE_VERSION=3.11.2

FROM moonbuggy2000/alpine-s6:3.11.2

ARG PYTHON_VERSION=3.8
ARG APP_PATH=/app

ARG MEDUSA_COMMIT_BRANCH=master
ARG MEDUSA_COMMIT_HASH=d0c136d7a528a471b51676140bd35d24d97f65c6

ENV PYTHON_INTERPRETER=python3 \
	APP_PATH="${APP_PATH}" \
	PYTHON_VERSION="${PYTHON_VERSION}" \
	PATH="${APP_PATH}:${PATH}" \
	PYTHONDONTWRITEBYTECODE=1 \
	PYTHONUNBUFFERED=1 \
	MEDUSA_COMMIT_BRANCH="${MEDUSA_COMMIT_BRANCH}" \
	MEDUSA_COMMIT_HASH="${MEDUSA_COMMIT_HASH}" \
	PUID=1000 \
	PGID=1000

WORKDIR ${APP_PATH}

RUN \
	# Install packages
	apk --update add --no-cache \
		git \
		mediainfo \
		python3=~${PYTHON_VERSION} \
		shadow \
		tzdata \
		unrar \
	# Link Python
	&& ln -sf /usr/bin/python3 /usr/bin/python \
	# Install Medusa
	&& git init \
	&& git remote add origin https://github.com/pymedusa/Medusa.git \
	&& git fetch --depth=1 origin ${MEDUSA_COMMIT_HASH} \
	&& git reset --hard FETCH_HEAD \
	&& rm -rf $(cat .dockerignore) \
	# Add user and group
	&& addgroup -g ${PGID} medusa \
	&& adduser -DH -u ${PUID} -G medusa medusa \
	# Fix permissions
	&& chown -R medusa:medusa ${APP_PATH} \
	# Cleanup
	&& apk del --no-cache git \
	&& rm -rf /var/cache/apk/

COPY ./etc /etc

EXPOSE 8081

VOLUME /config /downloads /tv /anime

ENTRYPOINT [ "/init" ]

HEALTHCHECK --start-period=60s --timeout=10s \
	CMD wget --quiet --tries=1 --spider http://127.0.0.1:8081/ || exit 1