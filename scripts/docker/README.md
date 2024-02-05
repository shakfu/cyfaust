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






Create and run a new container from an image

```bash
docker run -it --rm debian:bookworm
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

