# Install Bioconductor

# Bioconductor is a project that provides tools for the analysis and comprehension of high-throughput genomic data.
# For more information, see the following URL.
#
# https://cran.r-project.org/web/packages/BiocManager/vignettes/BiocManager.html

# This checks to see if the Bioconductor package manager is installed. If not,
# it installs it and a set of commonly used Bioconductor packages.
if (!require("BiocManager", quietly = TRUE)) {
    install.packages(
        "BiocManager",
        repos = "https://cloud.r-project.org"
    )
    # Load the BiocManager package.
    library(BiocManager)
}

if (!require(tidyverse)) {
    install.packages(
        "tidyverse",
        repos = "https://cloud.r-project.org"
    )
    library(tidyverse)
}

# Verify version of Bioconductor currently in use.
BiocManager::version()

# Use BiocManager::valid() to check the validity of the Bioconductor installation.
# This function checks the installed packages and their versions
# against the current version of Bioconductor.
datBiocMgrValid <- BiocManager::valid()

# On Thu May 15, 2025, BiocManager::version() identified the following package issues.
# Out-of-Date: 232
# Too new: 91
# Then, it suggested running the following command to fix these issues.
#
# BiocManager::install(c(
# "abind", "acepack", "archive", "askpass", "available",
# "backports", "bench", "BH", "bindr", "bit", "bit64", "bitops",
# "blob", "brio", "broom", "cachem", "callr", "caret", "caTools",
# "cba", "checkmate", "chron", "classInt", "cli", "cliapp",
# "clock", "colorspace", "commonmark", "conflicted", "conquer",
# "coro", "covr", "cpp11", "crayon", "crosstalk", "curl", "CVST",
# "data.table", "DBI", "DBItest", "dbplyr", "ddalpha", "debugme",
# "decor", "deldir", "DEoptimR", "desc", "devtools",
# "DiagrammeR", "diffobj", "digest", "dimRed", "downlit",
# "dplyr", "DT", "e1071", "earth", "evaluate", "fansi", "farver",
# "fastICA", "fastmap", "fastmatch", "filehash", "filelock",
# "FNN", "Formula", "fs", "furrr", "future", "future.apply",
# "gargle", "gdata", "generics", "geometry", "geosphere",
# "gganimate", "ggforce", "ggplot2", "ggThemeAssist", "gh",
# "gitcreds", "globals", "glue", "gower", "gplots", "gt",
# "gtable", "gtools", "here", "hexbin", "highr", "Hmisc", "hms",
# "htmlTable", "htmltools", "htmlwidgets", "httpuv", "httr",
# "httr2", "igraph", "interp", "ipred", "isoband", "jpeg",
# "jsonlite", "kableExtra", "kernlab", "knitr", "ks", "labeling",
# "later", "latticeExtra", "lava", "leaflet", "lifecycle",
# "linprog", "lintr", "listenv", "lme4", "lobstr", "logcondens",
# "lpSolve", "lubridate", "lwgeom", "magic", "magrittr",
# "mapproj", "maps", "markdown", "MatrixModels", "matrixStats",
# "mclust", "mda", "mets", "mime", "minqa", "mlbench",
# "MLmetrics", "mockery", "mockr", "modeldata", "multcomp",
# "multicool", "munsell", "mvtnorm", "nloptr", "odbc", "openssl",
# "pacman", "pagedown", "palmerpenguins", "parallelly", "pillar",
# "pingr", "pkgbuild", "pkgcache", "pkgdepends", "pkgdown",
# "pkgKitten", "pkgload", "pkgsearch", "plot3D", "plotly",
# "plotmo", "plotrix", "pls", "plyr", "png", "polyclip",
# "pracma", "prettycode", "prettyunits", "pROC", "processx",
# "prodlim", "profmem", "profvis", "progress", "progressr",
# "promises", "proxy", "ps", "purrr", "quantmod", "quantreg",
# "R6", "ragg", "RANN", "rappdirs", "raster", "RColorBrewer",
# "Rcpp", "RcppArmadillo", "RcppEigen", "RcppRoll", "readr",
# "recipes", "rematch2", "remotes", "repurrrsive", "reticulate",
# "rex", "rgl", "rlang", "RMariaDB", "rmarkdown", "RMySQL",
# "robustbase", "Rook", "roxygen2", "RPostgres", "RPostgreSQL",
# "rprojroot", "rsample", "rsconnect", "RSpectra", "RSQLite",
# "rstudioapi", "RUnit", "rvest", "s2", "sandwich", "sass",
# "scales", "setRNG", "sf", "sfsmisc", "shiny", "slider",
# "sodium", "sourcetools", "sp", "SparseM", "spatstat",
# "spatstat.data", "spatstat.geom", "spatstat.linnet",
# "spatstat.sparse", "spatstat.utils", "statmod", "stringi",
# "stringr", "svglite", "sys", "systemfonts", "TeachingDemos",
# "terra", "testthat", "textshaping", "TH.data", "tibble",
# "tidyr", "tidyselect", "tidyverse", "tikzDevice", "timeDate",
# "timereg", "timeSeries", "tinytex", "tseries", "TTR", "tzdb",
# "units", "usethis", "utf8", "vctrs", "vdiffr", "viridis",
# "viridisLite", "visNetwork", "waldo", "warp", "webfakes",
# "webutils", "withr", "wk", "wkutils", "xfun", "XML", "xml2",
# "xmlparsedata", "xts", "yaml", "zeallot", "zoo"
# ), update = TRUE, ask = FALSE, force = TRUE)

# Search for Bioconductor packages available for installation with
# your current version of R and Bioconductor.
# BiocManager::available() will return a list of all available Bioconductor packages
# for the current version of R and Bioconductor.
avail <- BiocManager::available()
length(avail) # all CRAN & Bioconductor packages
# BiocManager::available("BSgenome.Hsapiens") # BSgenome.Hsapiens.* packages

# Display some example Bioconductor packages available for your platform.
dat_sample_bioc_pkgs <- tibble::tibble(sample_pkgs = avail) |>
    dplyr::slice_sample(n = 10) |>
    dplyr::arrange(sample_pkgs)
print(dat_sample_bioc_pkgs)

# Use BiocManager to install the Bioconductor packages.
# BiocManager::install() should be used to manage (e.g., install, update, delete)
# Bioconductor packages instead of install.packages(). Note that BiocManager::install()
# can be used to install CRAN packages as well.
BiocManager::install(
    c(
        "BiocGenerics",
        "Biobase",
        "Biostrings",
        "GenomicRanges",
        "IRanges",
        "S4Vectors",
        "XVector",
        "BiocParallel",
        "BiocFileCache",
        "BiocIO"
    ),
    update = TRUE,
    ask = FALSE
)
