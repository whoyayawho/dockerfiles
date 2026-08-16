# ROS/ROS 2 Docker Images

ROS 1과 ROS 2 개발 환경을 위한 Dockerfile 모음입니다. 각 이미지는 ROS 워크스페이스와 개발용 편의 명령을 포함합니다.

**Docker Hub 저장소:** [whoyayawho/ros](https://hub.docker.com/r/whoyayawho/ros)

## 목차

- [프로젝트 파일](#프로젝트-파일)
- [이미지 정의](#이미지-정의)
- [멀티 플랫폼 빌드 및 테스트](#멀티-플랫폼-빌드-및-테스트)
- [Docker Hub에 최종 태그 게시](#docker-hub에-최종-태그-게시)
- [태그 지정 방법](#태그-지정-방법)
- [컨테이너 실행](#컨테이너-실행)
- [개발 환경](#개발-환경)
- [파일 관리 설정](#파일-관리-설정)

---

## 프로젝트 파일

| 파일                                                               | 역할                                                 |
| ------------------------------------------------------------------ | ---------------------------------------------------- |
| [`Dockerfile_ros_melodic`](./Dockerfile_ros_melodic)               | ROS 1 Melodic 개발 이미지                            |
| [`Dockerfile_ros_noetic`](./Dockerfile_ros_noetic)                 | ROS 1 Noetic 개발 이미지                             |
| [`Dockerfile_ros2_dashing`](./Dockerfile_ros2_dashing)             | ROS 2 Dashing 개발 이미지                            |
| [`Dockerfile_ros2_foxy`](./Dockerfile_ros2_foxy)                   | ROS 2 Foxy 개발 이미지                               |
| [`Dockerfile_ros2_humble`](./Dockerfile_ros2_humble)               | ROS 2 Humble 개발 이미지                             |
| [`Dockerfile_ros2_jazzy`](./Dockerfile_ros2_jazzy)                 | ROS 2 Jazzy 개발 이미지                              |
| [`Dockerfile_ros2_jazzy_pytorch`](./Dockerfile_ros2_jazzy_pytorch) | NVIDIA PyTorch 기반 ROS 2 Jazzy 개발 이미지          |
| [`docker_build.sh`](./docker_build.sh)                             | x86 PC용 멀티 플랫폼 빌드·테스트·게시 스크립트       |
| [`docker_run.sh`](./docker_run.sh)                                 | 컨테이너 실행 및 호스트 장치 자동 연결 스크립트      |
| [`.dockerignore`](./.dockerignore)                                 | Docker 빌드 컨텍스트 제외 규칙                       |
| [`.gitignore`](./.gitignore)                                       | 로컬 자격 증명, 아카이브 및 로그 제외 규칙           |
| [`.gitattributes`](./.gitattributes)                               | Dockerfile, 셸 스크립트 및 Markdown의 LF 줄바꿈 유지 |
| [`README.md`](./README.md)                                         | 프로젝트 사용 설명서                                 |

---

## 이미지 정의

### ROS 1

| Dockerfile               | 기반 OS      | ROS                  | Docker Hub 최종 태그     | 지원 상태 |
| ------------------------ | ------------ | -------------------- | ------------------------ | --------- |
| `Dockerfile_ros_melodic` | Ubuntu 18.04 | Melodic Desktop Full | `whoyayawho/ros:melodic` | EOL       |
| `Dockerfile_ros_noetic`  | Ubuntu 20.04 | Noetic Desktop Full  | `whoyayawho/ros:noetic`  | EOL       |

### ROS 2

| Dockerfile                      | 기반 이미지                         | ROS             | Docker Hub 최종 태그           | 지원 상태                      |
| ------------------------------- | ----------------------------------- | --------------- | ------------------------------ | ------------------------------ |
| `Dockerfile_ros2_dashing`       | Ubuntu 18.04                        | Dashing Desktop | `whoyayawho/ros:dashing`       | EOL                            |
| `Dockerfile_ros2_foxy`          | Ubuntu 20.04                        | Foxy Desktop    | `whoyayawho/ros:foxy`          | EOL                            |
| `Dockerfile_ros2_humble`        | Ubuntu 22.04                        | Humble Desktop  | `whoyayawho/ros:humble`        | 2027년 5월까지 지원            |
| `Dockerfile_ros2_jazzy`         | Ubuntu 24.04                        | Jazzy Desktop   | `whoyayawho/ros:jazzy`         | 2029년 5월까지 지원            |
| `Dockerfile_ros2_jazzy_pytorch` | NVIDIA PyTorch 25.11 / Ubuntu 24.04 | Jazzy Desktop   | `whoyayawho/ros:jazzy_pytorch` | Jazzy 기준 2029년 5월까지 지원 |

각 Docker Hub 최종 태그는 `linux/amd64`와 `linux/arm64`를 포함하는 하나의 image index로 게시합니다.

---

## 멀티 플랫폼 빌드 및 테스트

`docker_build.sh`는 x86-64 Linux PC 한 대에서 현재 7개 Dockerfile을 다음 두 플랫폼으로 빌드합니다.

- `linux/amd64`: 일반적인 x86-64 PC
- `linux/arm64`: Jetson용 ARM64 이미지

이 문서는 x86-64 Ubuntu 또는 x86-64 WSL 2 배포판 내부에 직접 설치한 Docker Engine을 기준으로 하며 Docker Desktop은 사용하지 않습니다.

### 준비 사항

- 실행 중인 Docker Engine
- Docker Buildx 플러그인
- QEMU `binfmt` 등록에 필요한 privileged 컨테이너 실행 권한
- 모든 기반 이미지와 APT 패키지를 받을 수 있는 네트워크 및 충분한 저장 공간

스크립트는 실행 환경이 Linux x86-64인지 검사합니다. ARM64 컨테이너를 직접 실행할 수 없는 경우 `tonistiigi/binfmt`를 privileged 컨테이너로 실행해 ARM64 QEMU를 등록하고, `ros-multiarch-builder`라는 Buildx 빌더를 생성하거나 기존 빌더를 재사용합니다.

### 로컬 빌드 및 smoke test

저장소 루트에서 다음 명령을 실행합니다.

```bash
bash ./docker_build.sh
```

이 명령은 Docker Hub에 아무것도 올리지 않습니다. 각 Dockerfile을 플랫폼별로 따로 빌드하고 다음 형식의 로컬 테스트 태그에 불러온 후 smoke test를 실행합니다.

```text
ros:<tag>-amd64-test
ros:<tag>-arm64-test
```

예를 들어 Jazzy에는 다음 두 로컬 태그가 생성됩니다.

```text
ros:jazzy-amd64-test
ros:jazzy-arm64-test
```

이 로컬 태그는 Docker Hub 태그가 아니며 최종 멀티 플랫폼 태그를 구성하는 용도로 게시되지 않습니다.

### 자동 smoke test

| Dockerfile | 로컬 태그의 `<tag>` | 환경 설정 파일 | 검사 내용 |
| --- | --- | --- | --- |
| `Dockerfile_ros_melodic` | `melodic` | `/opt/ros/melodic/setup.bash` | 아키텍처 및 `rosversion -d` |
| `Dockerfile_ros_noetic` | `noetic` | `/opt/ros/noetic/setup.bash` | 아키텍처 및 `rosversion -d` |
| `Dockerfile_ros2_dashing` | `dashing` | `/opt/ros/dashing/setup.bash` | 아키텍처, `ROS_DISTRO` 및 `ros2 --help` |
| `Dockerfile_ros2_foxy` | `foxy` | `/opt/ros/foxy/setup.bash` | 아키텍처, `ROS_DISTRO` 및 `ros2 --help` |
| `Dockerfile_ros2_humble` | `humble` | `/opt/ros/humble/setup.bash` | 아키텍처, `ROS_DISTRO` 및 `ros2 --help` |
| `Dockerfile_ros2_jazzy` | `jazzy` | `/opt/ros/jazzy/setup.bash` | 아키텍처, `ROS_DISTRO` 및 `ros2 --help` |
| `Dockerfile_ros2_jazzy_pytorch` | `jazzy_pytorch` | `/opt/ros/jazzy/setup.bash` | Jazzy 검사 및 `import torch` |

하나라도 빌드 또는 smoke test에 실패하면 스크립트는 실패 목록을 출력하고 0이 아닌 종료 코드로 끝납니다. `--push`를 지정했더라도 이 경우 Docker Hub 게시 단계는 실행하지 않습니다.

### ARM64 테스트 범위

x86 PC의 ARM64 테스트는 QEMU에서 실행되므로 이미지 아키텍처, ROS 환경 및 기본 명령 실행 여부를 검사할 수 있습니다. 실제 Jetson의 GPU, CUDA, NVIDIA Container Runtime, X11, 오디오 및 USB 동작까지 검증하지는 않습니다. 최종 배포 전에는 실제 Jetson에서도 필요한 기능을 검사해야 합니다.

---

## Docker Hub에 최종 태그 게시

먼저 Docker Hub에 로그인합니다.

```bash
docker login
```

이어서 `--push`를 지정합니다.

```bash
bash ./docker_build.sh --push
```

`--push` 모드도 먼저 모든 amd64/arm64 빌드와 smoke test를 수행합니다. 모두 통과하면 같은 Buildx 빌더의 캐시를 사용해 두 플랫폼을 함께 빌드하고 배포판별 최종 태그로 직접 push합니다.

```text
whoyayawho/ros:<tag>
└── image index
    ├── linux/amd64
    └── linux/arm64
```

Docker Hub에는 `melodic-amd64`, `melodic-arm64` 같은 아키텍처별 태그를 만들지 않습니다. 현재 Dockerfile 전체를 게시하면 다음 7개 최종 태그가 생성되며, 각 태그 내부에서 두 플랫폼을 지원합니다.

```text
whoyayawho/ros:melodic
whoyayawho/ros:noetic
whoyayawho/ros:dashing
whoyayawho/ros:foxy
whoyayawho/ros:humble
whoyayawho/ros:jazzy
whoyayawho/ros:jazzy_pytorch
```

Jazzy 게시 결과는 다음과 같이 확인합니다.

```bash
docker buildx imagetools inspect whoyayawho/ros:jazzy
```

출력에 `linux/amd64`와 `linux/arm64`가 모두 있어야 합니다. 이후 플랫폼을 지정하지 않고 같은 태그를 받으면 Docker가 호스트 아키텍처에 맞는 이미지를 선택합니다.

```bash
docker pull whoyayawho/ros:jazzy
```

- x86-64 PC: `linux/amd64` 선택
- Jetson: `linux/arm64` 선택

### Jazzy + PyTorch 기반 이미지 선택

`Dockerfile_ros2_jazzy_pytorch`는 BuildKit의 `TARGETARCH`에 따라 기반 이미지를 자동으로 선택합니다.

| 대상 플랫폼 | 기반 이미지 |
| --- | --- |
| `linux/amd64` | `nvcr.io/nvidia/pytorch:25.11-py3` |
| `linux/arm64` | `nvcr.io/nvidia/pytorch:25.11-py3-igpu` |

두 기본값은 Dockerfile의 `PYTORCH_BASE_AMD64`와 `PYTORCH_BASE_ARM64` 빌드 인수로 매개변수화되어 있습니다. PyTorch 컨테이너 25.11의 Jetson용 이미지는 JetPack 7.0에 대응하므로 대상 Jetson의 JetPack 버전도 일치해야 합니다. 자세한 내용은 [NVIDIA PyTorch 25.11 릴리스 노트](https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/rel-25-11.html)와 [NVIDIA PyTorch for Jetson 호환성 표](https://docs.nvidia.com/deeplearning/frameworks/install-pytorch-jetson-platform-release-notes/pytorch-jetson-rel.html)를 참고하세요.

Docker는 image index에서 OS와 CPU 아키텍처를 기준으로 이미지를 선택하며 장치가 Jetson인지까지 판별하지는 않습니다. 이 저장소는 `linux/arm64` 최종 사용 대상을 Jetson으로 한정합니다.

---

## 태그 지정 방법

`docker tag`는 기존 로컬 이미지에 새 참조 이름을 추가합니다.

```bash
docker tag SOURCE_IMAGE:SOURCE_TAG TARGET_IMAGE:TARGET_TAG
```

예를 들어 로컬 Foxy amd64 테스트 이미지에 다른 로컬 태그를 추가하려면 다음과 같이 실행합니다.

```bash
docker tag ros:foxy-amd64-test ros:foxy-local
docker image ls ros
```

이미지 ID를 사용할 수도 있습니다.

```bash
docker image ls
docker tag IMAGE_ID ros:foxy-local
```

`docker tag`는 이미지 내용을 변경하거나 여러 플랫폼을 합치지 않으며 Docker Hub에 업로드하지도 않습니다. 단일 플랫폼 로컬 이미지를 `whoyayawho/ros:foxy` 같은 최종 태그로 직접 push하면 기존 멀티 플랫폼 태그가 단일 플랫폼 이미지로 바뀔 수 있습니다. 최종 멀티 플랫폼 태그는 `docker_build.sh --push`로 게시합니다.

---

## 컨테이너 실행

`docker_run.sh`는 Bash 환경에서 실행해야 하며 기본값은 다음과 같습니다.

| 환경변수         | 기본값                 | 역할             |
| ---------------- | ---------------------- | ---------------- |
| `CONTAINER_NAME` | `ros2_jazzy`           | 새 컨테이너 이름 |
| `IMAGE_NAME`     | `whoyayawho/ros:jazzy` | 실행할 이미지    |

```bash
# 기본 Jazzy 이미지 실행
bash ./docker_run.sh

# Humble 이미지 실행
CONTAINER_NAME=ros2_humble \
IMAGE_NAME=whoyayawho/ros:humble \
bash ./docker_run.sh

# Jazzy + PyTorch 이미지 실행
CONTAINER_NAME=ros2_jazzy_pytorch \
IMAGE_NAME=whoyayawho/ros:jazzy_pytorch \
bash ./docker_run.sh
```

최종 Docker Hub 태그가 멀티 플랫폼 image index이면 `docker_run.sh`에 `--platform`을 추가할 필요가 없습니다. Docker가 x86 PC에서는 amd64, Jetson에서는 arm64 이미지를 자동으로 선택합니다.

스크립트의 실제 동작은 다음과 같습니다.

- `--ipc=host`, `--network=host`, `--privileged`, `-it`를 항상 사용합니다.
- NVIDIA GPU와 NVIDIA Container Runtime이 모두 감지되면 GPU 옵션을 추가합니다.
- Jetson에서는 `--runtime nvidia`와 NVIDIA 환경변수를 사용하며, 일반 NVIDIA GPU에서는 추가로 `--gpus all`을 사용합니다.
- `DISPLAY`가 설정되어 있으면 컨테이너에 전달하고, X11 소켓과 Xauthority 파일은 각각 존재할 때 마운트합니다.
- `/dev/snd`가 있으면 ALSA 장치를 연결하고, PulseAudio 소켓과 쿠키는 각각 존재할 때 마운트합니다.
- `/dev/bus/usb`가 있으면 USB 버스를 마운트합니다.
- 사용할 수 없는 장치는 오류로 중단하지 않고 경고 후 건너뜁니다.
- 동일 이름의 컨테이너가 이미 있으면 삭제하거나 교체하지 않고 오류로 종료합니다.

`--network=host`는 Docker Engine이 실행되는 Linux 호스트의 네트워크 네임스페이스를 사용합니다. WSL 2 배포판 내부에서 Docker Engine을 실행한다면 여기서 호스트는 해당 WSL 2 Linux 환경을 의미합니다.

> `--privileged`, 호스트 네트워크, 호스트 IPC 및 장치 마운트는 컨테이너에 넓은 권한을 부여합니다. 신뢰할 수 있는 이미지만 실행하세요. 또한 Jetson 감지는 실행 옵션만 구성하므로 PyTorch 이미지는 호스트의 JetPack 버전과 호환되어야 합니다.

---

## 개발 환경

### ROS 편의 별칭 (Aliases)

각 Dockerfile은 root 사용자의 `.bashrc`에 다음 별칭을 추가합니다.

```bash
cw   # Change to Workspace - 워크스페이스로 이동
     # ROS1: cd ~/ros_ws
     # ROS2: cd ~/ros2_ws

cs   # Change to Source - 소스 디렉터리로 이동
     # ROS1: cd ~/ros_ws/src
     # ROS2: cd ~/ros2_ws/src

cm   # Compile and Make - 빌드 후 .bashrc 다시 로드
     # ROS1: cd ~/ros_ws && catkin_make && source ~/.bashrc
     # ROS2: cd ~/ros2_ws && colcon build --symlink-install \
     #       --cmake-args -DBUILD_SHARED_LIBS=ON && source ~/.bashrc
```

이미지를 만들 때는 `src` 디렉터리만 생성됩니다. 첫 빌드 전에는 `.bashrc`가 참조하는 `devel/setup.bash` 또는 `install/setup.bash`가 없어서 셸 시작 시 관련 오류가 표시될 수 있습니다. `cm`으로 워크스페이스를 빌드하면 나머지 디렉터리와 setup 파일이 생성됩니다.

### 워크스페이스 구조

**ROS1 (Melodic, Noetic):**

```text
/root/ros_ws/
├── src/          # 소스 코드
├── build/        # catkin_make 실행 후 생성
└── devel/        # catkin_make 실행 후 생성
```

**ROS2 (Dashing, Foxy, Humble, Jazzy):**

```text
/root/ros2_ws/
├── src/          # 소스 코드
├── build/        # colcon build 실행 후 생성
├── install/      # colcon build 실행 후 생성
└── log/          # colcon build 실행 후 생성
```

---

## 파일 관리 설정

- `.gitattributes`는 셸 스크립트, Dockerfile 및 Markdown을 LF 줄바꿈으로 유지합니다.
- `.gitignore`와 `.dockerignore`는 로컬 키, 토큰, `.env` 파일, 다운로드 아카이브 및 로그를 제외합니다.
- 두 셸 스크립트는 문서 예시처럼 `bash ./docker_build.sh`와 `bash ./docker_run.sh`로 실행할 수 있습니다. 직접 실행하려면 실행 권한이 필요합니다.
