library(devtools)

# See helpful tips at
# https://stat.ethz.ch/pipermail/r-package-devel/2017q4/002187.html
# if (!require("XML", character.only =  TRUE)) {
#   install.packages("XML", type = "source")  
# }


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

OUTPUT_DIR <- "D:/GoogleDrive/eric.milgram/R Examples/Package Mgt"

pkgsToInstall = c(  "omegahat/XML",
                    "tidyverse/tidyverse",
                    #"s-u/rJava",
                    "r-lib/testthat",
                    "haozhu233/kableExtra",
                    "thomasp85/ggraph",
                    "rstudio/leaflet",
                    "rstudio/htmltools",
                    "rstudio/rsconnect",
                    #"RcppCore/Rcpp",
                    "r-lib/debugme",
                    #"r-lib/processx",
                    "rstats-db/DBI",
                    "krlmlr/bindr",
                    "krlmlr/bindrcpp",
                    "cran/colorspace",
                    "hadley/scales",
                    "hadley/gtable",
                    "gagolews/stringi",
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

for (i in pkgsToInstall) {
    PrintSeparator()
    #devtools::install_github(i, OUTPUT_DIR)
    devtools::install_github(i)
    PrintSeparator()
}

# devtools::install_github(pkgsToInstall, output_dir = OUTPUT_DIR)
