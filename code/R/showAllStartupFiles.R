# Function to safely list files and show content if exists
show_startup_files <- function(directory, file_name) {
    file_path <- file.path(directory, file_name)
    if (file.exists(file_path)) {
        cat(sprintf("Contents of %s:\n", file_path))
        print(readLines(file_path), quote = FALSE)
    } else {
        cat(sprintf("No file named %s in %s\n", file_name, directory))
    }
}

# Using the function for .Rprofile and .Renviron in the home directory
home_dir <- path.expand("~")
show_startup_files(home_dir, ".Rprofile")
show_startup_files(home_dir, ".Renviron")

# Check the R home directory for Rprofile.site
r_home <- R.home()
show_startup_files(file.path(r_home, "etc"), "Rprofile.site")
