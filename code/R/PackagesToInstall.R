# See helpful tips at
# https://stat.ethz.ch/pipermail/r-package-devel/2017q4/002187.html

# Use the following command from the command shell to install the 'rlang'
# package before installing all of these other packages.

Sys.setenv(GLPK_HOME = "/mingw64")
Sys.setenv(LIB_XML = "/mingw64")              # Files are located at /mingw32/include/libxml2/
Sys.setenv(LIB_GMP = "/mingw64")

# On Windows, to install the older XML package, first,
# RTools42 needs to be installed. See the following URL
# for details on installing RTools42.
#     https://cran.r-project.org/bin/windows/Rtools/rtools42/rtools.html
#
# After RTools42 is installed, the local repos need to
# be updated using Pacman, and then the libxml2 system
# library needs to be installed.
# Open an msys2 shell and run the following commands.
#     pacman -Sy                                          # Update the local repos
#     pacman -S mingw-w64-{i686,x86_64}-libxml2           # Install libxml2 system lib
#
# Once the previous steps have been completed, R can now
# compile packages from source and install them.
# The following sequence of commands can be used
# to install the older XML package.
Sys.setenv(LOCAL_CPPFLAGS = "-I$(MINGW_PREFIX)/include/libxml2")
install.packages("XML", type = "source")

# For more details on the aforementioned procedure
# and commands, see the documentation available
# at the following URL.
#     https://github.com/r-windows/docs/blob/master/rtools40.md#compiling-r-packages-with-custom-flags

# RCurl is another useful package that should be installed.
# To do so, open an Msys2 shell and run the following sequence of commands.
#     pacman -Sy                                          # Update the local repos 
#     pacman -S mingw-w64-{i686,x86_64}-curl              # Install the curl system libs
#
# Now you can install RCurl from souce by running the
# following command from within R itself.
install.packages("RCurl", type = "source")
# For more information, visit
#     https://github.com/r-windows/docs/blob/master/packages.md#readme

# Install some critical packages
if (!require("remotes", character.only = TRUE)) {
  install.packages("remotes")
}

invisible(
  lapply(
    c("formatR", "markdown", "nycflights13"),
    function(x) {
      # if (x == "remotes") {
      #   if ( !require("devtools", character.only = TRUE) ) {
      #     install.packages(x)
      #   } else if ( !require(x, character.only = TRUE) ) {
      #         install.packages(x)
      #   }
      # }
      install.packages(x, type = "source")
    }
  )
)

PkgsToInstall = matrix(
  data = c(
    "jennybc/repurrrsive"     ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "rstudio/rmarkdown"       ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "yihui/knitr"             ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "tidyverse/rvest"         ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "kiernann/gluedown"       ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "r-lib/credentials"       ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "rstudio/reticulate"      ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "RcppCore/Rcpp"           ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "r-lib/downlit"           ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "tidyverse/tidyverse"     ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "tidyverse/tidyr"         ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "tidyverse/dplyr"         ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "tidyverse/readr"         ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "tidyverse/purrr"         ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "gagolews/stringi"        ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "tidyverse/stringr"       ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "rstudio/profvis"         ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "tidyverse/ggplot2"       ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "rstudio/shiny"           ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "ropensci/plotly"         ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "thomasp85/gganimate"     ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "haozhu233/kableExtra"    ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "trinker/pacman"          ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "DyfanJones/RAthena"      ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "r-dbi/DBI"               ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "r-dbi/RPostgres"         ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "r-dbi/RMariaDB"          ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "r-dbi/RSQLite"           ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "r-dbi/odbc"              ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "rstudio/sparklyr"        ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "tidyverse/dbplyr"        ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "sjmgarnier/viridisLite"  ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "sjmgarnier/viridis"      ,TRUE  ,TRUE  ,TRUE  ,TRUE  ,
    "rich-iannone/DiagrammeR" ,TRUE  ,TRUE  ,TRUE  ,TRUE
  ),
  ncol = 5,
  byrow = TRUE,
  dimnames = list(
    rownames = 1:34           ,
    colnames = c("repo_name"  ,"force" ,"dependencies" ,"build_vignettes" , "build_manuals")
  )
)

