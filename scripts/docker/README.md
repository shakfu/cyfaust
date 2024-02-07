# Build cyfaust with docker

## Key Links

- [docker reference docs](https://docs.docker.com/reference/)


## Usage patterns

Pull image from docker hub

```bash
docker pull debian:bookworm
```

List docker images

```bash
docker images
```

Execute a command in a running container


```bash

# insert here

```


Create and run a new container from an image

```bash
docker run -it --rm debian:bookworm
```

Create and run a new temporary container and run a command with volume

```bash
docker run -v `pwd`/build:/cyfaust/build -it --rm cyfaust:bookworm make
```

Use mount instead of `-v` volumes

```bash
docker run --mount type=bind,src=`pwd`/wheels,dst=/cyfaust/wheels -it --rm cyfaust:bookwork make wheel
```


Remove specific image

```bash
docker rmi <image-id>
```


Remove dangling images

```bash
docker image prune
```

Show build cache

```bash
docker system df
```

To prune everything

```bash
docker system prune -a
```

