# Nov 4, 2019
#   - Added 'build_manual=TRUE', 'build_vignettes=TRUE'
#   - Added 'remotes::install_github("r-lib/rlang", build_vignettes = TRUE, build_manual = TRUE)'

#library(devtools)

# See helpful tips at
# https://stat.ethz.ch/pipermail/r-package-devel/2017q4/002187.html
# if (!require("XML", character.only =  TRUE)) {
#   install.packages("XML", type = "source")  
# }

  remotes::install_github("r-lib/rlang")
  remotes::install_github("yihui/xfun")
  remotes::install_github("yihui/knitr")
  remotes::install_github("rstudio/rmarkdown")

# remotes::install_github("tidyverse/readr")
# devtools::install_github("tidyverse/readr")

  remotes::install_github("tidyverse/tidyverse")
  remotes::install_github("rstudio/profvis")
  remotes::install_github("tidyverse/ggplot2")
  remotes::install_github("rstudio/shiny")
  remotes::install_github("ropensci/plotly")
  remotes::install_github("thomasp85/gganimate")
  remotes::install_github("haozhu233/kableExtra")
  remotes::install_github("RcppCore/Rcpp")


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
                    "cran/Lahman",
                    "tidyverse/tidyverse",
                    # "tidyverse/tidyr",
                    # "tidyverse/dplyr",
                    # "tidyverse/readr",
                    # "tidyverse/purrr",
                    #"tidyverse/stringi",
                    "tidyverse/stringr",
                    "rstudio/gt",
                    #"s-u/rJava",
                    #"haozhu233/kableExtra",
                    "thomasp85/ggraph",
                    "rstudio/leaflet",
                    "rstudio/htmltools",
                    "rstudio/rsconnect",
                    # "RcppCore/Rcpp",
                    "r-lib/debugme",
                    #"r-lib/processx",
                    "rstats-db/DBI",
                    "krlmlr/bindr",
                    "krlmlr/bindrcpp",
                    "cran/colorspace",
                    "hadley/scales",
                    "hadley/gtable",
                    #"gagolews/stringi",
                    "hadley/reshape",
                    "rstudio/rmarkdown",
                    "yihui/knitr",
                    "ramnathv/htmlwidgets",
                    "jeffreyhorner/Rook",
                    "sjmgarnier/viridisLite",
                    "sjmgarnier/viridis",
                    "datastorm-open/visNetwork",
                    "rich-iannone/DiagrammeR"
                  )

# install.packages("stringi")
# install.packages("remotes", build_vignettes = TRUE, build_manual = TRUE)
# remotes::install_github("r-lib/rlang")
# remotes::install_github("r-lib/rlang", build_vignettes = TRUE, build_manual = TRUE)
# devtools::install_git(url = "https://github.com/r-lib/rlang.git", build_vignettes = TRUE, build_manual = TRUE)
# remotes::install_github("r-lib/testthat", build_vignettes = TRUE, build_manual = TRUE)
# remotes::install_github("renkun-ken/formattable", build_vignettes = TRUE, build_manual = TRUE)
# remotes::install_github("haozhu233/kableExtra", force = TRUE, build_vignettes = TRUE, build_manual = TRUE)
# remotes::install_github("RcppCore/Rcpp", build_manual = TRUE, build_vignettes = TRUE)


# install.packages("seriation")
# install.packages("deldir")
# install.packages("Rcpp")

# remotes::install_github("r-lib/rlang", force = FALSE, build_vignettes = TRUE, build_manual = TRUE)

for (i in pkgsToInstall) {
    # cat("START:\n")
    # PrintSeparator()
    ##devtools::install_github(i, OUTPUT_DIR)
    # devtools::install_github(i, build_manual = TRUE, build_vignettes = TRUE)
    devtools::install_github(i)
    # PrintSeparator()
    # cat("STOP:\n\n\n")
}