# remotes::install_github("jennybc/repurrrsive",   build_vignettes = TRUE, force = TRUE, dependencies = TRUE, build_manual = TRUE)
# remotes::install_github("rstudio/rmarkdown",     build_vignettes = TRUE, force = TRUE)
# remotes::install_github("yihui/knitr",           build_vignettes = TRUE, force = TRUE)
# remotes::install_github("tidyverse/rvest",       build_vignettes = TRUE)
# remotes::install_github("kiernann/gluedown",     build_vignettes = TRUE)
# remotes::install_github("r-lib/credentials",     build_vignettes = TRUE)
# remotes::install_github("rstudio/reticulate",    build_vignettes = TRUE)
# remotes::install_github("RcppCore/Rcpp",         build_vignettes = TRUE)
# remotes::install_github("r-lib/downlit",         build_vignettes = TRUE)
# remotes::install_github("tidyverse/tidyverse",   build_vignettes = TRUE)
# remotes::install_github("tidyverse/tidyr",       build_vignettes = TRUE, force = FALSE, dependencies = TRUE)
# remotes::install_github("tidyverse/dplyr",       build_vignettes = TRUE)
# remotes::install_github("tidyverse/readr",       build_vignettes = TRUE)
# remotes::install_github("tidyverse/purrr",       build_vignettes = TRUE, force = FALSE, dependencies = TRUE)
# # remotes::install_github("tidyverse/stringi",     build_vignettes = TRUE)
# remotes::install_github("gagolews/stringi",      build_vignettes = TRUE)
# remotes::install_github("tidyverse/stringr",     build_vignettes = TRUE, force = FALSE, dependencies = TRUE)
# remotes::install_github("rstudio/profvis",       build_vignettes = TRUE)
# remotes::install_github("tidyverse/ggplot2",     build_vignettes = TRUE)
# remotes::install_github("rstudio/shiny",         build_vignettes = TRUE)
# remotes::install_github("ropensci/plotly",       build_vignettes = TRUE)
# remotes::install_github("thomasp85/gganimate",   build_vignettes = TRUE)
# remotes::install_github("haozhu233/kableExtra",  build_vignettes = TRUE)
# remotes::install_github("trinker/pacman",        build_vignettes = TRUE)
# remotes::install_github("DyfanJones/RAthena",    build_vignettes = TRUE)
# remotes::install_github("r-dbi/DBI",             build_vignettes = TRUE)
# remotes::install_github("r-dbi/RPostgres",       build_vignettes = TRUE)
# remotes::install_github("r-dbi/RMariaDB",        build_vignettes = TRUE)
# remotes::install_github("r-dbi/RSQLite",         build_vignettes = TRUE)
# remotes::install_github("r-dbi/odbc",            build_vignettes = TRUE)
# remotes::install_github("rstudio/sparklyr",      build_vignettes = TRUE)
# remotes::install_github("tidyverse/dbplyr",      build_vignettes = TRUE)
# remotes::install_github("sjmgarnier/viridisLite", build_vignettes = TRUE)
# remotes::install_github("sjmgarnier/viridis",    build_vignettes = TRUE, dependencies = TRUE)
# remotes::install_github("rich-iannone/DiagrammeR", build_vignettes = TRUE, dependencies = TRUE)
# # remotes::install_github("omegahat/XML",          build_vignettes = TRUE, dependencies = TRUE)

PrintSeparator <- function(pNumDashes = 76, pNumPrefixRet = 2, pNumSuffixRet = 2) {
  # Ensure that all function arguments are integers
  #formals(sys.call) <- lapply(as.list(environment()), as.integer)
  prefixStr <- paste(rep.int("\n", times = pNumPrefixRet), sep = "", collapse = "")
  sepString <- paste(rep.int(x = "-", times = pNumDashes), sep = "", collapse = "")
  postFixStr <- paste(rep.int("\n", times = pNumSuffixRet), sep = "", collapse = "")
  cat(prefixStr)
  cat(sepString)
  cat(postFixStr)
}

#OUTPUT_DIR <- "D:/GoogleDrive/eric.milgram/R Examples/Package Mgt"

pkgsToInstall = c(  
                    "r-lib/here",
                    "christophergandrud/networkD3",
                    "thomasp85/ggforce",
                    "rstudio/gt",
                    "rstudio/leaflet",
                    "rstudio/htmltools",
                    "rstudio/rsconnect",
                    "r-lib/debugme",
                    "krlmlr/bindr",
                    "hadley/scales",
                    "ramnathv/htmlwidgets",
                    "jeffreyhorner/Rook",
                    "datastorm-open/visNetwork"
                  )

for (i in pkgsToInstall) {
    cat("\n\n\n", i, "\t\n", sep = "")
    cat(rep("*", 100), "\n", sep = "")
    # PrintSeparator()
    ##devtools::install_github(i, OUTPUT_DIR)
    remotes::install_github(i, build_manual = FALSE, build_vignettes = TRUE, dependencies = TRUE)
    # devtools::install_github(i)
    # PrintSeparator()
    cat(rep("*", 100), "\n", sep = "")
}

