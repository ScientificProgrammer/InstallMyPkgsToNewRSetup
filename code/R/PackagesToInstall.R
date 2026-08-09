#!/usr/bin/env Rscript

DEFAULT_PKG_CSV <- "data/PkgsToInstall.csv"
detected_physical_cpus <- suppressWarnings(parallel::detectCores(logical = FALSE))
DEFAULT_NUM_CPUS <- if (is.na(detected_physical_cpus)) {
  1L
} else {
  max(1L, min(4L, as.integer(detected_physical_cpus)))
}
DEFAULT_DEPENDENCY_MODE <- "hard"
DEFAULT_LOG_DIR <- "tmp"
LOG_CHILD_ENVVAR <- "PACKAGES_TO_INSTALL_LOG_CHILD"
LOG_FILE_ENVVAR <- "PACKAGES_TO_INSTALL_LOG_FILE"
RESULTS_FILE_ENVVAR <- "PACKAGES_TO_INSTALL_RESULTS_FILE"
METADATA_FILE_ENVVAR <- "PACKAGES_TO_INSTALL_METADATA_FILE"
RUN_ID_ENVVAR <- "PACKAGES_TO_INSTALL_RUN_ID"
BOOTSTRAP_CRAN_PKGS <- c("curl", "here", "pkgdepends", "pak", "RCurl", "remotes", "sessioninfo")
BOOTSTRAP_GITHUB_PKGS <- c("r-lib/rlang")
STATIC_V8_GITHUB_REPOS <- c("jeroen/V8")
LEAFLET_COMPAT_REPO <- "rstudio/leaflet"
LEAFLET_COMPAT_REF <- "leaflet@2.1.2"
LEAFLET_COMPAT_MIN_RASTER <- "3.6.3"
LEAFLET_COMPAT_MIN_TERRA <- "1.8-5"
LEAFLET_COMPAT_REQUIRED_PKGS <- c("base64enc", "markdown", "raster", "sp", "terra")
PKG_INSTALL_MAX_ATTEMPTS <- 2L
V8_STATIC_ENVVARS <- c("DOWNLOAD_STATIC_LIBV8", "V8_PKG_CFLAGS", "V8_PKG_LIBS", "INCLUDE_DIR", "LIB_DIR")

usage <- function(status = 0L) {
  cat(
    "Usage: Rscript code/R/PackagesToInstall.R [options]\n",
    "\n",
    "Install the GitHub R packages listed in data/PkgsToInstall.csv.\n",
    "\n",
    "Options:\n",
    "  --csv PATH         Package CSV path. Default: data/PkgsToInstall.csv\n",
    "  --validate-only   Validate the CSV and exit without installing.\n",
    "  --dry-run         Validate and print the install plan without installing.\n",
    sprintf("  --ncpus N         CPUs for source builds. Default: %d (host-aware, max 4)\n", DEFAULT_NUM_CPUS),
    "  --dependency-mode MODE\n",
    "                    Dependency mode for rows with dependencies=TRUE:\n",
    "                    hard, soft, all, or none. Default: hard\n",
    "  --v8-mode MODE    V8 build mode: auto, static, or system. Default: auto\n",
    "  --log-dir DIR     Write transcript and result artifacts to DIR. Default: tmp\n",
    "  --no-log          Disable the default transcript and result artifact logging.\n",
    "  --help, -h        Show this help text.\n",
    sep = ""
  )
  quit(status = status, save = "no")
}

