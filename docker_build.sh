#!/usr/bin/env bash

set -uo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || exit 1
readonly PROJECT_DIR
readonly BUILDER_NAME="ros-multiarch-builder"
readonly LOCAL_REPOSITORY="ros"
readonly REMOTE_REPOSITORY="whoyayawho/ros"

declare -ar IMAGE_TAGS=(
    melodic
    noetic
    dashing
    foxy
    humble
    jazzy
    jazzy_pytorch
)

declare -ar DOCKERFILES=(
    Dockerfile_ros_melodic
    Dockerfile_ros_noetic
    Dockerfile_ros2_dashing
    Dockerfile_ros2_foxy
    Dockerfile_ros2_humble
    Dockerfile_ros2_jazzy
    Dockerfile_ros2_jazzy_pytorch
)

declare -ar ROS_DISTROS=(
    melodic
    noetic
    dashing
    foxy
    humble
    jazzy
    jazzy
)

declare -ar IMAGE_KINDS=(
    ros1
    ros1
    ros2
    ros2
    ros2
    ros2
    pytorch
)

declare -ar PLATFORMS=(linux/amd64 linux/arm64)
declare -ar ARCH_TAGS=(amd64 arm64)
declare -ar DEB_ARCHES=(amd64 arm64)

PUBLISH=false

log() {
    printf '[docker_build] %s\n' "$*"
}

warn() {
    printf '[docker_build] 경고: %s\n' "$*" >&2
}

die() {
    printf '[docker_build] 오류: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
사용법: bash ./docker_build.sh [--push]

옵션 없이 실행하면 x86 PC에서 모든 이미지를 linux/amd64와 linux/arm64로
각각 빌드하고 로컬 smoke test를 수행합니다.

  --push    모든 로컬 테스트가 통과한 뒤 Docker Hub에 배포판별 최종 태그
            하나로 멀티 플랫폼 이미지를 게시합니다. 먼저 docker login을
            실행해야 합니다.
  -h, --help
            도움말을 표시합니다.
EOF
}

parse_arguments() {
    if (( $# > 1 )); then
        usage >&2
        die "인수는 하나만 지정할 수 있습니다."
    fi

    case "${1:-}" in
        "")
            ;;
        --push)
            PUBLISH=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            die "지원하지 않는 옵션입니다: $1"
            ;;
    esac
}

check_prerequisites() {
    [[ "$(uname -s)" == "Linux" ]] || die "Linux 환경에서 실행해야 합니다."

    case "$(uname -m)" in
        x86_64|amd64)
            ;;
        *)
            die "이 스크립트는 x86-64 PC 전용입니다. 현재 아키텍처: $(uname -m)"
            ;;
    esac

    command -v docker >/dev/null 2>&1 || die "docker 명령을 찾을 수 없습니다."
    docker info >/dev/null 2>&1 || die "Docker 데몬에 연결할 수 없습니다."
    docker buildx version >/dev/null 2>&1 || die "Docker Buildx를 사용할 수 없습니다."

    local dockerfile
    for dockerfile in "${DOCKERFILES[@]}"; do
        [[ -f "$PROJECT_DIR/$dockerfile" ]] || die "Dockerfile을 찾을 수 없습니다: $dockerfile"
    done

    if [[ "$PUBLISH" == true ]]; then
        log "게시 모드입니다. Docker Hub 로그인 상태와 '$REMOTE_REPOSITORY' push 권한이 필요합니다."
    fi
}

arm64_runtime_available() {
    local detected_arch
    detected_arch="$(
        docker run --rm --platform linux/arm64 arm64v8/alpine:3.20 uname -m 2>/dev/null
    )" || return 1

    [[ "$detected_arch" == "aarch64" || "$detected_arch" == "arm64" ]]
}

ensure_arm64_emulation() {
    if arm64_runtime_available; then
        log "ARM64 QEMU 실행 환경이 준비되어 있습니다."
        return
    fi

    log "ARM64 빌드 및 로컬 테스트를 위해 QEMU binfmt를 등록합니다."
    docker run --privileged --rm tonistiigi/binfmt --install arm64 \
        || die "ARM64 QEMU binfmt 등록에 실패했습니다."

    arm64_runtime_available \
        || die "QEMU 등록 후에도 linux/arm64 컨테이너를 실행할 수 없습니다."
}

ensure_builder() {
    if docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
        log "기존 Buildx 빌더를 사용합니다: $BUILDER_NAME"
    else
        log "Buildx 빌더를 생성합니다: $BUILDER_NAME"
        docker buildx create \
            --name "$BUILDER_NAME" \
            --driver docker-container \
            >/dev/null \
            || die "Buildx 빌더 생성에 실패했습니다."
    fi

    local builder_info
    builder_info="$(docker buildx inspect "$BUILDER_NAME" --bootstrap)" \
        || die "Buildx 빌더를 시작할 수 없습니다."

    grep -q 'linux/amd64' <<< "$builder_info" \
        || die "Buildx 빌더가 linux/amd64를 지원하지 않습니다."
    grep -q 'linux/arm64' <<< "$builder_info" \
        || die "Buildx 빌더가 linux/arm64를 지원하지 않습니다."

    log "Buildx 빌더가 linux/amd64와 linux/arm64를 지원합니다."
}

