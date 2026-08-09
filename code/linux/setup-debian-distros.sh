#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

DRY_RUN=false
ASSUME_YES=false
LOG_DIR="${REPO_ROOT}/tmp"

SUDO=()

R_DEB_PKGS=(
    build-essential
    git
    pkg-config
    libcurl4-openssl-dev
    libgit2-dev
    libssl-dev
    libxml2-dev
    libsodium-dev
    libarchive-dev
    libglpk-dev
    libmariadb-dev
    libmariadb-dev-compat
    libpq-dev
    libsqlite3-dev
    libuv1-dev
    unixodbc-dev
    graphviz
    pandoc
    biber
    latexmk
    lmodern
    texlive-fonts-recommended
    texlive-latex-base
    texlive-latex-extra
    texlive-latex-recommended
    texlive-luatex
    texlive-xetex
)

CMAKE_DEB_PKGS=(
    cmake
)

TEXT_RENDERING_DEB_PKGS=(
    libfontconfig1-dev
    libfreetype-dev
    libfribidi-dev
    libharfbuzz-dev
    libjpeg-dev
    libpng-dev
    libtiff-dev
    libwebp-dev
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
  - The TeX package set is intentionally smaller than texlive-full, but includes
    pdfLaTeX, LuaLaTeX, XeLaTeX, Biber, and common R Markdown dependencies.
  - Database headers cover DBI backends for ODBC, PostgreSQL, MariaDB/MySQL,
    and SQLite.
  - Text and image headers support ragg, systemfonts, textshaping, and the
    tidyverse reporting stack.
**********************************************
NOTES
}

all_packages() {
    printf '%s\n' "${CMAKE_DEB_PKGS[@]}"
    printf '%s\n' "${TEXT_RENDERING_DEB_PKGS[@]}"
    printf '%s\n' "${R_DEB_PKGS[@]}"
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
    install_package_group 'CMake packages' "${CMAKE_DEB_PKGS[@]}"
    install_package_group 'text rendering packages' "${TEXT_RENDERING_DEB_PKGS[@]}"
    install_package_group 'R system dependency packages' "${R_DEB_PKGS[@]}"
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