parse_args <- function(args) {
  parsed <- list(
    csv = DEFAULT_PKG_CSV,
    validate_only = FALSE,
    dry_run = FALSE,
    ncpus = DEFAULT_NUM_CPUS,
    dependency_mode = DEFAULT_DEPENDENCY_MODE,
    v8_mode = "auto",
    log_dir = DEFAULT_LOG_DIR,
    log_enabled = TRUE
  )

  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]

    if (identical(arg, "--csv")) {
      i <- i + 1L
      if (i > length(args) || !nzchar(args[[i]])) {
        stop("--csv requires a path.", call. = FALSE)
      }
      parsed$csv <- args[[i]]
    } else if (identical(arg, "--validate-only")) {
      parsed$validate_only <- TRUE
    } else if (identical(arg, "--dry-run")) {
      parsed$dry_run <- TRUE
    } else if (identical(arg, "--ncpus")) {
      i <- i + 1L
      if (i > length(args) || !grepl("^[1-9][0-9]*$", args[[i]])) {
        stop("--ncpus requires a positive integer.", call. = FALSE)
      }
      parsed$ncpus <- as.integer(args[[i]])
    } else if (identical(arg, "--dependency-mode")) {
      i <- i + 1L
      if (i > length(args) || !(args[[i]] %in% c("hard", "soft", "all", "none"))) {
        stop("--dependency-mode requires one of: hard, soft, all, none.", call. = FALSE)
      }
      parsed$dependency_mode <- args[[i]]
    } else if (identical(arg, "--v8-mode")) {
      i <- i + 1L
      if (i > length(args) || !(args[[i]] %in% c("auto", "static", "system"))) {
        stop("--v8-mode requires one of: auto, static, system.", call. = FALSE)
      }
      parsed$v8_mode <- args[[i]]
    } else if (identical(arg, "--log-dir")) {
      i <- i + 1L
      if (i > length(args) || !nzchar(args[[i]])) {
        stop("--log-dir requires a directory path.", call. = FALSE)
      }
      parsed$log_dir <- args[[i]]
    } else if (identical(arg, "--no-log")) {
      parsed$log_enabled <- FALSE
    } else if (arg %in% c("--help", "-h")) {
      usage(0L)
    } else {
      stop(sprintf("Unknown option: %s", arg), call. = FALSE)
    }

    i <- i + 1L
  }

  parsed
}

script_path <- function() {
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(file_arg) == 0L) {
    return(NA_character_)
  }

  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = FALSE)
}

repo_root <- function() {
  path <- script_path()
  if (is.na(path)) {
    return(getwd())
  }

  normalizePath(file.path(dirname(path), "..", ".."), mustWork = FALSE)
}

resolve_path <- function(path, root) {
  if (file.exists(path)) {
    return(normalizePath(path, mustWork = TRUE))
  }

  rooted_path <- file.path(root, path)
  if (file.exists(rooted_path)) {
    return(normalizePath(rooted_path, mustWork = TRUE))
  }

  stop(sprintf("File not found: %s", path), call. = FALSE)
}

resolve_log_dir <- function(path, root) {
  if (grepl("^/", path)) {
    return(normalizePath(path, mustWork = FALSE))
  }

  normalizePath(file.path(root, path), mustWork = FALSE)
}

unique_output_path <- function(path) {
  if (!file.exists(path)) {
    return(path)
  }

  dir_name <- dirname(path)
  extension <- tools::file_ext(path)
  stem <- if (nzchar(extension)) {
    tools::file_path_sans_ext(basename(path))
  } else {
    basename(path)
  }
  suffix <- if (nzchar(extension)) paste0(".", extension) else ""

  for (idx in seq_len(999L)) {
    candidate <- file.path(dir_name, sprintf("%s_%03d%s", stem, idx, suffix))
    if (!file.exists(candidate)) {
      return(candidate)
    }
  }

  stop(sprintf("Could not create a unique output path for %s", path), call. = FALSE)
}

make_run_paths <- function(log_dir) {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

  list(
    run_id = timestamp,
    log_file = unique_output_path(
      file.path(log_dir, sprintf("output_of_PackagesToInstall-dot-R.%s.txt", timestamp))
    ),
    results_file = unique_output_path(
      file.path(log_dir, sprintf("packages_to_install_results.%s.csv", timestamp))
    ),
    metadata_file = unique_output_path(
      file.path(log_dir, sprintf("packages_to_install_run_metadata.%s.csv", timestamp))
    )
  )
}

logging_child <- function() {
  identical(Sys.getenv(LOG_CHILD_ENVVAR, unset = "0"), "1")
}

runtime_paths <- function() {
  list(
    run_id = Sys.getenv(RUN_ID_ENVVAR, unset = ""),
    log_file = Sys.getenv(LOG_FILE_ENVVAR, unset = ""),
    results_file = Sys.getenv(RESULTS_FILE_ENVVAR, unset = ""),
    metadata_file = Sys.getenv(METADATA_FILE_ENVVAR, unset = "")
  )
}

logging_tools_available <- function() {
  nzchar(Sys.which("bash")) && nzchar(Sys.which("tee"))
}

