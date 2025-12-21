#!/bin/bash

# 설정
CONTAINER_NAME=ros2_humble
IMAGE_NAME=smkang0521/ros:humble
USE_NVIDIA_GPU=true

# GPU 옵션 설정
if [ "$USE_NVIDIA_GPU" = "true" ]; then
    GPU_OPTIONS="--gpus all \
-e NVIDIA_VISIBLE_DEVICES=all \
-e NVIDIA_DRIVER_CAPABILITIES=all"
else
    GPU_OPTIONS=""
fi

docker run --name=${CONTAINER_NAME} --ipc=host --net=host --privileged -it \
$GPU_OPTIONS \
--device /dev/snd \
-e DISPLAY=$DISPLAY \
-e QT_X11_NO_MITSHM=1 \
-e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
-v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
-v /home/${USER}/.config/pulse/cookie:/root/.config/pulse/cookie \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v /dev/bus/usb:/dev/bus/usb \
--group-add $(getent group audio | cut -d: -f3) \
${IMAGE_NAME} /bin/bash
