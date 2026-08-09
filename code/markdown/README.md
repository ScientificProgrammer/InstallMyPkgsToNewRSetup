# InstallMyPkgsToNewRSetup

![GNU 3.0 License Badge](https://img.shields.io/github/license/ScientificProgrammer/InstallMyPkgsToNewRSetup)

## Purpose

This repository maintains Eric's personal R bootstrap workflow for headless
servers and interactive workstations. Its main job is to prepare a new R
installation with the system libraries and focused R package set needed for
analysis, reporting, visualization, databases, and package development.

The current maintained path is a Debian-family Linux workflow:

1. Install or validate system packages with `apt-get`.

2. Validate the R package manifest.

3. Install the R packages listed in `data/PkgsToInstall.csv`.

This is not an R package, and it is not a fully general cross-platform
provisioning tool.

## Support Status

### Debian 13 Trixie arm64

Status: current validated path.

The current dependency set and install preflight are validated on Debian 13
running on arm64. The CRAN `trixie-cran46` repository supplies R 4.6.x.

### Other Debian-Family Linux Distros

Status: plausible, but not fully validated.

The Linux script checks `/etc/os-release`, package candidates, `apt` repair
state, and TeX command shadowing before installing. Package names and versions
can still differ by distro release.

### Non-Debian Linux Distros

Status: not supported by the system package script.

The R installer may still be useful after system dependencies are installed
manually, but `code/linux/setup-debian-distros.sh` is `apt`-specific.

### Windows

Status: legacy / incomplete.

The repo began as a Windows-oriented helper, but the current maintained workflow
does not automate Rtools, MSYS2, Windows system libraries, TeX, or native
package-build prerequisites. Treat `code/bat/` as historical reference, not a
supported installer.

### macOS

Status: not supported.

There is no Homebrew or Xcode command-line-tools setup path in this repo.

## Repository Layout

- `data/PkgsToInstall.csv`: active GitHub R package manifest.

- `code/R/PackagesToInstall.R`: main R installer and manifest validator.

- `code/linux/setup-debian-distros.sh`: Debian-family system dependency
  installer and preflight checker.

- `code/R/bioconductor.R`: Bioconductor setup helper.

- `code/R/setup-mcptools-and-assoc-pkgs.R`: MCP tools setup helper.

- `code/bat/`: legacy Windows-era snippets and troubleshooting artifacts.

- `_pre_git_versions/`: historical pre-git versions of the R installer.

- `tmp/`: ignored local logs and run artifacts.

`code/markdown/README.md` is a mirrored Markdown copy of this file.

## Clone

```bash
git clone https://github.com/ScientificProgrammer/InstallMyPkgsToNewRSetup.git
cd InstallMyPkgsToNewRSetup
```

## Recommended Linux Workflow

### Step 0: Install R

Install current R before running this repository. On Debian 13, use CRAN's
`trixie-cran46` repository and verify its signing key fingerprint before adding
the repository:

```text
95C0 FAF3 8DB3 CCAD 0C08 0A7B DC78 B2DD EABC 47B7
```

The recommended deb822 source is `/etc/apt/sources.list.d/cran.sources`:

```text
Types: deb
URIs: https://cloud.r-project.org/bin/linux/debian/
Suites: trixie-cran46/
Components:
Signed-By: /etc/apt/trusted.gpg.d/cran_debian_key.asc
```

After `apt-get update`, verify `apt-cache policy r-base` selects CRAN, then
install `r-base` and `r-base-dev`.

### Step 1: Run the Debian Preflight

Run a dry run before installing anything:

```bash
bash code/linux/setup-debian-distros.sh --dry-run
```

This checks:

- Whether the host looks like Debian, Ubuntu, Linux Mint, or a Debian-family
  distro.

- Whether every required `apt` package has an install candidate.

- Whether `apt`/`dpkg` already needs repair.

- Whether `/usr/local/texlive/...` commands shadow distro TeX tools.

Logs are written to:

```text
tmp/output_of_setup-debian-distros-dot-sh.<timestamp>.txt
```

### Step 2: Repair System Blockers

Resolve every preflight error before installing more packages.

One important blocker is a mixed TeX installation. If `/usr/local/texlive/...`
commands shadow distro TeX commands, Debian package maintainer scripts can
configure `tex-common` against the wrong TeX tree.

On a host where `apt` should own TeX, move the TeX Live symlinks out of
`/usr/local/bin`, then repair `dpkg`:

```bash
backup_dir="/usr/local/bin/texlive_2025_links_disabled.$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p "$backup_dir"

texlive_commands=(
    fmtutil
    fmtutil-sys
    fmtutil-user
    kpsewhich
    mktexlsr
    updmap
    updmap-sys
    pdftex
    luatex
    xetex
    tex
    latex
    pdflatex
    lualatex
    xelatex
    tlmgr
)

for name in "${texlive_commands[@]}"; do
    path="/usr/local/bin/$name"
    if [[ -L "$path" ]] && readlink "$path" | grep -q '^/usr/local/texlive/'; then
        sudo mv "$path" "$backup_dir/"
    fi
done

hash -r
which -a fmtutil-sys kpsewhich mktexlsr updmap-sys pdftex luatex xetex
kpsewhich -all fmtutil.cnf
sudo dpkg --configure -a
sudo apt-get -f install
```

### Step 3: Install Required Debian Packages

After the preflight passes, run the installer:

```bash
bash code/linux/setup-debian-distros.sh --yes
```

Omit `--yes` if you want `apt-get install` to prompt interactively.

Do not source this script. Run it with `bash`.

### Step 4: Validate the R Package Manifest

```bash
Rscript code/R/PackagesToInstall.R --validate-only
```

### Step 5: Run the R Package Installer

```bash
Rscript code/R/PackagesToInstall.R
```

The R installer writes logs by default. Each run creates:

- `tmp/output_of_PackagesToInstall-dot-R.<timestamp>.txt`

- `tmp/packages_to_install_results.<timestamp>.csv`

- `tmp/packages_to_install_run_metadata.<timestamp>.csv`

Use `--no-log` only when you deliberately want to disable those artifacts.

## R Installer Options

```text
Usage: Rscript code/R/PackagesToInstall.R [options]

Options:
  --csv PATH
      Package CSV path. Default: data/PkgsToInstall.csv
  --validate-only
      Validate the CSV and exit without installing.
  --dry-run
      Validate and print the install plan without installing.
  --ncpus N
      CPUs for source builds. Default: detected physical CPUs, capped at 4
  --dependency-mode MODE
      hard, soft, all, or none. Default: hard
  --v8-mode MODE
      auto, static, or system. Default: auto
  --log-dir DIR
      Write transcript and result artifacts to DIR. Default: tmp
  --no-log
      Disable default transcript and result artifact logging.
  --help, -h
      Show help.
```

Rows with `dependencies=TRUE` use hard dependencies by default: `Depends`,
`Imports`, and `LinkingTo`. This avoids pulling large optional dependency
trees, especially native packages that may not build cleanly against older
distro system libraries.

Use `--dependency-mode all` only when you deliberately want optional `Suggests`
and `Enhances` dependency trees.

## Curated Package Policy

The active manifest intentionally stays small. Bootstrap installation covers
`remotes`, `pak`, and the current GitHub version of `rlang`. The bulk manifest
contains 15 maintained repositories covering:

- DBI, ODBC, MariaDB/MySQL, PostgreSQL, SQLite, `dbplyr`, and `pool`.

- `tidyverse`, `Rcpp`, and `data.table`.

- DiagrammeR.

- `knitr`, `rmarkdown`, Quarto's R package, and `renv`.

Transitive dependencies are resolved in hard-dependency mode. Packages used
only occasionally should be installed per project with `renv` rather than
added to the global bootstrap.

## RStudio

RStudio is useful on interactive workstations, but it is not required for
R Markdown or Quarto rendering. The maintained headless path installs the R
packages, Pandoc, Quarto CLI, and targeted TeX Live components directly.
RStudio installation remains an optional workstation decision.

## Windows Suitability

The original repo was created during a Windows/R workflow era, but the current
branch is no longer a complete Windows bootstrap.

What may still be useful on Windows:

- `data/PkgsToInstall.csv` as a package intent manifest.

- Parts of `code/R/PackagesToInstall.R` after Windows prerequisites are
  installed.

- `code/bat/CommandLine-PkgInstalls.bat` as historical command examples.

Known gaps:

- No supported Rtools setup.

- No MSYS2 system-library setup.

- No Windows TeX setup.

- No Windows-specific handling for native package system requirements.

For Windows, start with validation only:

```bat
Rscript code/R/PackagesToInstall.R --validate-only --no-log
```

Do not expect the full installer to be reliable on a fresh Windows host until a
Windows-specific preflight and dependency setup path is added.

## Other Linux Suitability

For Ubuntu, Debian, and other Debian-family hosts, the intended first check is:

```bash
bash code/linux/setup-debian-distros.sh --dry-run
```

If that passes, the host is likely close enough to try the install path. If it
fails, use the preflight output as the compatibility report.

Known risk areas across distro releases:

- Package names may differ.

- Package versions may be older or newer than the validated Debian 13 host.

- TeX package ownership and native development-library versions can affect
  source package builds.

- Third-party package sources can change candidate versions.

For Fedora, Arch, openSUSE, Alpine, or other non-Debian distros, install system
prerequisites through that distro's package manager first, then use the R
installer cautiously.

## Background

This repo exists because R workstation setup is expensive to rediscover. Eric
has accumulated a set of R packages that are important enough to install early
on a new system rather than discovering missing packages during deadline work.

The package list favors current GitHub versions for many packages, which means
source builds and native system dependencies matter. That is why the current
workflow now separates system package preparation from R package installation
and writes durable logs for both.

## Caveats

This is still a personal workstation bootstrap repo, not a polished package
manager.

The historical `_pre_git_versions/` files are preserved for provenance. They
are not the active installer.