reexec_with_logging_if_needed <- function() {
  if (logging_child()) {
    return(invisible(FALSE))
  }

  args <- parse_args(commandArgs(TRUE))
  if (!isTRUE(args$log_enabled)) {
    return(invisible(FALSE))
  }

  script_file <- script_path()
  if (is.na(script_file) || !file.exists(script_file)) {
    warning("Could not determine script path; running without transcript logging.", call. = FALSE)
    return(invisible(FALSE))
  }

  if (!logging_tools_available()) {
    warning("bash and tee are required for transcript logging; running without transcript logging.", call. = FALSE)
    return(invisible(FALSE))
  }

  root <- repo_root()
  log_dir <- resolve_log_dir(args$log_dir, root)
  dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

  paths <- make_run_paths(log_dir)
  rscript_path <- file.path(R.home("bin"), "Rscript")
  wrapper_file <- unique_output_path(
    file.path(log_dir, sprintf("packages_to_install_log_wrapper.%s.sh", paths$run_id))
  )
  wrapper_script <- paste(
    "#!/usr/bin/env bash",
    "set -euo pipefail",
    "rscript_path=\"$1\"",
    "script_file=\"$2\"",
    "log_file=\"$3\"",
    "results_file=\"$4\"",
    "metadata_file=\"$5\"",
    "run_id=\"$6\"",
    "shift 6",
    sprintf("export %s=1", LOG_CHILD_ENVVAR),
    sprintf("export %s=\"$log_file\"", LOG_FILE_ENVVAR),
    sprintf("export %s=\"$results_file\"", RESULTS_FILE_ENVVAR),
    sprintf("export %s=\"$metadata_file\"", METADATA_FILE_ENVVAR),
    sprintf("export %s=\"$run_id\"", RUN_ID_ENVVAR),
    "\"$rscript_path\" \"$script_file\" \"$@\" 2>&1 | tee \"$log_file\"",
    sep = "\n"
  )
  writeLines(wrapper_script, wrapper_file, useBytes = TRUE)
  Sys.chmod(wrapper_file, mode = "0700")

  status <- system2(
    "bash",
    c(
      wrapper_file,
      rscript_path,
      script_file,
      paths$log_file,
      paths$results_file,
      paths$metadata_file,
      paths$run_id,
      commandArgs(TRUE)
    )
  )
  if (file.exists(wrapper_file)) {
    unlink(wrapper_file)
  }

  if (is.null(status)) {
    status <- 0L
  }

  cat(sprintf("\nTranscript log saved to %s\n", paths$log_file))
  if (file.exists(paths$results_file)) {
    cat(sprintf("Package results saved to %s\n", paths$results_file))
  }
  if (file.exists(paths$metadata_file)) {
    cat(sprintf("Run metadata saved to %s\n", paths$metadata_file))
  }

  quit(status = as.integer(status), save = "no")
}

set_cran_repo <- function() {
  repos <- getOption("repos")
  if (is.null(repos) || is.na(repos[["CRAN"]]) || identical(repos[["CRAN"]], "@CRAN@")) {
    options(repos = c(CRAN = "https://cloud.r-project.org"))
  }
}

installed_pkg_names <- function() {
  rownames(installed.packages())
}

r_package_installed <- function(pkg_name) {
  requireNamespace(pkg_name, quietly = TRUE)
}

installed_r_package_version <- function(pkg_name) {
  if (!r_package_installed(pkg_name)) {
    return(NA_character_)
  }

  as.character(utils::packageVersion(pkg_name))
}

package_version_less_than <- function(pkg_name, minimum_version) {
  installed_version <- installed_r_package_version(pkg_name)
  if (is.na(installed_version)) {
    return(FALSE)
  }

  utils::packageVersion(pkg_name) < package_version(minimum_version)
}

install_cran_if_missing <- function(pkg_names, ncpus) {
  missing <- setdiff(pkg_names, installed_pkg_names())
  if (length(missing) == 0L) {
    cat("Bootstrap CRAN packages are already installed.\n")
    return(invisible(character()))
  }

  cat("Installing bootstrap CRAN packages:\n")
  cat(sprintf("  %s\n", missing), sep = "")
  install.packages(missing, type = "source", Ncpus = ncpus)
  invisible(missing)
}

