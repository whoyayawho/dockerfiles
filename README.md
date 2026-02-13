# ROS/ROS2 Docker Images

ROS(Robot Operating System) 및 ROS2 개발을 위한 Docker 이미지 모음입니다.

**DockerHub:** [smkang0521/ros](https://hub.docker.com/r/smkang0521/ros)

## 📋 목차

- [사용 가능한 이미지](#사용-가능한-이미지)
- [빌드 방법](#빌드-방법)
- [멀티 플랫폼 빌드](#멀티-플랫폼-빌드)
- [DockerHub 업로드](#dockerhub-업로드)
- [컨테이너 실행](#컨테이너-실행)
- [SPADI 시스템 전용 안내](#spadi-시스템-전용-안내)
- [개발 환경](#개발-환경)

---

## 사용 가능한 이미지

### ROS 1 (레거시)

| Dockerfile               | Ubuntu | ROS 버전 | DockerHub 태그           | 설명                      |
| ------------------------ | ------ | -------- | ------------------------ | ------------------------- |
| `Dockerfile_ros_melodic` | 18.04  | Melodic  | `smkang0521/ros:melodic` | ROS1 Melodic Desktop Full |
| `Dockerfile_ros_noetic`  | 20.04  | Noetic   | `smkang0521/ros:noetic`  | ROS1 Noetic Desktop Full  |

### ROS 2

| Dockerfile                       | Ubuntu | ROS 버전         | DockerHub 태그                  | 설명                           |
| -------------------------------- | ------ | ---------------- | ------------------------------- | ------------------------------ |
| `Dockerfile_ros2_dashing`        | 18.04  | Dashing          | `smkang0521/ros:dashing`        | ROS2 Dashing Desktop           |
| `Dockerfile_ros2_foxy`           | 20.04  | Foxy             | `smkang0521/ros:foxy`           | ROS2 Foxy Desktop              |
| `Dockerfile_ros2_humble`         | 22.04  | Humble           | `smkang0521/ros:humble`         | ROS2 Humble Desktop            |
| `Dockerfile_ros2_humble_spadi`   | 22.04  | Humble + SPADI   | `smkang0521/ros:humble_spadi`   | SPADI 로봇 시스템 전용         |
| `Dockerfile_ros2_jazzy`          | 24.04  | Jazzy            | `smkang0521/ros:jazzy`          | ROS2 Jazzy Desktop             |
| `Dockerfile_ros2_jazzy_tensorrt` | 24.04  | Jazzy + TensorRT | `smkang0521/ros:jazzy_tensorrt` | ROS2 Jazzy + TensorRT (GPU/AI) |

---

## 빌드 방법

### 일반 빌드

기본적인 Docker 이미지 빌드 명령어입니다.

```bash
# ROS1 Melodic
docker build --network=host --no-cache -t smkang0521/ros:melodic -f Dockerfile_ros_melodic .

# ROS1 Noetic
docker build --network=host --no-cache -t smkang0521/ros:noetic -f Dockerfile_ros_noetic .

# ROS2 Dashing
docker build --network=host --no-cache -t smkang0521/ros:dashing -f Dockerfile_ros2_dashing .

# ROS2 Foxy
docker build --network=host --no-cache -t smkang0521/ros:foxy -f Dockerfile_ros2_foxy .

# ROS2 Humble
docker build --network=host --no-cache -t smkang0521/ros:humble -f Dockerfile_ros2_humble .

# ROS2 Humble SPADI
docker build --network=host --no-cache -t smkang0521/ros:humble_spadi -f Dockerfile_ros2_humble_spadi .

# ROS2 Jazzy
docker build --network=host --no-cache -t smkang0521/ros:jazzy -f Dockerfile_ros2_jazzy .

# ROS2 Jazzy TensorRT
docker build --network=host --no-cache -t smkang0521/ros:jazzy_tensorrt -f Dockerfile_ros2_jazzy_tensorrt .
```

### 빌드 옵션 설명

- `--network=host`: 호스트 네트워크 사용
- `--no-cache`: 캐시 없이 빌드
- `-t`: 이미지 태그 지정
- `-f`: 사용할 Dockerfile 지정

---

## 멀티 플랫폼 빌드

하나의 Dockerfile로 `amd64`(x86_64)와 `arm64`(Jetson 등) 이미지를 동시에 빌드하여 DockerHub에 업로드할 수 있습니다.
`docker pull` 시 호스트 아키텍처에 맞는 이미지가 자동으로 다운로드됩니다.

### 1. 멀티 플랫폼 빌더 생성 (최초 1회)

```bash
# 멀티 플랫폼 지원 빌더 생성
docker buildx create --name multiarch --driver docker-container --use

# 빌더 부트스트랩 (QEMU 에뮬레이터 설정 포함)
docker buildx inspect --bootstrap
```

### 2. 멀티 플랫폼 빌드 및 업로드

```bash
# ROS2 Jazzy TensorRT (amd64 + arm64)
docker buildx build --platform linux/amd64,linux/arm64 \
  --network=host --no-cache \
  -t smkang0521/ros:jazzy_tensorrt \
  -f Dockerfile_ros2_jazzy_tensorrt \
  --push .
```

### 참고사항

- `--push`: `docker-container` 드라이버는 로컬 저장을 지원하지 않으므로 레지스트리(DockerHub)로 직접 push해야 합니다
- `--load`: 로컬에 이미지를 저장하려면 `--push` 대신 사용할 수 있지만, 단일 플랫폼만 지원됩니다
- 타 아키텍처 빌드는 QEMU 에뮬레이션으로 진행되므로 네이티브 빌드보다 느릴 수 있습니다

---

## DockerHub 업로드

빌드한 이미지를 DockerHub에 업로드하는 방법입니다.

```bash
# 1. DockerHub 로그인
docker login

# 2. 이미지 태그 변경 (필요한 경우)
docker tag ros:foxy smkang0521/ros:foxy

# 3. DockerHub에 푸시
docker push smkang0521/ros:foxy
```

### 전체 이미지 업로드 예시

```bash
# 모든 이미지 푸시
docker push smkang0521/ros:melodic
docker push smkang0521/ros:noetic
docker push smkang0521/ros:dashing
docker push smkang0521/ros:foxy
docker push smkang0521/ros:humble
docker push smkang0521/ros:humble_spadi
docker push smkang0521/ros:jazzy
docker push smkang0521/ros:jazzy_tensorrt
```

---

## 컨테이너 실행

### docker_run.sh 사용 (권장)

편리한 실행 스크립트를 제공합니다.

```bash
./docker_run.sh
```

이 스크립트는 다음 기능을 자동으로 설정합니다:

- GPU 지원 (`--gpus all`)
- X11 GUI 지원 (그래픽 애플리케이션 실행 가능)
- USB 디바이스 접근
- PulseAudio (오디오 지원)
- Host 네트워크 모드

### 주요 옵션 설명

- `--gpus all`: 모든 GPU 사용 (CUDA 지원)
- `--network host`: 호스트 네트워크 사용
- `--privileged`: 컨테이너에 특권 부여 (하드웨어 접근)
- `-e DISPLAY`: X11 디스플레이 설정
- `-v /tmp/.X11-unix`: X11 소켓 마운트
- `-v /dev/bus/usb`: USB 디바이스 접근

---

## SPADI 시스템 전용 안내

### 빌드 전 패키지 수정 필요

SPADI 이미지를 빌드하기 전에 다음 파일들을 수정해야 합니다:

1. **merge launch 파일**
   - `calibration_file_path` 변경: `"/root/soslab_files/calibration_params.json"`

2. **카메라 launch 파일**
   - `json_path` 변경: `"/root/soslab_files/calibration_params.json"`

3. **카메라 config 파일**
   - `trigger_mode` 변경: `true`

### 포함된 ROS2 패키지

SPADI 이미지에는 다음 ROS2 패키지가 자동으로 빌드됩니다:

- **iahrs_ros2**: IMU/AHRS 센서 드라이버
- **merge_image_pointcloud**: 이미지와 포인트클라우드 병합
- **ml_ros2**: ML-X ROS2 패키지
- **pylon_ros2**: Basler Pylon 카메라 드라이버

### Cyclone DDS 설정

SPADI 이미지는 Cyclone DDS를 기본 미들웨어로 사용합니다:

- 네트워크 인터페이스: `192.168.2.20`
- 멀티캐스트 활성화
- RMW 구현: `rmw_cyclonedds_cpp`

---

## 개발 환경

### ROS 편의 별칭 (Aliases)

효율적인 개발을 위한 별칭이 설정되어 있습니다:

```bash
cw   # Change to Workspace - 워크스페이스로 이동
     # ROS1: cd ~/ros_ws
     # ROS2: cd ~/ros2_ws

cs   # Change to Source - 소스 디렉토리로 이동
     # ROS1: cd ~/ros_ws/src
     # ROS2: cd ~/ros2_ws/src

cm   # Compile and Make - 빌드 및 환경 설정
     # ROS1: cd ~/ros_ws && catkin_make && source devel/setup.bash
     # ROS2: cd ~/ros2_ws && colcon build --symlink-install && source install/setup.bash
```

### 워크스페이스 구조

**ROS1 (Melodic, Noetic):**

```
/root/ros_ws/
├── src/          # 소스 코드
├── build/        # 빌드 파일
└── devel/        # 개발 환경
```

**ROS2 (Dashing, Foxy, Humble, Jazzy):**

```
/root/ros2_ws/
├── src/          # 소스 코드
├── build/        # 빌드 파일
├── install/      # 설치 환경
└── log/          # 로그 파일
```
