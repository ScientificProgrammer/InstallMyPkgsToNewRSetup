# Setting up on Windows or Linux - Read this before you begin.

# Running `InstallMyRPkgsToNewRSetup` on Linux Ubuntu 22.04 LTS

At various points throughout the script, I had to install a
the following packages from the command line in order
for the code to run.

```bash
sudo apt install -y unixodbc-dev
sudo apt install -y libmysqlclient-dev
sudo apt install -y libpq-dev
sudo apt install -y libgit2-dev 
sudo apt install -y libarchive-dev 
sudo apt install -y libsodium-dev
sudo apt install -y libglpk-dev
sudo apt install -y libudunits2-dev
sudo apt install -y libmagick++-dev
sudo apt install -y libnode-dev
sudo apt install -y cargo                 # gifski
sudo apt install -y libgl1-mesa-dev       # rgl   
sudo apt install -y libglu1-mesa-dev      # rgl   
sudo apt install -y rustc                 # gifski
sudo apt install -y gdal-bin              # sf
sudo apt install -y libgdal-dev           # sf
sudo apt install -y libgeos-dev           # sf
sudo apt install -y libproj-dev           # sf
sudo apt install -y libsqlite3-dev        # sf
sudo apt install -y libpoppler-cpp-dev    # pdftools
sudo apt install -y libavfilter-dev       # gganimate
```


## Difficulty Installing `Hmisc` &lpar;and many other packages&rpar;
When I had a hard time installing `Hmisc`, I received
warnings about all of the following packages. Therefore,
I attempted to explicitly install them.

```R
pak::pkg_install(
   c(
      "RcppEigen",
      "deldir",
      "ucminf",
      "nloptr",
      "minqa",
      "pan",
      "mvtnorm",
      "SparseM",
      "polspline",
      "Hmisc",
      "leaps",
      "VGAM",
      "acepack",
      "ordinal",
      "lme4",
      "quantreg",
      "interp",
      "pcaPP",
      "jomo",
      "multcomp",
      "glmnet",
      "latticeExtra",
      "mitml",
      "rms",
      "mice",
      "qreport"
   )
)
```

With some help from ChatGPT, I figured out that many of the R packages
that I kept trying to build and that would fail with a Fortran
error were due to a problem with `/usr/bin/ld` being unable to find
the correct `libgfortran.so` file.

ChatGPT recommended two suggestions to fix the problem.

1. Update the `LD_LIBRARY_PATH` env variable as shown here.

   `export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH`

2. Create a new symbolic link, as shown below.

```
sudo ln -s /usr/lib/gcc/x86_64-linux-gnu/11/libgfortran.so /usr/lib/libgfortran.so
```

Before trying either solution, I noticed that `$LD_LIBRARY_PATH` was null.
Therefore, I didn't make any changes to it. However, after creating the
symbolic link, I was able to compile and install all of my R packages
using the `pak` package's `pkg_install()` command.

Prior to then, I tried for more than 7 hours to get my packages compiled,
but the installation would fail. After creating the symbolic link, there
were no additional failures when running my package install script.

Note that some packages, such as `Hmisc`, `leaflet`, and `RDiagrammeR`
required at least 5 minutes to build on my Linux Ubuntu laptop, which was
a Dell Precision 8660 with 32 GB of RAM.
