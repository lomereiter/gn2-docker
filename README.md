# gn2-docker
GeneNetwork2 development server installation

## Building the image
Run `docker build` after cloning the repository:
```bash
$ cd gn2-docker
$ docker build  -t gn2 .
```

It should take ~1.5 hours.

## Running the server
```bash
docker run -i -p 0.0.0.0:5003:5003 -t gn2
```

Now its web interface is available at 0.0.0.0:5003

## Making changes

Find the container id in the `docker ps` output and run `bash` in that container. The following one-liner should work:
```bash
docker exec -i -t `docker ps | grep gn2 | cut -f1 -d' ' | head -n1` /bin/bash
```

Vim is already installed in the built image.


