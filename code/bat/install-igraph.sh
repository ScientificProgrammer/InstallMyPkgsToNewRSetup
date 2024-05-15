#!/bin/bash

Rscript -e '
    options(
        repos = c(
            igraph = "https://igraph.r-universe.dev",
            CRAN = "https://cloud.r-project.org"
        )
    )
    install.packages("igraph");
    sessioninfo::session_info();
'