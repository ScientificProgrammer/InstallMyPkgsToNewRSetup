if (!require("devtools")) {
  install.packages("devtools")
} else {
  library(devtools)
}

install.packages("XML")

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


pkgsToInstall = c(  #"s-u/rJava",
                    #"dragua/xlsx",
                    "haozhu233/kableExtra",
                    "thomasp85/ggraph",
                    "rstudio/leaflet",
                    "rstudio/htmltools",
                    "RcppCore/Rcpp",
                    "tidyverse/tidyverse",
                    "r-lib/debugme",
                    "r-lib/processx",
                    "tidyverse/purrr",
                    "tidyverse/reprex",
                    "tidyverse/tibble",
                    "rstats-db/DBI",
                    "krlmlr/bindr",
                    "tidyverse/glue",
                    "krlmlr/bindrcpp",
                    "tidyverse/dplyr",
                    "hadley/plyr",
                    "cran/psych",
                    "cran/colorspace",
                    "hadley/scales",
                    "hadley/gtable",
                    "gagolews/stringi",
                    "hadley/reshape",
                    "tidyverse/tidyverse",
                    "rstudio/rmarkdown",
                    "yihui/knitr",
                    "ramnathv/htmlwidgets",
                    "tidyverse/rlang",
                    #"igraph/rigraph",
                    #"omegahat/XML",
                    "tidyverse/tidyselect",
                    "tidyverse/tidyr",
                    "tidyverse/stringr",
                    "tidyverse/readxl",
                    "jeffreyhorner/Rook",
                    "sjmgarnier/viridisLite",
                    "sjmgarnier/viridis",
                    "datastorm-open/visNetwork",
                    "rich-iannone/DiagrammeR"
                  )

for (i in pkgsToInstall) {
    PrintSeparator()
    devtools::install_github(i)
    PrintSeparator()
}
