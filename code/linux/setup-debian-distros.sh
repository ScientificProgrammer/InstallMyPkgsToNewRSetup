#!/bin/sh

# Install packages required to build rgdal
sudo apt install -y libgdal-dev
sudo apt install -y libgdal30
# sudo apt install -y gdal-bin
# sudo apt install -y gdal-data
# sudo apt install -y r-cran-rgdal
# sudo apt install -y r-cran-sf
# sudo apt install -y python3-gdal

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
sudo apt install -y libarchive-dev              # archive handling libraries
sudo apt install -y libavfilter-dev 		# ffmpeg libraries
sudo apt install -y libfreetype6-dev 		# FreeType 2 font engine 
sudo apt install -y libssl-dev 			# OpenSSL project's implementation 
sudo apt install -y libudunits2-dev 		# units of physical quantities

# On Debian based systems, use libnode-dev to get the
# functionality associated with libv8-dev
# sudo apt install -y libv8-dev
sudo apt install -y libnode-dev

sudo apt install -y texlive-latex-base 		# Contains 'pdflatex'
sudo apt install -y pktools
sudo apt install -y pktools-dev

