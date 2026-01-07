library(ggplot2)
library(gridExtra)
library(scales)

create_linear_models <- function(data, x_var = "size", y_var = "time", group_var = "program") {
  programs <- unique(data[[group_var]])
  models <- list()
  slopes <- numeric(length(programs))
  names(slopes) <- programs

  for (prog in programs) {
    subset_data <- data[data[[group_var]] == prog, ]
    formula <- as.formula(paste(y_var, "~", x_var))
    model <- lm(formula, data = subset_data)
    models[[prog]] <- model

    slope <- coef(model)[2]
    slopes[prog] <- slope / 1e-9
  }

  cat("\nSummary of slopes:\n")
  print(slopes)
}

df <- read.table("varyXY.tsv", header = TRUE)
print("varyXY")
create_linear_models(df)

df <- read.table("varyX.tsv", header = TRUE)
print("varyX")
create_linear_models(df)

df <- read.table("varyY.tsv", header = TRUE)
print("varyY")
create_linear_models(df)
