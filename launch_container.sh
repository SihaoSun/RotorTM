#!/bin/sh
HOST_DIR=$1
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
if ! test -f XAUTH; then
	sudo touch $XAUTH
	sudo xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | sudo xauth -f $XAUTH nmerge -
fi

# Check nVidia GPU docker support
# More info: http://wiki.ros.org/docker/Tutorials/Hardware%20Acceleration
NVIDIA_DOCKER_REQUIREMENT='nvidia-docker2'
GPU_OPTIONS=""
if dpkg --get-selections | grep -q "^$NVIDIA_DOCKER_REQUIREMENT[[:space:]]*install$" >/dev/null; then
  echo "Starting docker with nVidia support!"
  GPU_OPTIONS="--gpus all --runtime=nvidia"
fi

# Check if using tmux conf
TMUX_CONF_FILE=$HOME/.tmux.conf
TMUX_CONF=""
if test -f ${TMUX_CONF_FILE}; then
  echo "Loading tmux config: ${TMUX_CONF_FILE}"
  TMUX_CONF="--volume=$TMUX_CONF_FILE:/home/RotorTM/.tmux.conf:ro"
fi

docker run --privileged --rm -it \
           --volume $HOST_DIR:/home/RotorTM/catkin_ws/src/host_dir:rw \
           --volume=$XSOCK:$XSOCK:rw \
           --volume=$XAUTH:$XAUTH:rw \
           --volume=/dev:/dev:rw \
           ${TMUX_CONF} \
           ${GPU_OPTIONS} \
           --shm-size=1gb \
           --env="XAUTHORITY=${XAUTH}" \
           --env="DISPLAY=${DISPLAY}" \
           --env=TERM=xterm-256color \
           --env=QT_X11_NO_MITSHM=1 \
           --net=host \
           -u "RotorTM"  \
           rotor_tm:latest \
           bash
