# Nov 4, 2019
#   - Added 'build_manual=TRUE', 'build_vignettes=TRUE'
#   - Added 'remotes::install_github("r-lib/rlang", build_vignettes = TRUE, build_manual = TRUE)'

library(remotes)

# See helpful tips at
# https://stat.ethz.ch/pipermail/r-package-devel/2017q4/002187.html
# if (!require("XML", character.only =  TRUE)) {
#   install.packages("XML", type = "source")  
# }
 
# install.packages("xml2")
Sys.setenv(GLPK_HOME = "/mingw64")
Sys.setenv(LIB_XML = "/mingw64")              #Files are located at /mingw32/include/libxml2/
Sys.setenv(LIB_GMP = "/mingw64")

remotes::install_github("yihui/knitr",           build_vignettes = FALSE)
remotes::install_github("rstudio/rmarkdown",     build_vignettes = TRUE)
remotes::install_github("kiernann/gluedown",     build_vignettes = TRUE)
remotes::install_github("r-lib/credentials",     build_vignettes = TRUE)
remotes::install_github("r-lib/rlang",           build_vignettes = TRUE)
remotes::install_github("rstudio/reticulate",    build_vignettes = TRUE)
remotes::install_github("RcppCore/Rcpp",         build_vignettes = FALSE)

remotes::install_github("tidyverse/tidyverse",   build_vignettes = TRUE)
remotes::install_github("rstudio/profvis",       build_vignettes = TRUE)
remotes::install_github("tidyverse/ggplot2",     build_vignettes = TRUE)
remotes::install_github("rstudio/shiny",         build_vignettes = TRUE)
remotes::install_github("ropensci/plotly",       build_vignettes = TRUE)
remotes::install_github("thomasp85/gganimate",   build_vignettes = TRUE)
remotes::install_github("haozhu233/kableExtra",  build_vignettes = FALSE)
remotes::install_github("trinker/pacman",        build_vignettes = TRUE)
remotes::install_github("igraph/rigraph",        build_vignettes = TRUE)
remotes::install_github("r-dbi/DBI",             build_vignettes = TRUE)
remotes::install_github("r-dbi/RPostgres",       build_vignettes = TRUE)
remotes::install_github("r-dbi/RMariaDB",        build_vignettes = TRUE)
remotes::install_github("r-dbi/RSQLite",         build_vignettes = TRUE)
remotes::install_github("r-dbi/odbc",            build_vignettes = TRUE)
remotes::install_github("tidyverse/dbplyr",      build_vignettes = TRUE)
remotes::install_github("rstudio/sparklyr",      build_vignettes = TRUE)
remotes::install_github("DyfanJones/RAthena",    build_vignettes = TRUE)
remotes::install_github("tidyverse/tidyr",       build_vignettes = FALSE)
remotes::install_github("tidyverse/dplyr",       build_vignettes = FALSE)
remotes::install_github("tidyverse/readr",       build_vignettes = FALSE)
remotes::install_github("tidyverse/purrr",       build_vignettes = FALSE)
remotes::install_github("tidyverse/stringi",     build_vignettes = FALSE)
remotes::install_github("tidyverse/stringr",     build_vignettes = FALSE)


# remotes::install_github(,        build_vignettes = TRUE)


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
                    "omegahat/XML",
                    "tidyverse/ggplot2",
                    "thomasp85/ggforce",
                    # "cran/Lahman",
                    "rstudio/gt",
                    #"s-u/rJava",
                    "rstudio/leaflet",
                    "rstudio/htmltools",
                    "rstudio/rsconnect",
                    "r-lib/debugme",
                    "krlmlr/bindr",
                    "hadley/scales",
                    "ramnathv/htmlwidgets",
                    "jeffreyhorner/Rook",
                    "sjmgarnier/viridisLite",
                    "sjmgarnier/viridis",
                    "datastorm-open/visNetwork",
                    "rich-iannone/DiagrammeR"
                  )

for (i in pkgsToInstall) {
    cat("\n\n\n", i, "\t\n", sep = "")
    cat(rep("*", 100), "\n", sep = "")
    # PrintSeparator()
    ##devtools::install_github(i, OUTPUT_DIR)
    remotes::install_github(i, build_manual = FALSE, build_vignettes = TRUE)
    # devtools::install_github(i)
    # PrintSeparator()
    cat(rep("*", 100), "\n", sep = "")
}
