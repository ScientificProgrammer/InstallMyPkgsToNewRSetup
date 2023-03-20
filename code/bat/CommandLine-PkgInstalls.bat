RScript -e "if (!require(pak)) { try(install.packages('pak', repos = 'https://r-lib.github.io/p/pak/devel/', build_manual = TRUE, build_vignettes = TRUE, dependencies = TRUE)); sessioninfo::session_info(); } else cat('\n\n', 'package already exists...skipping install\n\n')"

RScript -e "if (!require(glue)) { try(install.packages('glue', type = 'source', repo = 'https://cloud.r-project.org/', build_manual = TRUE, build_vignettes = TRUE)); sessioninfo::session_info(); } else cat('\n\n', 'package already exists...skipping install\n\n')"

RScript -e "try(pak::pkg_install('r-lib/rlang'     , upgrade = TRUE, dependencies = pkgdepends::as_pkg_dependencies('all'))); sessioninfo::session_info()"

RScript -e "try(pak::pkg_install('r-lib/remotes'   , upgrade = TRUE, dependencies = pkgdepends::as_pkg_dependencies('all'))); sessioninfo::session_info()"

RScript -e "try(pak::pkg_install('tidyverse/tibble', upgrade = TRUE, dependencies = pkgdepends::as_pkg_dependencies('all'))); sessioninfo::session_info()"

RScript -e "try(pak::pkg_install('r-lib/pillar'    , upgrade = TRUE, dependencies = pkgdepends::as_pkg_dependencies('all'))); sessioninfo::session_info()"

RScript -e "try(pak::pkg_install('r-lib/processx'  , upgrade = TRUE, dependencies = pkgdepends::as_pkg_dependencies('all'))); sessioninfo::session_info()"

RScript -e "try(pak::pkg_install('r-lib/pkgload'   , upgrade = TRUE, dependencies = pkgdepends::as_pkg_dependencies('all'))); sessioninfo::session_info()"

RScript -e "try(pak::pkg_install('r-lib/vctrs'     , upgrade = TRUE, dependencies = pkgdepends::as_pkg_dependencies('all'))); sessioninfo::session_info()"

REM RScript -e "try(remotes::install_github('tidyverse/tibble', build_vignettes = TRUE, build_manual = TRUE, dependencies = TRUE)); sessioninfo::session_info();"
