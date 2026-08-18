#!/bin/bash

set -euo pipefail

# 환경변수로 기본 설정을 덮어쓸 수 있습니다.
# 예: CONTAINER_NAME=ros2_jazzy IMAGE_NAME=whoyayawho/ros:jazzy ./docker_run.sh
CONTAINER_NAME="${CONTAINER_NAME:-ros2_jazzy}"
IMAGE_NAME="${IMAGE_NAME:-whoyayawho/ros:jazzy}"

log() {
    printf '[docker_run] %s\n' "$*"
}

warn() {
    printf '[docker_run] 경고: %s\n' "$*" >&2
}

die() {
    printf '[docker_run] 오류: %s\n' "$*" >&2
    exit 1
}

is_jetson_host() {
    if [[ -f /etc/nv_tegra_release ]]; then
        return 0
    fi

    if [[ -r /proc/device-tree/model ]]; then
        local device_model
        device_model="$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || true)"
        [[ "${device_model,,}" == *jetson* ]] && return 0
    fi

    return 1
}

command -v docker >/dev/null 2>&1 || die "docker 명령을 찾을 수 없습니다."
docker info >/dev/null 2>&1 || die "Docker 데몬에 연결할 수 없습니다."

# 같은 이름의 컨테이너가 있으면 삭제하거나 교체하지 않고 종료합니다.
if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    die "동일 이름의 컨테이너가 이미 존재합니다: '$CONTAINER_NAME'. 이름을 바꾸거나 기존 컨테이너를 직접 정리하세요."
fi

docker_args=(
    run
    --name "$CONTAINER_NAME"
    --ipc=host
    --network=host
    --privileged
    -it
)

# NVIDIA GPU와 Jetson을 자동 판별해 적절한 Docker GPU 옵션을 추가합니다.
docker_runtimes="$(docker info --format '{{json .Runtimes}}' 2>/dev/null || true)"
nvidia_runtime_available=false
if [[ "$docker_runtimes" == *'"nvidia"'* ]]; then
    nvidia_runtime_available=true
fi

if is_jetson_host; then
    log "NVIDIA Jetson 환경을 감지했습니다."
    if [[ "$nvidia_runtime_available" == true ]]; then
        docker_args+=(
            --runtime nvidia
            --env NVIDIA_VISIBLE_DEVICES=all
            --env NVIDIA_DRIVER_CAPABILITIES=all
        )
    else
        warn "NVIDIA Container Runtime을 찾을 수 없어 Jetson GPU 연결을 건너뜁니다."
    fi
else
    nvidia_smi_command="$(command -v nvidia-smi 2>/dev/null || true)"
    if [[ -z "$nvidia_smi_command" && -x /usr/lib/wsl/lib/nvidia-smi ]]; then
        nvidia_smi_command=/usr/lib/wsl/lib/nvidia-smi
    fi

    if [[ -n "$nvidia_smi_command" ]] && "$nvidia_smi_command" -L >/dev/null 2>&1; then
        log "NVIDIA GPU를 감지했습니다."

        # 최신 Docker는 NVIDIA CDI를 통해 기본 runc에서도 --gpus 요청을 처리할 수
        # 있으므로, docker info에 'nvidia' 런타임이 없다는 이유만으로 GPU 연결을
        # 건너뛰면 안 됩니다. 구형 설정에서 nvidia 런타임이 등록되어 있으면
        # 명시적으로 사용하고, 그렇지 않아도 Docker에 GPU 장치를 요청합니다.
        if [[ "$nvidia_runtime_available" == true ]]; then
            docker_args+=(--runtime nvidia)
        else
            log "NVIDIA CDI/기본 런타임을 통해 GPU 연결을 요청합니다."
        fi

        docker_args+=(
            --gpus all
            --env NVIDIA_VISIBLE_DEVICES=all
            --env NVIDIA_DRIVER_CAPABILITIES=all
        )
    else
        log "NVIDIA GPU를 찾지 못해 GPU 옵션 없이 실행합니다."
    fi
fi

# X11 GUI: 호스트에서 사용할 수 있으면 항상 연결합니다.
if [[ -n "${DISPLAY:-}" ]]; then
    docker_args+=(
        --env "DISPLAY=$DISPLAY"
        --env QT_X11_NO_MITSHM=1
    )

    if [[ -d /tmp/.X11-unix ]]; then
        docker_args+=(--volume /tmp/.X11-unix:/tmp/.X11-unix)
    else
        warn "/tmp/.X11-unix가 없어 X11 소켓을 마운트하지 않습니다."
    fi

    xauthority="${XAUTHORITY:-}"
    if [[ -z "$xauthority" && -n "${HOME:-}" ]]; then
        xauthority="$HOME/.Xauthority"
    fi
    if [[ -n "$xauthority" && -f "$xauthority" ]]; then
        docker_args+=(
            --env XAUTHORITY=/root/.Xauthority
            --volume "$xauthority:/root/.Xauthority:ro"
        )
    else
        warn "Xauthority 파일이 없어 X11 인증 설정을 건너뜁니다."
    fi
else
    warn "DISPLAY가 설정되지 않아 X11 옵션을 건너뜁니다."
fi

# 오디오: 호스트에서 사용할 수 있으면 항상 연결합니다.
if [[ -e /dev/snd ]]; then
    docker_args+=(--device /dev/snd)

    if command -v getent >/dev/null 2>&1; then
        audio_entry="$(getent group audio 2>/dev/null || true)"
        if [[ -n "$audio_entry" ]]; then
            IFS=: read -r -a audio_fields <<< "$audio_entry"
            audio_gid="${audio_fields[2]:-}"
            if [[ "$audio_gid" =~ ^[0-9]+$ ]]; then
                docker_args+=(--group-add "$audio_gid")
            fi
        fi
    fi
else
    warn "/dev/snd가 없어 ALSA 장치를 추가하지 않습니다."
fi

pulse_socket=""
if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    pulse_socket="$XDG_RUNTIME_DIR/pulse/native"
fi

if [[ -n "$pulse_socket" && -S "$pulse_socket" ]]; then
    docker_args+=(
        --env "PULSE_SERVER=unix:$pulse_socket"
        --volume "$pulse_socket:$pulse_socket"
    )

    pulse_cookie="${PULSE_COOKIE:-}"
    if [[ -z "$pulse_cookie" && -n "${HOME:-}" ]]; then
        pulse_cookie="$HOME/.config/pulse/cookie"
    fi
    if [[ -n "$pulse_cookie" && -f "$pulse_cookie" ]]; then
        docker_args+=(--volume "$pulse_cookie:/root/.config/pulse/cookie:ro")
    fi
else
    warn "PulseAudio 소켓을 찾을 수 없어 PulseAudio 설정을 건너뜁니다."
fi

# USB: 호스트에서 사용할 수 있으면 항상 연결합니다.
if [[ -d /dev/bus/usb ]]; then
    docker_args+=(--volume /dev/bus/usb:/dev/bus/usb)
else
    warn "/dev/bus/usb가 없어 USB 마운트를 건너뜁니다."
fi

log "컨테이너를 실행합니다: '$CONTAINER_NAME' (이미지: '$IMAGE_NAME')."
exec docker "${docker_args[@]}" "$IMAGE_NAME" /bin/bash
