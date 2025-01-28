#!/usr/bin/env bash

# REPO ORIGIN:
#   https://github.com/ScientificProgrammer/InstallMyPkgsToNewRSetup.git
# 
# FILENAME:
#   ./code/linux/setup-debian-distros.sh
# 
# PURPOSE:
#   For Debian based Linux distros, such as Debian, Ubuntu, Linux Mint, etc,
#   install the system packages that are required to run 
# 
# USAGE:
#    1. Clone the repo containing this file.
#
#       From the command line, navigate to the directory where you want the
#       repo containing this script to be located. Here's an example.
#       
#   2.  Source this script.
#   
#
# EXAMPLE:
#   cd ~/Projects/git-repos/github/
#   git clone https://github.com/ScientificProgrammer/InstallMyPkgsToNewRSetup.git
#   cd InstallMyPkgsToNewRSetup/
#   source ./code/linux/setup-debian-distros.sh
#

install_pkgs_for_r() {
    # For Markdown tool support
    sudo apt install -y pandoc                  # pandoc install time is lengthy
    sudo apt install -y texlive-latex-base 		# Contains 'pdflatex'
    sudo apt install -y pktools
    sudo apt install -y pktools-dev
    
    # Install packages required to build rgdal
    sudo apt install -y libgdal-dev

    # Install packages required to build DB connectors
    sudo apt install -y libmariadb-dev
    sudo apt install -y libmysqlclient-dev
    sudo apt install -y libpq-dev
    sudo apt install -y unixodbc-dev
    
    # Install packages required to build image procesing packages
    sudo apt install -y libjpeg-dev
    sudo apt install -y libmagick++-dev
    sudo apt install -y libpng-dev
    sudo apt install -y libtiff5-dev
    
    # Install packages required to build misc packages
    sudo apt install -y libarchive-dev          # archive handling libraries
    sudo apt install -y libavfilter-dev 		# ffmpeg libraries
    sudo apt install -y libfreetype6-dev 		# FreeType 2 font engine 
    sudo apt install -y libssl-dev 			    # OpenSSL project's implementation 
    sudo apt install -y libudunits2-dev 		# units of physical quantities
    
    # On Debian based systems, use libnode-dev to get the
    # functionality associated with libv8-dev
    sudo apt install -y libnode-dev

    # Required for r-lib/gargle
    sudo apt install -y libsodium-dev
}

time install_pkgs_for_r