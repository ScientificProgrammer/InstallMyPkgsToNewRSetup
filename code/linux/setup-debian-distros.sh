#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

DRY_RUN=false
ASSUME_YES=false
LOG_DIR="${REPO_ROOT}/tmp"

SUDO=()

R_DEB_PKGS=(
    protobuf-compiler
    libprotobuf-dev
    libprotoc-dev
    libcurl4-openssl-dev
    libgit2-dev
    gsfonts
    pandoc
    libglpk-dev
    texlive-latex-base
    pktools
    pktools-dev
    libmysqlclient-dev
    libpq-dev
    unixodbc-dev
    libjpeg-dev
    libmagick++-dev
    libpng-dev
    libtiff5-dev
    libarchive-dev
    libavfilter-dev
    libfreetype6-dev
    libssl-dev
    libudunits2-dev
    libsodium-dev
    chromium
    cargo
    libgl1-mesa-dev
    libglu1-mesa-dev
    rustc
    gdal-bin
    libpoppler-cpp-dev
)

CMAKE_DEB_PKGS=(
    cmake
    cmake-data
    cmake-doc
    cmake-format
    cmake-qt-gui
    dh-cmake
    extra-cmake-modules
    extra-cmake-modules-doc
)

TEXT_RENDERING_DEB_PKGS=(
    libfribidi-dev
    libharfbuzz-dev
)

R_APT_COMPAT_DEB_PKGS=(
    r-cran-raster
    r-cran-terra
)

V8_DEB_PKGS=(
    libnode-dev
)

