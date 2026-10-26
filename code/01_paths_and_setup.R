project_root <- if (file.exists("AEDS6400_blog3.Rproj")) {
  normalizePath(".", winslash = "/", mustWork = TRUE)
} else if (file.exists(file.path("..", "AEDS6400_blog3.Rproj"))) {
  normalizePath("..", winslash = "/", mustWork = TRUE)
} else {
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

data_dir <- file.path(project_root, "data")
figure_dir <- file.path(project_root, "figure")

if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
}
if (!dir.exists(figure_dir)) {
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
}
