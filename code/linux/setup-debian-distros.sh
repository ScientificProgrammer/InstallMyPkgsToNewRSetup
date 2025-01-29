# For Markdown tool support

PrintBashSrcMsg() {
    if [[ -z "$1" ]]; then
        return 1;
    fi
    printf "%s: %b" "${BASH_SOURCE[0]}" "$1"
}

PrintNotes() {
    printf "\n\n"
    printf "**********************************************\n"
    PrintBashSrcMsg "This bash shell script attempts to install or upgrade all system packages\n"
    PrintBashSrcMsg "that will be required by the R packages to be installed by\n"
    PrintBashSrcMsg "<REPO_ORIGIN>/code/R/PackagesToInstall.R\n"
    PrintBashSrcMsg "This script is designed only for Debian based Linux distros.\n"
    PrintBashSrcMsg '
NOTES:
    - The time required to install '\'pandoc\'' is lengthy. Even
      with a relatively modern computer and nominally fast network
      connection, this package can require 30 - 90 minutes to install.

    - The '\'texlive-latex-base\'' package contains '\'pdflatex\''.

    - On Debian based systems, the '\'libnode-dev\'' is used to get the
      functionality associated with '\'libv8-dev\'' package.

    - '\'libsodium-dev\'' is required for '\'r-lib/gargle\''.

    - '\'libavfilter-dev\'' contains '\'ffmpeg\'' libraries.
'
    printf "**********************************************\n"
}

SetPkgArrays() {

    declare -ag R_DEB_PKGS=(
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
        libnode-dev         # libnode-dev --> jeroen/V8
        libsodium-dev
        chromium
        cargo               # yihui/knitr --> gifsky --> cargo (needed for rust compiler)
        libgl1-mesa-dev     # yihui/knitr --> rgl --> libgl1-mesa-dev
        libglu1-mesa-dev    # yihui/knitr --> rgl --> libglu1-mesa-dev
        rustc               # yihui/knitr --> gifsky --> rustc
        gdal-bin            # tidyverse/ggplot2 --> sf --> gdal-bin
        libpoppler-cpp-dev  # rstudio/pagedown --> pdftools --> libpoppler-cpp-dev
    )

    declare -ag CMAKE_DEB_PKGS=(
        cmake
        cmake-data
        cmake-doc
        cmake-format
        cmake-qt-gui
        dh-cmake
        extra-cmake-modules
        extra-cmake-modules-doc
    )
}

UnsetPkgArrays() {
    unset R_DEB_PKGS
    unset CMAKE_DEB_PKGS
}

InstallOrUpdatePackages() {

    printf "\n\n"
    printf "**********************************************\n"
    PrintBashSrcMsg "Attempting to install (or upgrade)\n"
    PrintBashSrcMsg "cmake and related packages.\n"
    printf "**********************************************\n"
    sudo apt install "${CMAKE_DEB_PKGS:-}" 2>/dev/null
    printf "**********************************************\n"
    printf "\n\n"

    printf "**********************************************\n"
    PrintBashSrcMsg "Attempting to install libfribidi-dev and libharfbuzz-dev\n"
    printf "**********************************************\n"
    sudo apt install libfribidi-dev libharfbuzz-dev 2>/dev/null  # Required for r-lib/lobstr
    printf "**********************************************\n"
    printf "\n\n"

    for pkg in "${R_DEB_PKGS[@]}"; do
        printf "**********************************************\n"
        printf "Attempting to install %s\n" "${pkg:-}"
        printf "**********************************************\n"
        sudo apt install "${pkg:-}" -y 2>/dev/null
        printf "**********************************************\n"
        printf "\n\n"
    done
}

PrintNotes
SetPkgArrays
printf "\n\n"
printf "**********************************************\n"
PrintBashSrcMsg "Preparing to update system package lists.\n"
printf "**********************************************\n"
sudo apt update
printf "**********************************************\n"
printf "\n\n"
printf "**********************************************\n"
PrintBashSrcMsg "Preparing to install packages.\n"
printf "**********************************************\n"
InstallOrUpdatePackages | sed -E 's/^/    /'
printf "**********************************************\n"
PrintBashSrcMsg "Review the output and check for errors. If any errors are found,\n"
PrintBashSrcMsg "attempt to resolve them before running the R package installer script\n"
PrintBashSrcMsg "<REPO_ORIGIN>/code/R/PackagesToInstall.R\n"
printf "**********************************************\n"
printf "\n\n"
UnsetPkgArrays