usage() {
    cat <<'USAGE'
Usage: code/linux/setup-debian-distros.sh [options]

Install Debian/Ubuntu/Linux Mint system packages needed by the R package
installer in code/R/PackagesToInstall.R.

Options:
  --dry-run           Run preflight checks and apt install simulations only.
  --yes, -y           Pass --yes to apt-get install.
  --log-dir DIR       Write the timestamped run log to DIR. Default: ./tmp.
  --help, -h          Show this help text.

This script is intended to be run, not sourced.
USAGE
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --yes | -y)
                ASSUME_YES=true
                ;;
            --log-dir)
                if [[ $# -lt 2 || -z "${2:-}" ]]; then
                    printf 'ERROR: --log-dir requires a directory path.\n' >&2
                    return 2
                fi
                LOG_DIR="$2"
                shift
                ;;
            --help | -h)
                usage
                exit 0
                ;;
            *)
                printf 'ERROR: Unknown option: %s\n\n' "$1" >&2
                usage >&2
                return 2
                ;;
        esac
        shift
    done

    if [[ "${LOG_DIR}" != /* ]]; then
        LOG_DIR="${REPO_ROOT}/${LOG_DIR}"
    fi
}

print_section() {
    printf '\n**********************************************\n'
    printf '%s\n' "$1"
    printf '**********************************************\n'
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

print_notes() {
    cat <<'NOTES'

**********************************************
This script installs or upgrades Debian-family system packages required by
code/R/PackagesToInstall.R.

Notes:
  - It uses apt-get because apt does not provide a stable scripting interface.
  - texlive-latex-base provides pdflatex for R Markdown and related packages.
  - libnode-dev provides the Debian-family equivalent needed by jeroen/V8 when
    Ubuntu/Debian nodejs packages own Node.
  - NodeSource nodejs packages already own /usr/include/node/* and conflict
    with Ubuntu libnode-dev; on those hosts this script skips libnode-dev and
    code/R/PackagesToInstall.R builds jeroen/V8 with static libv8.
  - r-cran-raster and r-cran-terra are intentionally installed from apt on
    Jammy/Mint hosts because current CRAN terra does not compile against the
    older distro GDAL stack used here.
  - libsodium-dev is required for r-lib/gargle.
  - libavfilter-dev provides FFmpeg libraries.
**********************************************
NOTES
}

nodejs_package_version() {
    dpkg-query -W -f='${Version}' nodejs 2>/dev/null || true
}

has_nodesource_nodejs() {
    local nodejs_version=''

    nodejs_version="$(nodejs_package_version)"
    [[ "${nodejs_version}" == *nodesource* ]]
}

v8_deb_packages() {
    if has_nodesource_nodejs; then
        return 0
    fi

    printf '%s\n' "${V8_DEB_PKGS[@]}"
}

all_packages() {
    printf '%s\n' "${CMAKE_DEB_PKGS[@]}"
    printf '%s\n' "${TEXT_RENDERING_DEB_PKGS[@]}"
    printf '%s\n' "${R_DEB_PKGS[@]}"
    printf '%s\n' "${R_APT_COMPAT_DEB_PKGS[@]}"
    v8_deb_packages
}

check_required_commands() {
    local missing=()
    local required=(
        apt-cache
        apt-get
        awk
        date
        dpkg-query
        grep
        mkdir
        readlink
        tee
    )

    if [[ "${DRY_RUN}" == false && "${EUID}" -ne 0 ]]; then
        required+=(sudo)
    fi

    for cmd in "${required[@]}"; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            missing+=("${cmd}")
        fi
    done

    if [[ "${#missing[@]}" -gt 0 ]]; then
        printf 'Missing required command(s): %s\n' "${missing[*]}" >&2
        return 1
    fi

    if [[ "${DRY_RUN}" == false && "${EUID}" -ne 0 ]]; then
        SUDO=(sudo)
    fi

    return 0
}

check_node_v8_strategy() {
    local nodejs_header_owner=''
    local nodejs_version=''

    print_section 'Checking Node/V8 dependency strategy'

    nodejs_version="$(nodejs_package_version)"

    if [[ -z "${nodejs_version}" ]]; then
        printf 'No dpkg-managed nodejs package detected; apt will install libnode-dev for jeroen/V8.\n'
        return 0
    fi

    printf 'dpkg nodejs version: %s\n' "${nodejs_version}"

    if has_nodesource_nodejs; then
        nodejs_header_owner="$(dpkg-query -S /usr/include/node/common.gypi 2>/dev/null || true)"
        printf 'Node header owner: %s\n' "${nodejs_header_owner:-<not owned>}"
        cat <<'EOF'
Detected NodeSource nodejs. Skipping Ubuntu libnode-dev because both packages
own files under /usr/include/node, which causes dpkg overwrite failures.

For jeroen/V8, use:
  Rscript code/R/PackagesToInstall.R --v8-mode auto

The R installer defaults to auto mode and will build V8 with DOWNLOAD_STATIC_LIBV8=1.
EOF
        return 0
    fi

    printf 'NodeSource nodejs not detected; apt will manage libnode-dev for jeroen/V8.\n'
}

check_debian_family() {
    local distro_id=''
    local distro_id_like=''

    if [[ ! -r /etc/os-release ]]; then
        printf 'Cannot read /etc/os-release; this does not look like a supported Debian-family host.\n' >&2
        return 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    distro_id="${ID:-}"
    distro_id_like="${ID_LIKE:-}"

    if [[ "${distro_id}" == "debian" || "${distro_id}" == "ubuntu" || "${distro_id}" == "linuxmint" ]]; then
        printf 'Detected supported distro: %s\n' "${PRETTY_NAME:-${distro_id}}"
        return 0
    fi

    if grep -Eq '(^|[[:space:]])(debian|ubuntu)([[:space:]]|$)' <<<"${distro_id_like}"; then
        printf 'Detected Debian-family distro: %s\n' "${PRETTY_NAME:-${distro_id}}"
        return 0
    fi

    printf 'Unsupported distro for this script: %s\n' "${PRETTY_NAME:-unknown}" >&2
    return 1
}

check_package_candidates() {
    local candidate=''
    local failures=0
    local pkg=''

    print_section 'Checking apt package candidates'

    while IFS= read -r pkg; do
        candidate="$(apt-cache policy "${pkg}" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
        if [[ -z "${candidate}" || "${candidate}" == "(none)" ]]; then
            printf 'No apt candidate found for package: %s\n' "${pkg}" >&2
            failures=1
        else
            printf '%-32s %s\n' "${pkg}" "${candidate}"
        fi
    done < <(all_packages | sort -u)

    return "${failures}"
}

check_apt_repair_state() {
    local output=''
    local status=0

    print_section 'Checking whether apt/dpkg already needs repair'

    set +e
    output="$(apt-get -s -f install 2>&1)"
    status=$?
    set -e

    if [[ "${status}" -ne 0 ]]; then
        printf '%s\n' "${output}" >&2
        printf '\napt-get -s -f install failed. Repair apt/dpkg before installing more packages.\n' >&2
        return 1
    fi

    if grep -Eq 'not fully installed or removed|^Conf ' <<<"${output}"; then
        printf '%s\n' "${output}" >&2
        cat >&2 <<'EOF'

apt/dpkg has unfinished package work. Resolve this before running the installer.
On the current host, tex-common was previously observed in this state.
EOF
        return 1
    fi

    printf 'apt/dpkg repair simulation is clean.\n'
    return 0
}

check_texlive_shadowing() {
    local cmd=''
    local first_path=''
    local target_path=''
    local collisions=()
    local tex_commands=(
        fmtutil
        fmtutil-sys
        kpsewhich
        mktexlsr
        updmap-sys
        pdftex
        luatex
        xetex
    )

    print_section 'Checking for TeX Live command shadowing'

    for cmd in "${tex_commands[@]}"; do
        first_path="$(command -v "${cmd}" 2>/dev/null || true)"
        if [[ -z "${first_path}" ]]; then
            continue
        fi

        target_path="${first_path}"
        if [[ -L "${first_path}" ]]; then
            target_path="$(readlink -f "${first_path}" 2>/dev/null || printf '%s' "${first_path}")"
        fi

        if [[ "${first_path}" == /usr/local/texlive/* || "${target_path}" == /usr/local/texlive/* ]]; then
            collisions+=("${cmd}: ${first_path} -> ${target_path}")
        fi
    done

    if [[ "${#collisions[@]}" -eq 0 ]]; then
        printf 'No /usr/local/texlive commands are shadowing apt TeX commands.\n'
        return 0
    fi

    cat >&2 <<'EOF'
TeX Live installed under /usr/local is shadowing distro TeX commands.

This script installs texlive-latex-base from apt. Debian package maintainer
scripts call TeX tools while configuring packages, so /usr/local/texlive
symlinks can cause apt's TeX packages to run against the wrong TeX tree.

Shadowing commands:
EOF
    printf '  %s\n' "${collisions[@]}" >&2
    cat >&2 <<'EOF'

Repair options:
  - Prefer apt TeX for this host and move the /usr/local/bin TeX symlinks aside.
  - Or purge apt TeX packages and manage TeX entirely with /usr/local/texlive.

Do not continue with this apt installer until that ownership decision is resolved.
EOF
    return 1
}

run_preflight() {
    local failures=0

    print_section 'Running preflight checks'

    if ! check_required_commands; then
        failures=1
    fi

    if ! check_debian_family; then
        failures=1
    fi

    if ! check_package_candidates; then
        failures=1
    fi

    if ! check_apt_repair_state; then
        failures=1
    fi

    check_node_v8_strategy

    if ! check_texlive_shadowing; then
        failures=1
    fi

    if [[ "${failures}" -ne 0 ]]; then
        die 'Preflight failed. Resolve the issue(s) above, then rerun this script.'
    fi
}

run_apt_update() {
    if [[ "${DRY_RUN}" == true ]]; then
        print_section 'Dry run: skipping apt-get update'
        return 0
    fi

    print_section 'Updating apt package lists'
    "${SUDO[@]}" apt-get update
}

install_package_group() {
    local label="$1"
    shift

    local apt_args=(install)
    if [[ "${ASSUME_YES}" == true ]]; then
        apt_args+=(--yes)
    fi

    apt_args+=("$@")

    if [[ "${DRY_RUN}" == true ]]; then
        print_section "Dry run: simulating ${label}"
        apt-get -s "${apt_args[@]}"
        return 0
    fi

    print_section "Installing ${label}"
    "${SUDO[@]}" apt-get "${apt_args[@]}"
}

run_installs() {
    local v8_pkgs=()

    install_package_group 'CMake packages' "${CMAKE_DEB_PKGS[@]}"
    install_package_group 'text rendering packages' "${TEXT_RENDERING_DEB_PKGS[@]}"
    install_package_group 'R system dependency packages' "${R_DEB_PKGS[@]}"
    install_package_group 'apt-managed R compatibility packages' "${R_APT_COMPAT_DEB_PKGS[@]}"

    mapfile -t v8_pkgs < <(v8_deb_packages)
    if [[ "${#v8_pkgs[@]}" -eq 0 ]]; then
        print_section 'Skipping Ubuntu libnode-dev'
        printf 'NodeSource nodejs is installed; jeroen/V8 will use static libv8 from the R installer.\n'
        return 0
    fi

    install_package_group 'Node/V8 system dependency packages' "${v8_pkgs[@]}"
}

run_main() {
    print_notes
    run_preflight
    run_apt_update
    run_installs

    print_section 'System package setup complete'
    printf 'Next step: Rscript code/R/PackagesToInstall.R --validate-only\n'
}

main() {
    local log_file=''
    local status=0

    parse_args "$@"
    mkdir -p "${LOG_DIR}"
    log_file="${LOG_DIR}/output_of_setup-debian-distros-dot-sh.$(date +%Y%m%d_%H%M%S).txt"

    set +e
    run_main 2>&1 | tee "${log_file}"
    status=${PIPESTATUS[0]}
    set -e

    printf '\nLog saved to %s\n' "${log_file}"
    return "${status}"
}

main "$@"
