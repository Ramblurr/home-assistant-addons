build:
	podman run \
  --rm \
  -it \
  --name builder \
  --privileged \
  -v $(shell pwd):/data \
  -v /run/user/1000/podman/podman.sock:/var/run/docker.sock:ro \
  docker.io/homeassistant/amd64-builder \
  -t /data \
  --all \
  --test \
  -i ramblurr/borgbackup-add-on \
  -d local --amd64
