# gn2-docker
GeneNetwork2 development server installation

## Clone one of GN2 repo forks (unless already done)
E.g.
``` bash
$ git clone git@github.com:zsloan/genenetwork2.git
```

While the repository is being cloned (it's quite large), start building the Docker image.

## Building the image
Run `docker build` after cloning the `gn2-docker` repository:
```bash
$ cd gn2-docker
$ docker build  -t gn2 .
```

It should take about an hour.

## Running the server and making changes

The development directory is mapped as a Docker volume, so that all updates to files in it are applied immediately:
```bash
<cd into genenetwork2 repository>
docker run -i -t -v `pwd`:/home/zas1024/gene -p 5003:5003 gn2_v7
```

In a few seconds, the web interface should become available at 0.0.0.0:5003
