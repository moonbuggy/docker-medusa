# Docker Medusa
[Medusa](https://pymedusa.com/) in an Alpine or Debian-slim container with
either Python or PyPy.

## Usage
`docker run -d --name Medusa -p 8081:8081 moonbuggy2000/medusa:<tag>`

### Tags
*   `alpine`, `latest`     - Alpine using Python as the interpreter
*   `alpine-pypy`, `pypy`  - Alpine using PyPy as the interpreter
*   `debian`               - debian-slim using Python as the interpreter
*   `debian-pypy`          - debian-slim using PyPy as the interpreter

PyPy may result in Medusa running faster, although I've neither bench-marked it
nor done a thorough test of compatibility. It seems to run as expected for me
(so far).

Python generally runs faster in Debian than Alpine due to Alpine's usage of musl
instead of glibc, so the `debian` images should theoretically perform better (at
the cost of increased image size). Again, I have not benchmarked this to confirm.

Older images used Bitnami's minideb instead of Debian-slim as a base, however
the minideb images had limited architecture support so the change was necessary
for multi-arch building. The `minideb` tags are no longer updated and should not
be used.

#### Architectures
The Alpine and Debian tags above should automatically provide an image that
works on `amd64`, `arm`, `armhf`, `arm64`, `386`, `ppc64le` and `s390x` devices.
The PyPy builds support fewer architectures.

If desired, a particular architecture can be specified by adding a suffix to a
tag in the form `<tag>-<arch>` (e.g. `debian-pypy-arm64`).

In keeping with the theme, I have not tested these builds on all the various
architectures.

### Environment variables
*   `PUID` - user ID to run as (default: `1000`)
*   `PGID` - group ID to run as (default: `1000`)
*   `TZ`   - set the timezone

The PUID/PGID settings are to ensure correct permissions are set when accessing
mounted host volumes.

### Volumes
The following volumes will need to be mounted to volumes on the host to persist
configuration and give Medusa access to downloads and media files.

*   `/config`
*   `/downloads`
*   `/tv`
*   `/anime`

## Known Issues
The container may fail to start on some ARM devices with this error:

```
Fatal Python error: pyinit_main: can't initialize time
Python runtime state: core initialized
PermissionError: [Errno 1] Operation not permitted
```

This is caused by [a bug in libseccomp](https://github.com/moby/moby/issues/40734)
and can be resolved by either updating libseccomp on the Docker _host_ (to at
least 2.4.x) or running the container with `--security-opt seccomp=unconfined`
set in the `docker run` command.

On a Debian-based host (e.g. Armbian) it may be necessary to add the backports
repo for apt to find the newest version.

## Links
GitHub: <https://github.com/moonbuggy/docker-medusa>

Docker Hub: <https://hub.docker.com/r/moonbuggy2000/medusa>
