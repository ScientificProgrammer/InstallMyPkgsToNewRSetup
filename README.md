## [ScientificProgrammer/InstallMyPkgsToNewRSetup](https://github.com/ScientificProgrammer/InstallMyPkgsToNewRSetup)

### PURPOSE

The purpose of this repo is to maintain a script for automatically importing the latest
versions of the most common or critical packages I need whenever setting up a
new installation of R.

### BACKGROUND

Over the years, there are a number of R packages that I have found to be essential
for the work I do with R. On too many occasions, I have attempted to load a package
only to discover that I never installed it.

My goal in creating this repo is to maintain a script that I can pull easily
immediately after setting up a new R installation and have the script
automatically install my list of essential packages.

A number of solutions have been developed for R to help with managing packages. Examples
that come to mind are [rstudio/packrat](https://github.com/rstudio/packrat) and
[RevolutionAnalytics/checkpoint](https://github.com/RevolutionAnalytics/checkpoint).

R suffers from the same paradoxical challenge as many other successful
software projects: *package version management hell*. Giving users the ability
o create packages to extend the functionality of core software is critical
to adoption of the software. Furthermore, for a packaged extension to be useful
and widely adopted, its creators (or maintainers) must continually develop the
extension.

Here is where the paradox starts. On the one hand, a package undergoing rapid
development shows that its maintainers care about improving it. On the other hand,
that rapid evolution virtually guarantees that someone will have a conflict with
that package at some time.

The odds of that conflict occurring multiply rapidly as more packages become
dependent on other packages. Most of my frustration that arises when I
encounter a package conflict in R stems from this sort of a conflict. The
problem is even worse when the conflict originates within the `base R`

R is not unique in this regard. Other successful software platforms suffer from
the same problem. If you've ever written software in Python, you know
exactly what I mean.

Even just installing Python can be incredibly confusing to a beginner. All sorts
of questions arise.

1. Should I use *Conda* or *Anaconda*?

1. What are the differences between *Python 2* and *Python 3*?

1. Should I install a package into my standard Python environment, or
   should I install it into a virtual environment?
   
Despite these headaches, Python's popularity continues to grow, again, in large
part because of the paradox I mentioned earlier.

Another popular software project that springs to mind for this paradox
is *Node.js*. If you're not familiar with it, check out
this interesting story from *ARS Technica* titled, [Rage-quit: Coder unpublished 17 lines of JavaScript and “broke the Internet”](https://arstechnica.com/information-technology/2016/03/rage-quit-coder-unpublished-17-lines-of-javascript-and-broke-the-internet/),


The net summary of all that background information is that I created this
repo so that I'd have a structured place to maintain my relatively simple
R script that I use to install all of my desired R packages when I set
up a new installation of R.

The dream is that, after setting up a new R installation, I can run this
script while I go work on other things, since installing all of my
desired packages can literally take hours. The install time can be
especially long since I try to install the latest development versions,
as opposed to the CRAN approved versions.

The development versions will usually require downloading source code
from a Github repo, then compiling the package. Fortunately,
R's 'devtools' package makes this process fairly easy. If it encounters
a problem, it will halt the installation, reinstall the prior version
of the package (if it was already installed), and then warn the user.

I'd rather have this problem happen at a time of my choosing versus
in the hour before I have a deadline due.

### CAVEATS

#### WHY IS THIS SCRIPT SO CRUDE?
I created this script at least 4 years prior to the creation of this repo. Initially,
this script was stored on my Google Drive. I'd call it up whenever I needed it,
then make hacky edits.

If I was making small changes, I tended to comment out lines of code
as needed. At some point, I'd arbitrarily decide to save a new version
of the file, which is the reason for the files located in the `_pre_git_versions`
folder. Now, by using `git`, there will be no need for those files going further.


#### WHY DIDN'T YOU IMPLEMENT IT AS A PACKAGE?

SHORT ANSWER: Time.

