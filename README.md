# Docker Medusa
[Medusa](https://pymedusa.com/) in an Alpine or minideb container with either Python or PyPy.

## Usage
`docker run -d --name Medusa -p 8081:8081 moonbuggy2000/medusa:<tag>`

### Tags
* `latest` / `python` - Alpine using Python as the interpreter
* `pypy`              - Alpine using PyPy as the interpreter
* `minideb`           - Bitnami's minideb using Python as the interpreter
* `minideb-pypy`      - Bitnami's minideb using PyPy as the interpreter

PyPy may result in Medusa running faster, although I've neither benchmarked it nor done a thorough test of compatibility. It seems to run as expected for me (so far).

Python generally runs faster in Debian than Alpine due to Alpine's usage of musl instead of glibc, so the `minideb` image should theoretically perform better (at the cost of increased image size). Again, I have not benchmarked this to confirm.

### Environment variables
* `PUID` - user ID to run as (default: `1000`)
* `PGID` - group ID to run as (default: `1000`)

The PUID/PGID settings are to ensure correct permissions are set when accessing mounted host volumes. 

### Volumes
The following volumes will need to be mounted to volumes on the host to persist configuration and give Medusa access to downloads and media files.

* `/config`
* `/downloads`
* `/tv`
* `/anime`

## Links
GitHub: https://github.com/moonbuggy/docker-medusa

Docker Hub: https://hub.docker.com/r/moonbuggy2000/medusa