parse_logical_column <- function(values, column_name) {
  if (is.logical(values)) {
    return(values)
  }

  normalized <- tolower(trimws(as.character(values)))
  valid <- normalized %in% c("true", "false", "t", "f", "1", "0")

  if (any(!valid | is.na(normalized))) {
    bad_values <- unique(values[!valid | is.na(normalized)])
    stop(
      sprintf(
        "Column '%s' must contain only TRUE/FALSE values. Bad value(s): %s",
        column_name,
        paste(bad_values, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  normalized %in% c("true", "t", "1")
}

validate_pkg_table <- function(pkg_table, csv_path) {
  required_cols <- c(
    "repo_name",
    "force_build",
    "dependencies",
    "build_vignettes",
    "build_manuals"
  )
  missing_cols <- setdiff(required_cols, names(pkg_table))

  if (length(missing_cols) > 0L) {
    stop(
      sprintf(
        "Package CSV is missing required column(s): %s",
        paste(missing_cols, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  pkg_table <- pkg_table[, required_cols]
  pkg_table$repo_name <- trimws(as.character(pkg_table$repo_name))

  empty_rows <- which(!nzchar(pkg_table$repo_name) | is.na(pkg_table$repo_name))
  if (length(empty_rows) > 0L) {
    stop(
      sprintf("Package CSV has empty repo_name value(s) on row(s): %s", paste(empty_rows + 1L, collapse = ", ")),
      call. = FALSE
    )
  }

  dup_pkgs <- unique(pkg_table$repo_name[duplicated(pkg_table$repo_name)])
  if (length(dup_pkgs) > 0L) {
    stop(
      sprintf(
        "Package CSV has duplicate repo_name value(s): %s\nUpdate %s to remove duplicates.",
        paste(dup_pkgs, collapse = ", "),
        csv_path
      ),
      call. = FALSE
    )
  }

  logical_cols <- setdiff(required_cols, "repo_name")
  for (column_name in logical_cols) {
    pkg_table[[column_name]] <- parse_logical_column(pkg_table[[column_name]], column_name)
  }

  pkg_table
}

read_pkg_table <- function(csv_path) {
  pkg_table <- read.csv(
    csv_path,
    strip.white = TRUE,
    stringsAsFactors = FALSE
  )

  validate_pkg_table(pkg_table, csv_path)
}

dependency_arg <- function(install_dependencies, dependency_mode) {
  if (!isTRUE(install_dependencies) || identical(dependency_mode, "none")) {
    return(FALSE)
  }

  pkgdepends::as_pkg_dependencies(dependency_mode)
}

shell_command <- function(values) {
  paste(shQuote(values), collapse = " ")
}

collapse_value <- function(values) {
  if (length(values) == 0L) {
    return("")
  }

  paste(values, collapse = "; ")
}

format_run_time <- function(time) {
  format(time, "%Y-%m-%d %H:%M:%S %z")
}

result_columns <- function() {
  c(
    "started_at",
    "finished_at",
    "phase",
    "repo_name",
    "install_ref",
    "status",
    "elapsed_sec",
    "message"
  )
}

empty_results <- function() {
  stats::setNames(
    data.frame(matrix(ncol = length(result_columns()), nrow = 0L), stringsAsFactors = FALSE),
    result_columns()
  )
}

initialize_results_file <- function(results_file) {
  if (!nzchar(results_file)) {
    return(invisible(NULL))
  }

  dir.create(dirname(results_file), recursive = TRUE, showWarnings = FALSE)
  write.csv(empty_results(), results_file, row.names = FALSE, quote = TRUE)
  invisible(NULL)
}

append_result_rows <- function(results_file, results) {
  if (!nzchar(results_file) || nrow(results) == 0L) {
    return(invisible(NULL))
  }

  dir.create(dirname(results_file), recursive = TRUE, showWarnings = FALSE)
  write.table(
    results[, result_columns(), drop = FALSE],
    file = results_file,
    append = TRUE,
    sep = ",",
    row.names = FALSE,
    col.names = FALSE,
    quote = TRUE,
    qmethod = "double"
  )
  invisible(NULL)
}

write_run_metadata <- function(metadata_file,
                               args,
                               root,
                               csv_path,
                               pkg_table,
                               v8_strategy,
                               paths,
                               started_at,
                               run_status,
                               exit_code,
                               error_message = "") {
  if (!nzchar(metadata_file)) {
    return(invisible(NULL))
  }

  keys <- c(
    "run_id",
    "run_status",
    "exit_code",
    "started_at",
    "updated_at",
    "command",
    "working_directory",
    "script_path",
    "repo_root",
    "csv_path",
    "package_rows",
    "validate_only",
    "dry_run",
    "ncpus",
    "dependency_mode",
    "requested_v8_mode",
    "resolved_v8_mode",
    "v8_reason",
    "log_file",
    "results_file",
    "metadata_file",
    "r_version",
    "platform",
    "lib_paths",
    "cran_repos",
    "nodejs_version",
    "libnode_dev_version",
    "error_message"
  )

  values <- c(
    paths$run_id,
    run_status,
    as.character(exit_code),
    format(started_at, "%Y-%m-%d %H:%M:%S %z"),
    format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    shell_command(c(file.path(R.home("bin"), "Rscript"), script_path(), commandArgs(TRUE))),
    getwd(),
    script_path(),
    root,
    csv_path,
    as.character(nrow(pkg_table)),
    as.character(args$validate_only),
    as.character(args$dry_run),
    as.character(args$ncpus),
    args$dependency_mode,
    args$v8_mode,
    v8_strategy$mode,
    v8_strategy$reason,
    paths$log_file,
    paths$results_file,
    paths$metadata_file,
    R.version.string,
    R.version$platform,
    collapse_value(.libPaths()),
    collapse_value(getOption("repos")),
    dpkg_package_version("nodejs"),
    dpkg_package_version("libnode-dev"),
    error_message
  )

  metadata <- data.frame(key = keys, value = values, stringsAsFactors = FALSE)
  dir.create(dirname(metadata_file), recursive = TRUE, showWarnings = FALSE)
  write.csv(metadata, metadata_file, row.names = FALSE, quote = TRUE)
  invisible(NULL)
}

command_output <- function(command, args) {
  if (!nzchar(Sys.which(command))) {
    return(character())
  }

  tryCatch(
    suppressWarnings(system2(command, args, stdout = TRUE, stderr = FALSE)),
    error = function(e) character()
  )
}

dpkg_package_version <- function(pkg_name) {
  output <- command_output("dpkg-query", c("-W", "-f=\\${Version}", pkg_name))
  if (length(output) == 0L) {
    return("")
  }

  output[[1]]
}

dpkg_package_installed <- function(pkg_name) {
  status <- command_output("dpkg-query", c("-W", "-f=\\${db:Status-Abbrev}", pkg_name))
  length(status) > 0L && grepl("^ii", status[[1]])
}

nodesource_nodejs_installed <- function() {
  grepl("nodesource", dpkg_package_version("nodejs"), fixed = TRUE)
}

resolve_v8_strategy <- function(requested_mode, pkg_table) {
  if (!any(pkg_table$repo_name %in% STATIC_V8_GITHUB_REPOS)) {
    return(list(mode = "unused", reason = "jeroen/V8 is not in the install table."))
  }

  if (identical(requested_mode, "static")) {
    return(list(mode = "static", reason = "--v8-mode static was requested."))
  }

  if (identical(requested_mode, "system")) {
    return(list(mode = "system", reason = "--v8-mode system was requested."))
  }

  if (nodesource_nodejs_installed()) {
    return(list(
      mode = "static",
      reason = "NodeSource nodejs is installed; Ubuntu libnode-dev conflicts with its /usr/include/node files."
    ))
  }

  if (dpkg_package_installed("libnode-dev")) {
    return(list(mode = "system", reason = "Ubuntu/Debian libnode-dev is installed."))
  }

  list(
    mode = "static",
    reason = "No system libnode-dev package is installed; static libv8 is the safer default."
  )
}

restore_envvar <- function(name, value) {
  if (is.na(value)) {
    Sys.unsetenv(name)
  } else {
    do.call(Sys.setenv, stats::setNames(list(value), name))
  }
}

snapshot_envvars <- function(names) {
  stats::setNames(
    lapply(names, Sys.getenv, unset = NA_character_),
    names
  )
}

restore_envvars <- function(snapshot) {
  for (name in names(snapshot)) {
    restore_envvar(name, snapshot[[name]])
  }

  invisible(NULL)
}

apply_v8_strategy_env <- function(v8_strategy) {
  old_env <- snapshot_envvars(V8_STATIC_ENVVARS)

  if (identical(v8_strategy$mode, "static")) {
    Sys.setenv(DOWNLOAD_STATIC_LIBV8 = "1")
    Sys.unsetenv(c("V8_PKG_CFLAGS", "V8_PKG_LIBS", "INCLUDE_DIR", "LIB_DIR"))
    cat("Using DOWNLOAD_STATIC_LIBV8=1 for all V8 builds.\n")
  } else if (identical(v8_strategy$mode, "system")) {
    Sys.unsetenv(c("DOWNLOAD_STATIC_LIBV8", "V8_PKG_CFLAGS", "V8_PKG_LIBS"))
    cat("Using system libv8/libnode for V8 builds.\n")
  }

  old_env
}

install_ref_for_repo <- function(repo_name, v8_strategy) {
  if (repo_name %in% STATIC_V8_GITHUB_REPOS && identical(v8_strategy$mode, "static")) {
    return("V8")
  }

  repo_name
}

package_name_for_ref <- function(repo_name, install_ref) {
  ref_without_version <- sub("@.*$", "", install_ref)
  ref_without_version <- sub("^.*/", "", ref_without_version)

  if (nzchar(ref_without_version)) {
    return(ref_without_version)
  }

  sub("^.*/", "", repo_name)
}

leaflet_compat_required <- function(repo_name) {
  identical(repo_name, LEAFLET_COMPAT_REPO) &&
    (
      !r_package_installed("raster") ||
        !r_package_installed("terra") ||
        package_version_less_than("raster", LEAFLET_COMPAT_MIN_RASTER) ||
        package_version_less_than("terra", LEAFLET_COMPAT_MIN_TERRA)
    )
}

missing_leaflet_compat_packages <- function() {
  LEAFLET_COMPAT_REQUIRED_PKGS[!vapply(LEAFLET_COMPAT_REQUIRED_PKGS, r_package_installed, logical(1))]
}

leaflet_compat_reason <- function() {
  sprintf(
    paste(
      "%s requires raster >= %s, which pulls terra >= %s.",
      "This host has raster %s and terra %s, so installing %s avoids a source build",
      "of current terra against the older apt GDAL stack."
    ),
    LEAFLET_COMPAT_REPO,
    LEAFLET_COMPAT_MIN_RASTER,
    LEAFLET_COMPAT_MIN_TERRA,
    installed_r_package_version("raster"),
    installed_r_package_version("terra"),
    LEAFLET_COMPAT_REF
  )
}

install_strategy_for_repo <- function(repo_name, install_dependencies, dependency_mode, v8_strategy) {
  install_ref <- install_ref_for_repo(repo_name, v8_strategy)
  dependencies <- dependency_arg(install_dependencies, dependency_mode)
  message <- "installed or already current"
  preflight_error <- ""

  if (!identical(install_ref, repo_name)) {
    message <- sprintf("installed via %s", install_ref)
  }

  if (leaflet_compat_required(repo_name)) {
    missing_pkgs <- missing_leaflet_compat_packages()
    install_ref <- LEAFLET_COMPAT_REF
    dependencies <- FALSE
    message <- leaflet_compat_reason()

    if (length(missing_pkgs) > 0L) {
      preflight_error <- sprintf(
        "Cannot install %s with the Jammy/Mint compatibility pin until these apt-compatible R packages are installed: %s. Run code/linux/setup-debian-distros.sh first.",
        LEAFLET_COMPAT_REPO,
        paste(missing_pkgs, collapse = ", ")
      )
    }
  }

  list(
    install_ref = install_ref,
    dependencies = dependencies,
    package_name = package_name_for_ref(repo_name, install_ref),
    message = message,
    preflight_error = preflight_error
  )
}

transient_install_error <- function(message) {
  grepl(
    "Cannot query GitHub|are you offline|Could not resolve|Timeout|timed out|HTTP error 5|connection",
    message,
    ignore.case = TRUE
  )
}

run_pak_install <- function(install_ref, dependencies, upgrade) {
  pak::pkg_install(
    pkg = install_ref,
    upgrade = upgrade,
    ask = FALSE,
    dependencies = dependencies
  )
}

install_one_github_pkg <- function(repo_name, install_dependencies, dependency_mode, upgrade, phase, v8_strategy) {
  start_time <- Sys.time()
  status <- "ok"
  strategy <- install_strategy_for_repo(repo_name, install_dependencies, dependency_mode, v8_strategy)
  message <- strategy$message
  install_ref <- strategy$install_ref

  if (nzchar(strategy$preflight_error)) {
    status <- "failed"
    message <- strategy$preflight_error
  } else {
    install_error <- NULL

    for (attempt in seq_len(PKG_INSTALL_MAX_ATTEMPTS)) {
      tryCatch(
        {
          run_pak_install(
            install_ref = install_ref,
            dependencies = strategy$dependencies,
            upgrade = upgrade
          )
          install_error <- NULL
        },
        error = function(e) {
          install_error <<- conditionMessage(e)
        }
      )

      if (is.null(install_error)) {
        break
      }

      if (attempt < PKG_INSTALL_MAX_ATTEMPTS && transient_install_error(install_error)) {
        cat(sprintf("Transient install error for %s; retrying once.\n", repo_name))
        Sys.sleep(5)
      } else {
        break
      }
    }

    if (!is.null(install_error)) {
      if (transient_install_error(install_error) && r_package_installed(strategy$package_name)) {
        status <- "ok"
        message <- sprintf(
          "kept installed %s %s after transient install error: %s",
          strategy$package_name,
          installed_r_package_version(strategy$package_name),
          install_error
        )
      } else {
        status <- "failed"
        message <- install_error
      }
    }
  }

  data.frame(
    started_at = format_run_time(start_time),
    finished_at = format_run_time(Sys.time()),
    phase = phase,
    repo_name = repo_name,
    install_ref = install_ref,
    status = status,
    elapsed_sec = round(as.numeric(difftime(Sys.time(), start_time, units = "secs")), 1L),
    message = message,
    stringsAsFactors = FALSE
  )
}

install_bootstrap_github_pkgs <- function(dependency_mode, v8_strategy, results_file) {
  results <- vector("list", length(BOOTSTRAP_GITHUB_PKGS))

  for (row_idx in seq_along(BOOTSTRAP_GITHUB_PKGS)) {
    repo_name <- BOOTSTRAP_GITHUB_PKGS[[row_idx]]

    cat("\n")
    cat(strrep("*", 76L), "\n", sep = "")
    cat(sprintf("Installing bootstrap package %s\n", repo_name))
    cat(strrep("*", 76L), "\n", sep = "")

    result <- install_one_github_pkg(
      repo_name = repo_name,
      install_dependencies = TRUE,
      dependency_mode = dependency_mode,
      upgrade = TRUE,
      phase = "bootstrap",
      v8_strategy = v8_strategy
    )
    append_result_rows(results_file, result)
    results[[row_idx]] <- result
  }

  if (length(results) == 0L) {
    return(empty_results())
  }

  do.call(rbind, results)
}

install_bulk_github_pkgs <- function(pkg_table, dependency_mode, v8_strategy, results_file) {
  install_table <- pkg_table
  results <- vector("list", nrow(install_table))

  for (row_idx in seq_len(nrow(install_table))) {
    repo_name <- install_table$repo_name[[row_idx]]

    cat("\n")
    cat(strrep("*", 76L), "\n", sep = "")
    cat(sprintf("Installing %s\n", repo_name))
    cat(strrep("*", 76L), "\n", sep = "")

    result <- install_one_github_pkg(
      repo_name = repo_name,
      install_dependencies = install_table$dependencies[[row_idx]],
      dependency_mode = dependency_mode,
      upgrade = FALSE,
      phase = "bulk",
      v8_strategy = v8_strategy
    )
    append_result_rows(results_file, result)
    results[[row_idx]] <- result
  }

  installed_results <- if (length(results) == 0L) {
    empty_results()
  } else {
    do.call(rbind, results)
  }
  installed_results
}

print_install_plan <- function(pkg_table, v8_strategy, dependency_mode) {
  cat(sprintf("Validated %d package row(s).\n", nrow(pkg_table)))
  cat(sprintf("\nDependency mode: %s\n", dependency_mode))
  cat(sprintf("\nV8 build mode: %s\n", v8_strategy$mode))
  cat(sprintf("V8 build reason: %s\n", v8_strategy$reason))

  if (any(vapply(pkg_table$repo_name, leaflet_compat_required, logical(1)))) {
    cat("\nCompatibility install override(s):\n")
    cat(sprintf("  %s -> %s\n", LEAFLET_COMPAT_REPO, LEAFLET_COMPAT_REF))
    cat(sprintf("  Reason: %s\n", leaflet_compat_reason()))
  }

  cat("\nBootstrap CRAN package(s):\n")
  cat(sprintf("  %s\n", BOOTSTRAP_CRAN_PKGS), sep = "")
  cat("\nBootstrap GitHub package(s):\n")
  cat(sprintf("  %s\n", BOOTSTRAP_GITHUB_PKGS), sep = "")
  cat("\nBulk GitHub package(s):\n")
  cat(sprintf("  %s\n", pkg_table$repo_name), sep = "")
}

print_summary <- function(results) {
  cat("\n")
  cat(strrep("=", 76L), "\n", sep = "")
  cat("Install summary\n")
  cat(strrep("=", 76L), "\n", sep = "")

  print(results[, c("phase", "repo_name", "status", "elapsed_sec")], row.names = FALSE)

  failures <- results[results$status == "failed", , drop = FALSE]
  if (nrow(failures) > 0L) {
    cat("\nFailures:\n")
    for (row_idx in seq_len(nrow(failures))) {
      cat(sprintf("- %s: %s\n", failures$repo_name[[row_idx]], failures$message[[row_idx]]))
    }
  }

  invisible(failures)
}

print_run_artifacts <- function(paths) {
  if (!nzchar(paths$log_file) && !nzchar(paths$results_file) && !nzchar(paths$metadata_file)) {
    return(invisible(NULL))
  }

  cat("Run artifacts:\n")
  if (nzchar(paths$log_file)) {
    cat(sprintf("  transcript: %s\n", paths$log_file))
  }
  if (nzchar(paths$results_file)) {
    cat(sprintf("  results:    %s\n", paths$results_file))
  }
  if (nzchar(paths$metadata_file)) {
    cat(sprintf("  metadata:   %s\n", paths$metadata_file))
  }
  cat("\n")

  invisible(NULL)
}

main <- function() {
  started_at <- Sys.time()
  exit_code <- 0L
  run_status <- "completed"
  args <- parse_args(commandArgs(TRUE))
  root <- repo_root()
  csv_path <- resolve_path(args$csv, root)
  paths <- runtime_paths()

  set_cran_repo()
  pkg_table <- read_pkg_table(csv_path)
  v8_strategy <- resolve_v8_strategy(args$v8_mode, pkg_table)

  print_run_artifacts(paths)
  initialize_results_file(paths$results_file)
  write_run_metadata(
    metadata_file = paths$metadata_file,
    args = args,
    root = root,
    csv_path = csv_path,
    pkg_table = pkg_table,
    v8_strategy = v8_strategy,
    paths = paths,
    started_at = started_at,
    run_status = "started",
    exit_code = NA_integer_
  )

  if (args$validate_only || args$dry_run) {
    print_install_plan(pkg_table, v8_strategy, args$dependency_mode)
    if (args$dry_run) {
      cat("\nDry run only; no R packages were installed.\n")
    }
    write_run_metadata(
      metadata_file = paths$metadata_file,
      args = args,
      root = root,
      csv_path = csv_path,
      pkg_table = pkg_table,
      v8_strategy = v8_strategy,
      paths = paths,
      started_at = started_at,
      run_status = run_status,
      exit_code = exit_code
    )
    return(exit_code)
  }

  install_cran_if_missing(BOOTSTRAP_CRAN_PKGS, args$ncpus)
  old_v8_env <- apply_v8_strategy_env(v8_strategy)
  on.exit(restore_envvars(old_v8_env), add = TRUE)

  options(Ncpus = args$ncpus)

  cat("\nInstalling bootstrap GitHub packages before the bulk install.\n")
  bootstrap_results <- install_bootstrap_github_pkgs(args$dependency_mode, v8_strategy, paths$results_file)
  bulk_results <- install_bulk_github_pkgs(
    pkg_table,
    args$dependency_mode,
    v8_strategy,
    paths$results_file
  )
  results <- rbind(bootstrap_results, bulk_results)
  failures <- print_summary(results)

  if (nrow(failures) > 0L) {
    exit_code <- 1L
    run_status <- "failed"
  }

  sessioninfo::session_info()
  write_run_metadata(
    metadata_file = paths$metadata_file,
    args = args,
    root = root,
    csv_path = csv_path,
    pkg_table = pkg_table,
    v8_strategy = v8_strategy,
    paths = paths,
    started_at = started_at,
    run_status = run_status,
    exit_code = exit_code
  )
  exit_code
}

exit_status <- tryCatch(
  {
    reexec_with_logging_if_needed()
    main()
  },
  error = function(e) {
    cat(sprintf("ERROR: %s\n", conditionMessage(e)), file = stderr())
    1L
  }
)

quit(status = as.integer(exit_status), save = "no")
