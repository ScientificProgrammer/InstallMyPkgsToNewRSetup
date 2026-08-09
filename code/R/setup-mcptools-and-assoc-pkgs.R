library(remotes)

pkgsToInstall <- c(
    "posit-dev/btw",
    "posit-dev/mcptools"
)
for (repoName in pkgsToInstall) {
    tryCatch(
        {
            remotes::install_github(
                repo = repoName,
                force = FALSE,
                build_vignettes = TRUE,
                build_manual = TRUE
            )
        },
        error = function(e) {
            pkgInstalled <- FALSE
        }
    )
}
