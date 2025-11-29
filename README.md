# dockerfiles

## 빌드

```
$ docker build --network=host --no-cache -t smkang0521/ros:foxy -f Dockerfile_ros2_foxy .
```

## ssh 키 이용한 빌드

```
# 키 생성 : ssh-keygen -t rsa -b 4096 -f ./id_rsa_docker_build -N ""
DOCKER_BUILDKIT=1 docker build --ssh default=./id_rsa_docker_build --network=host --no-cache -t smkang0521/ros:humble_spadi -f Dockerfile_ros2_humble_spadi .
```

## dockerhub 이미지 업로드

```
$ docker login
$ docker tag ros:foxy smkang0521/ros:foxy
$ docker push smkang0521/ros:foxy
```
