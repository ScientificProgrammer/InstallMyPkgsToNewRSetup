# See helpful tips at
# https://stat.ethz.ch/pipermail/r-package-devel/2017q4/002187.html

# *************************************************************************
# June 8, 2022 - CRITICAL - INSTALL 'rlang' BEFORE PROCEEDING
# _________________________________________________________________________
# The 'rlang' package is very critical. Make sure that its latest development
# version is installed before proceeding. If is not installed, at best,
# you will be prompted repeatedly to confirm whether or not you wish to
# install it. At worst, your installation will be broken.
# If you try to install 'rlang' using the 'devtools::install_github()' or
# 'remotes::install_github()' function from within an RStudio session,
# the system will inform you that 'rlang' is already in use and ask you
# if you want to restart your R session.
#
# If you answer 'YES', you will
# be stuck in an infinite loop. If you answer 'NO', the install may finish.
# However, more likely, you will receive an error telling you that a DLL
# was in use, so the install failed. There is also a possibility that the
# install will appear to complete successfully, but, you will run into mysterious
# errors later on, and they will be very hard to diagnose.
#
# As of the date above, I was able to successfully install the 'rlang' package
# as follows.
# 1. Open a Windows command shell with administrative privileges. If you're not
#    sure how, use a search engine.
#
# 2. Enter the following command.
#        R -e "remotes::install_github('r-lib/rlang', build_vignettes = TRUE, build_manual = TRUE, force = TRUE)"
#
# 3. If you encounter errors, try the following command.
#        R -e "remotes::install_github('r-lib/rlang')"
#
# 4. If you still are having trouble, visit StackOverflow or Reddit.com/r/RStudio
#    and ask for help.
#
# 5. NOTE:  Today was the first time I was ever able to successfully
#           install the development version of the 'devtools' package, which
#           I did as shown in Step 2, above, except, here's the
#           command that I ran.
#
#       R -e "remotes::install_github('r-lib/devtools', build_vignettes = TRUE, build_manual = TRUE, force = TRUE)"
#           
# -------------------------------------------------------------------------
#
# June 8, 2022
# The Github repo for "r-lib/rlang" v1.02 suggests using the `pak` package for
# installing 'rlang' via the the following code statement.
#     pak::pkg_install("r-lib/rlang")
#
# See the following URLs for more information.
#   1. See the r-lib/rlang Github README for more info.
#           https://github.com/r-lib/rlang/tree/34b04a8a731b054de950ce885627898617e8b297#installation
#
#   2. RStudio has an in-progress page that says "pak" is for human interaction,
#      whereas, "remotes" is a lightweight, programmatic interface for package
#      installation with no dependencies. See the following URL for more info.
#           https://environments.rstudio.com/installation
#
#   3. The r-lib/pak Github repo.
#           https://github.com/r-lib/pak
#
# *************************************************************************
#

pkgCSVFile <- "./data/PkgsToInstall.csv"

Sys.setenv(GLPK_HOME = "/mingw64")
Sys.setenv(LIB_XML = "/mingw64")                                     # Files are located at /mingw32/include/libxml2/
Sys.setenv(LIB_GMP = "/mingw64")

# On Windows, to install the older XML package, first,
# RTools42 needs to be installed. See the following URL
# for details on installing RTools42.
#     https://cran.r-project.org/bin/windows/Rtools/rtools42/rtools.html
#
# After RTools42 is installed, the local repos need to
# be updated using Pacman, and then the libxml2 system
# library needs to be installed. To do so, open an msys2 shell and run
# the following commands.
#
#     pacman -Sy                                          # Update the local repos
#     pacman -S mingw-w64-{i686,x86_64}-libxml2           # Install libxml2 system lib
#
# Once the previous steps have been completed, R can now
# compile packages from source and install them. To test
# your installation, try to install the 'XML' and 'RCurl'
# packages using the following commands.
#
# From within R, run the following two commands.
Sys.setenv(LOCAL_CPPFLAGS = "-I$(MINGW_PREFIX)/include/libxml2")
install.packages("XML", type = "source")

# If your installation is working correctly, the 'XML' package
# will have been installed with no errors.
# For more details on the aforementioned procedure
# and commands, see the documentation available
# at the following URL.
#     https://github.com/r-windows/docs/blob/master/rtools40.md#compiling-r-packages-with-custom-flags

# RCurl is another useful package that should be installed.
# To do so, open an Msys2 shell and run the following sequence of commands.
#     pacman -Sy                                          # Update the local repos 
#     pacman -S mingw-w64-{i686,x86_64}-curl              # Install the curl system libs
#
# Now you can install RCurl from source by running the
# following command from within R itself.
install.packages("RCurl", type = "source")
# For more information, visit
#     https://github.com/r-windows/docs/blob/master/packages.md#readme

# Install the 'remotes' package, which is critical for the rest
# of this script to work properly.
if (!require("remotes", character.only = TRUE)) {
  install.packages("remotes")
}

# Install some other critical packages.
invisible(
  lapply(
    c("formatR", "markdown", "nycflights13"),
    function(x) {
      install.packages(x, type = "source")
    }
  )
)

# Read in the CSV file that contains the list of all packages
# to be installed, along with flags indicating whether or not
# the package should be "force installed", vignettes should be built,
# manuals should be built, and dependencies should be installed.
PkgsToInstall <- read.csv(pkgCSVFile, strip.white = TRUE)

View(PkgsToInstall)

dupPkgs <- names(which(table(PkgsToInstall$repo) > 1))

if (length(dupPkgs) != 0) {
  msg <- paste(length(dupPkgs), "duplicate package", ifelse(length(dupPkgs) > 1, "names were", "name was"), "found.")
  msg <- paste0(msg, "\n  Please update \"", pkgCSVFile, "\" to remove the duplicates.\n")
  msg <- paste0(msg, paste0("      \"", dupPkgs, "\"", collapse = "\n"), sep = "\n")
  stop(msg)
}

PrintSeparator <- function(pNumDashes = 76, pNumPrefixRet = 2, pNumSuffixRet = 2) {
  prefixStr <- paste(rep.int("\n", times = pNumPrefixRet), sep = "", collapse = "")
  sepString <- paste(rep.int(x = "-", times = pNumDashes), sep = "", collapse = "")
  postFixStr <- paste(rep.int("\n", times = pNumSuffixRet), sep = "", collapse = "")
  cat(prefixStr)
  cat(sepString)
  cat(postFixStr)
}

for (i in 1:nrow(PkgsToInstall)) {
    cat("\n\n\n", i, " of ", nrow(PkgsToInstall), ": ", PkgsToInstall$repo[i], "\n", sep = "")
    cat(rep("*", 100), "\n", sep = "")
    remotes::install_github(
      PkgsToInstall$repo[i],
      build_manual = PkgsToInstall$build_manuals[i],
      build_vignettes = PkgsToInstall$build_vignettes[i],
      dependencies = PkgsToInstall$dependencies[i])
    cat(rep("*", 100), "\n", sep = "")
}
