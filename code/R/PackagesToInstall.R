# See helpful tips at
# https://stat.ethz.ch/pipermail/r-package-devel/2017q4/002187.html

pkgCSVFile          <- "data/PkgsToInstall.csv"
NUM_CPUS_TO_BLD_SRC <- 4

installPkgsFromSrc <- function(pkgNames) {
    rslts <- lapply(pkgNames, function(pkgName) {
        msg <- NULL
            
        if (!pkgName %in% installed.packages()) {
            if (pkgName == 'pak') {
                if (!require("pak", character.only = TRUE)) {
                    # install.packages("pak", repos = "https://r-lib.github.io/p/pak/devel/")
                    try(
                        install.packages(
                            'pak',
                            repos = sprintf(
                                'https://r-lib.github.io/p/pak/devel/%s/%s/%s',
                                .Platform$pkgType,
                                R.Version()$os,
                                R.Version()$arch
                            )
                        )
                    )
                }
            } else {
                install.packages(pkgName, type = 'source', Ncpus = NUM_CPUS_TO_BLD_SRC)
            }
            msg <- paste0("package ", sprintf("%-15s", pkgName), " was installed successfully from source.")
        } else {
            msg <- paste0("package ", sprintf("%-15s", pkgName), " was already installed.")
        }
        return(msg)
    })
    names(rslts) <- pkgNames
    return(rslts)
}

# To install the development version of 'jeroen/curl' from Github, run the
# following command. For more details, visit
#
#      https://github.com/jeroen/curl#development-version
if (!require('curl')) {
    try(
        install.packages(
            pkgs            = 'https://github.com/jeroen/curl/archive/master.tar.gz',
            repos           = NULL,
            build_vignettes = TRUE,
            build_manual    = TRUE,
            force           = FALSE
        )
    )
    sessioninfo::session_info()
}

rslts <- installPkgsFromSrc(c("RCurl", "here", "remotes", "pkgdepends", "pak"))
invisible(lapply(rslts, function(x) {cat(x, "\n")}))

try(
    pak::pkg_install(
        pkg          = 'r-lib/rlang',
        upgrade      = TRUE,
        dependencies = pkgdepends::as_pkg_dependencies('all')
    )
)

pkgCSVFilePath <- here::here(pkgCSVFile)

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

# Make sure that a valid CRAN repo is set.
# x2 <- getOption("repos")
# 
# if (is.na(x2["CRAN"])) {
#     x2 <- structure(c(CRAN = "https://cloud.r-project.org"), RStudio = TRUE)
#     options(repos = x2)
# }
# rm(x2)

if (is.na(getOption("repos")["CRAN"])) {
    options(repos = structure(c(CRAN = "https://cran.microsoft.com/"), RStudio = TRUE))
}

Sys.setenv(GLPK_HOME = "/mingw64")
Sys.setenv(LIB_XML   = "/mingw64")                                     # Files are located at /mingw32/include/libxml2/
Sys.setenv(LIB_GMP   = "/mingw64")

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
#   Sys.setenv(LOCAL_CPPFLAGS = "-I$(MINGW_PREFIX)/include/libxml2")
#   install.packages("XML", type = "source")

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
#   install.packages("RCurl", type = "source")

# For more information, visit
#     https://github.com/r-windows/docs/blob/master/packages.md#readme

# **** IMPORTANT: Run this command from the command line ****
# RScript --verbose -e "try(pak::pkg_install('tidyverse/glue', upgrade = TRUE, dependencies = pkgdepends::as_pkg_dependencies('all'))); sessioninfo::session_info();"

# Read in the CSV file that contains the list of all packages
# to be installed, along with flags indicating whether or not
# the package should be "force installed", vignettes should be built,
# manuals should be built, and dependencies should be installed.
PkgsToInstall <- read.csv(pkgCSVFilePath, strip.white = TRUE)

# Check for duplicated package names and halt if found.
dupPkgs <- names(which(table(PkgsToInstall$repo) > 1))

if (length(dupPkgs) != 0) {
    msg <- paste(length(dupPkgs), "duplicate package", ifelse(length(dupPkgs) > 1, "names were", "name was"), "found.")
    msg <- paste0(msg, "\n  Please update \"", pkgCSVFile, "\" to remove the duplicates.\n")
    msg <- paste0(msg, paste0("      \"", dupPkgs, "\"", collapse = "\n"), sep = "\n")
    stop(simpleError(msg))
}

# pak::pkg_install(
#     as.character(PkgsToInstall$repo_name),
#     upgrade = TRUE,
#     ask = TRUE,
#     dependencies = pkgdepends::as_pkg_dependencies('all'))

remotes::install_github(
    repo = PkgsToInstall$repo_name,
    force = PkgsToInstall$force_build,
    build_manual = PkgsToInstall$build_manuals,
    build_vignettes = PkgsToInstall$build_vignettes)
