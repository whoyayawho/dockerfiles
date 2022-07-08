#!/bin/bash

USER_NAME=smkang
CONTAINER_NAME=ros2_dashing
IMAGE_NAME=smkang0521/ros:dashing

docker run --name=${CONTAINER_NAME} --ipc=host --net=host --privileged -it \
--gpus all \
-e DISPLAY=$DISPLAY \
-e NVIDIA_VISIBLE_DEVICES=all \
-e NVIDIA_DRIVER_CAPABILITIES=all \
-e QT_X11_NO_MITSHM=1 \
-e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
-v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native:rw \
-v /home/${USER_NAME}/.config/pulse/cookie:/root/.config/pulse/cookie \
-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
${IMAGE_NAME} /bin/bash
