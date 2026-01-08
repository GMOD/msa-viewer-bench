library(ggplot2)
library(gridExtra)
library(scales)
library(tidyr)
library(dplyr)


df <- read.table("varyXY.tsv", header = TRUE)
p1 <- ggplot(df, aes(x = size, y = time, color = program)) +
  geom_line(stat = "summary") +
  geom_errorbar(width = 0.2, stat = "summary") +
  geom_jitter(size = 0.5, position = position_jitter(width = 0.1, seed = 42)) +
  scale_x_continuous(labels = scales::comma) +
  labs(
    tag = "A",
    title = "Varying both dimensions (N x N)",
    x = "MSA size (total characters)",
    y = "Time (seconds)",
    color = "Viewer"
  )


df <- read.table("varyX.tsv", header = TRUE)
p2 <- ggplot(df, aes(x = size, y = time, color = program)) +
  geom_line(stat = "summary") +
  geom_errorbar(stat = "summary", aes(width = 20000)) +
  geom_jitter(size = 0.5, position = position_jitter(width = 0.1, seed = 42)) +
  scale_x_continuous(labels = scales::comma) +
  labs(
    tag = "B",
    title = "Varying columns (fixed 100 rows)",
    x = "MSA size (total characters)",
    y = "Time (seconds)",
    color = "Viewer"
  )


df <- read.table("varyY.tsv", header = TRUE)
p3 <- ggplot(df, aes(x = size, y = time, color = program)) +
  geom_line(stat = "summary") +
  geom_errorbar(width = 0.2, stat = "summary") +
  geom_jitter(size = 0.5, position = position_jitter(width = 0.1, seed = 42)) +
  scale_x_continuous(labels = scales::comma) +
  labs(
    tag = "C",
    title = "Varying rows (fixed 100 columns)",
    x = "MSA size (total characters)",
    y = "Time (seconds)",
    color = "Viewer"
  )


res <- grid.arrange(p1, p2, p3, nrow = 2)
ggsave("img/all.png", res, width = 14, height = 9)


# Timing breakdown visualization
if (file.exists("timings.tsv") && length(readLines("timings.tsv")) > 1) {
timings <- read.table("timings.tsv", header = TRUE)
timings$size <- timings$x_size * timings$y_size
timings$pageLoadTime <- timings$pageLoadTime / 1000
timings$fastaDownloadTime <- timings$fastaDownloadTime / 1000
timings$renderTime <- timings$renderTime / 1000

# Split into three categories
timings_varyXY <- timings %>% filter(x_size == y_size)
timings_varyX <- timings %>% filter(x_size == 100 & y_size != 100)
timings_varyY <- timings %>% filter(y_size == 100 & x_size != 100)

# Helper function to create timing summary
create_timing_summary <- function(data) {
  data %>%
    group_by(program, size, x_size, y_size) %>%
    summarise(
      pageLoadTime = mean(pageLoadTime),
      fastaDownloadTime = mean(fastaDownloadTime),
      renderTime = mean(renderTime),
      .groups = "drop"
    )
}

summary_varyXY <- create_timing_summary(timings_varyXY)
summary_varyX <- create_timing_summary(timings_varyX)
summary_varyY <- create_timing_summary(timings_varyY)

# Helper function for timing breakdown line plot
create_breakdown_plot <- function(data, title_text, tag_text) {
  timings_long <- data %>%
    pivot_longer(
      cols = c(pageLoadTime, fastaDownloadTime, renderTime),
      names_to = "phase",
      values_to = "time"
    ) %>%
    mutate(phase = factor(phase,
      levels = c("pageLoadTime", "fastaDownloadTime", "renderTime"),
      labels = c("Page Load", "FASTA Download", "MSA Render")
    ))

  ggplot(timings_long, aes(x = size, y = time, color = program)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    facet_wrap(~phase, nrow = 1) +
    scale_x_continuous(labels = scales::comma) +
    labs(
      tag = tag_text,
      x = "MSA size (total characters)",
      y = "Time (seconds)",
      color = "Viewer",
      title = title_text
    )
}

p4a <- create_breakdown_plot(summary_varyXY, "Varying both dimensions (N x N)", "A")
p4b <- create_breakdown_plot(summary_varyX, "Varying columns (fixed 100 rows)", "B")
p4c <- create_breakdown_plot(summary_varyY, "Varying rows (fixed 100 columns)", "C")

res_breakdown <- grid.arrange(p4a, p4b, p4c, nrow = 2)
ggsave("img/timing_breakdown.png", res_breakdown, width = 18, height = 9)


# MSA render time only (excluding page load and FASTA download)
create_render_only_plot <- function(data, title_text, tag_text) {
  ggplot(data, aes(x = size, y = renderTime, color = program)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    scale_x_continuous(labels = scales::comma) +
    labs(
      tag = tag_text,
      x = "MSA size (total characters)",
      y = "Time (seconds)",
      color = "Viewer",
      title = title_text
    )
}

p5a <- create_render_only_plot(summary_varyXY, "Varying both dimensions (N x N)", "A")
p5b <- create_render_only_plot(summary_varyX, "Varying columns (fixed 100 rows)", "B")
p5c <- create_render_only_plot(summary_varyY, "Varying rows (fixed 100 columns)", "C")

res_render_only <- grid.arrange(p5a, p5b, p5c, nrow = 2)
ggsave("img/render_time_only.png", res_render_only, width = 14, height = 9)


# Line chart version of render time
create_render_line_plot <- function(data, title_text, tag_text) {
  ggplot(data, aes(x = size, y = renderTime, color = program)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    scale_x_continuous(labels = scales::comma) +
    labs(
      tag = tag_text,
      x = "MSA size (total characters)",
      y = "Time (seconds)",
      color = "Viewer",
      title = title_text
    )
}

p6a <- create_render_line_plot(summary_varyXY, "Varying both dimensions (N x N)", "A")
p6b <- create_render_line_plot(summary_varyX, "Varying columns (fixed 100 rows)", "B")
p6c <- create_render_line_plot(summary_varyY, "Varying rows (fixed 100 columns)", "C")

res_render_line <- grid.arrange(p6a, p6b, p6c, nrow = 2)
ggsave("img/render_time_line.png", res_render_line, width = 14, height = 9)


# Timing breakdown as line chart (shows scaling trends)
create_phase_line_plot <- function(data, title_text, tag_text) {
  timings_line <- data %>%
    pivot_longer(
      cols = c(pageLoadTime, fastaDownloadTime, renderTime),
      names_to = "phase",
      values_to = "time"
    ) %>%
    mutate(phase = factor(phase,
      levels = c("pageLoadTime", "fastaDownloadTime", "renderTime"),
      labels = c("Page Load", "FASTA Download", "MSA Render")
    ))

  ggplot(timings_line, aes(x = size, y = time, color = program, linetype = phase)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    scale_x_continuous(labels = scales::comma) +
    labs(
      tag = tag_text,
      x = "MSA size (total characters)",
      y = "Time (seconds)",
      color = "Viewer",
      linetype = "Phase",
      title = title_text
    )
}

p7a <- create_phase_line_plot(summary_varyXY, "Varying both dimensions (N x N)", "A")
p7b <- create_phase_line_plot(summary_varyX, "Varying columns (fixed 100 rows)", "B")
p7c <- create_phase_line_plot(summary_varyY, "Varying rows (fixed 100 columns)", "C")

res_phase_line <- grid.arrange(p7a, p7b, p7c, nrow = 2)
ggsave("img/timing_by_phase_line.png", res_phase_line, width = 14, height = 9)
}