build_local_image() {
    local dockerfile="$1"
    local image_tag="$2"
    local platform="$3"
    local arch_tag="$4"
    local local_image="$LOCAL_REPOSITORY:${image_tag}-${arch_tag}-test"

    log "빌드: $dockerfile ($platform) -> $local_image"
    docker buildx build \
        --builder "$BUILDER_NAME" \
        --platform "$platform" \
        --file "$PROJECT_DIR/$dockerfile" \
        --tag "$local_image" \
        --load \
        "$PROJECT_DIR"
}

run_smoke_test() {
    local image_tag="$1"
    local ros_distro="$2"
    local image_kind="$3"
    local platform="$4"
    local arch_tag="$5"
    local deb_arch="$6"
    local local_image="$LOCAL_REPOSITORY:${image_tag}-${arch_tag}-test"

    log "smoke test: $local_image ($platform)"
    docker run --rm \
        --platform "$platform" \
        --entrypoint /bin/bash \
        --env "EXPECTED_ARCH=$deb_arch" \
        --env "EXPECTED_DISTRO=$ros_distro" \
        --env "IMAGE_KIND=$image_kind" \
        "$local_image" \
        -lc '
            set -e
            test "$(dpkg --print-architecture)" = "$EXPECTED_ARCH"
            source "/opt/ros/${EXPECTED_DISTRO}/setup.bash"

            if [[ "$IMAGE_KIND" = "ros1" ]]; then
                test "$(rosversion -d)" = "$EXPECTED_DISTRO"
            else
                test "$ROS_DISTRO" = "$EXPECTED_DISTRO"
                ros2 --help >/dev/null
            fi

            if [[ "$IMAGE_KIND" = "pytorch" ]]; then
                python -c "import torch; print(torch.__version__)"
            fi

            printf "smoke test passed: %s/%s\n" "$EXPECTED_DISTRO" "$EXPECTED_ARCH"
        '
}

publish_image() {
    local dockerfile="$1"
    local image_tag="$2"
    local remote_image="$REMOTE_REPOSITORY:$image_tag"

    log "멀티 플랫폼 게시: $remote_image"
    docker buildx build \
        --builder "$BUILDER_NAME" \
        --platform linux/amd64,linux/arm64 \
        --file "$PROJECT_DIR/$dockerfile" \
        --tag "$remote_image" \
        --push \
        "$PROJECT_DIR" \
        || return 1

    local inspect_output
    inspect_output="$(docker buildx imagetools inspect "$remote_image")" || return 1

    grep -q 'linux/amd64' <<< "$inspect_output" || return 1
    grep -q 'linux/arm64' <<< "$inspect_output" || return 1
}

print_summary() {
    local title="$1"
    shift

    printf '\n%s (%d)\n' "$title" "$#"
    local item
    for item in "$@"; do
        printf '  - %s\n' "$item"
    done
}

main() {
    parse_arguments "$@"
    check_prerequisites
    ensure_arm64_emulation
    ensure_builder

    declare -a passed_tests=()
    declare -a failed_steps=()

    local image_index platform_index
    for image_index in "${!IMAGE_TAGS[@]}"; do
        for platform_index in "${!PLATFORMS[@]}"; do
            local image_tag="${IMAGE_TAGS[$image_index]}"
            local dockerfile="${DOCKERFILES[$image_index]}"
            local ros_distro="${ROS_DISTROS[$image_index]}"
            local image_kind="${IMAGE_KINDS[$image_index]}"
            local platform="${PLATFORMS[$platform_index]}"
            local arch_tag="${ARCH_TAGS[$platform_index]}"
            local deb_arch="${DEB_ARCHES[$platform_index]}"
            local result_name="$image_tag/$arch_tag"

            if ! build_local_image "$dockerfile" "$image_tag" "$platform" "$arch_tag"; then
                failed_steps+=("$result_name 빌드")
                warn "$result_name 빌드에 실패했습니다."
                continue
            fi

            if ! run_smoke_test \
                "$image_tag" \
                "$ros_distro" \
                "$image_kind" \
                "$platform" \
                "$arch_tag" \
                "$deb_arch"; then
                failed_steps+=("$result_name smoke test")
                warn "$result_name smoke test에 실패했습니다."
                continue
            fi

            passed_tests+=("$result_name")
        done
    done

    print_summary "로컬 테스트 통과" "${passed_tests[@]}"
    print_summary "실패한 단계" "${failed_steps[@]}"

    if (( ${#failed_steps[@]} > 0 )); then
        die "실패한 단계가 있어 Docker Hub 게시를 수행하지 않습니다."
    fi

    if [[ "$PUBLISH" != true ]]; then
        log "모든 로컬 테스트가 통과했습니다. 게시하려면 docker login 후 --push로 다시 실행하세요."
        return
    fi

    declare -a published_images=()
    declare -a failed_publications=()

    for image_index in "${!IMAGE_TAGS[@]}"; do
        local image_tag="${IMAGE_TAGS[$image_index]}"
        local dockerfile="${DOCKERFILES[$image_index]}"
        local remote_image="$REMOTE_REPOSITORY:$image_tag"

        if publish_image "$dockerfile" "$image_tag"; then
            published_images+=("$remote_image")
        else
            failed_publications+=("$remote_image")
            warn "$remote_image 게시 또는 manifest 확인에 실패했습니다."
        fi
    done

    print_summary "게시 완료" "${published_images[@]}"
    print_summary "게시 실패" "${failed_publications[@]}"

    if (( ${#failed_publications[@]} > 0 )); then
        die "일부 이미지 게시에 실패했습니다."
    fi

    log "모든 최종 태그에 linux/amd64와 linux/arm64가 포함되어 있습니다."
}

main "$@"
