library(ggplot2)
library(gridExtra)
library(scales)
library(tidyr)
library(dplyr)


df <- read.table("varyXY.tsv", header = TRUE)
df$size <- df$size * df$size
p1 <- ggplot(df, aes(x = size, y = time, color = program)) +
  labs(tag = "A", title = "Varying both dimensions (N x N)") +
  geom_line(stat = "summary") +
  geom_errorbar(width = 0.2, stat = "summary") +
  geom_jitter(size = 0.5, position = position_jitter(width = 0.1, seed = 42)) +
  scale_x_continuous(breaks = scales::pretty_breaks(n = 10)) +
  ylab("Time to render MSA / seconds") +
  xlab("MSA size (total number of characters, C)")


df <- read.table("varyX.tsv", header = TRUE)
df$size <- df$x_size * df$y_size
p2 <- ggplot(df, aes(x = size, y = time, color = program)) +
  labs(tag = "B", title = "Varying number of columns (fixed 100 rows)") +
  geom_line(stat = "summary") +
  geom_errorbar(stat = "summary", aes(width = 20000)) +
  geom_jitter(size = 0.5, position = position_jitter(width = 0.1, seed = 42)) +
  scale_x_continuous(
    labels = function(x) paste0("N=", x)
  ) +
  ylab("Time to render MSA / seconds") +
  xlab("MSA size (total number of characters, C)")




df <- read.table("varyY.tsv", header = TRUE)
df$size <- df$x_size * df$y_size
p3 <- ggplot(df, aes(x = size, y = time, color = program)) +
  labs(tag = "C", title = "Varying number of rows (fixed 100 columns)") +
  geom_line(stat = "summary") +
  geom_errorbar(width = 0.2, stat = "summary") +
  geom_jitter(size = 0.5, position = position_jitter(width = 0.1, seed = 42)) +
  scale_x_continuous(
    labels = function(x) paste0("N=", x)
  ) +
  ylab("Time to render MSA / seconds") +
  xlab("MSA size (total number of characters, C)")


res <- grid.arrange(p1, p2, p3, nrow = 2)
ggsave("img/all.png", res, width = 14, height = 9)


# Timing breakdown visualization
if (file.exists("timings.tsv") && length(readLines("timings.tsv")) > 1) {
timings <- read.table("timings.tsv", header = TRUE)
timings$size <- timings$x_size * timings$y_size
timings$pageLoadTime <- timings$pageLoadTime / 1000
timings$fastaDownloadTime <- timings$fastaDownloadTime / 1000
timings$renderTime <- timings$renderTime / 1000

timings_summary <- timings %>%
  group_by(program, size) %>%
  summarise(
    pageLoadTime = mean(pageLoadTime),
    fastaDownloadTime = mean(fastaDownloadTime),
    renderTime = mean(renderTime),
    .groups = "drop"
  )

timings_long <- timings_summary %>%
  pivot_longer(
    cols = c(pageLoadTime, fastaDownloadTime, renderTime),
    names_to = "phase",
    values_to = "time"
  ) %>%
  mutate(phase = factor(phase, levels = c("renderTime", "fastaDownloadTime", "pageLoadTime")))

timings_long$size_label <- scales::comma(timings_long$size)
timings_long$size_label <- factor(timings_long$size_label, levels = unique(timings_long$size_label[order(timings_long$size)]))

p4 <- ggplot(timings_long, aes(x = size_label, y = time, fill = phase)) +
  geom_bar(stat = "identity", position = "stack") +
  facet_wrap(~program) +
  scale_fill_manual(
    values = c("pageLoadTime" = "#3498db", "fastaDownloadTime" = "#2ecc71", "renderTime" = "#e74c3c"),
    labels = c("pageLoadTime" = "Page Load", "fastaDownloadTime" = "FASTA Download", "renderTime" = "MSA Render")
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(
    x = "MSA size (total characters)",
    y = "Time (seconds)",
    fill = "Phase",
    title = "Time breakdown: Page Load vs FASTA Download vs MSA Rendering"
  )

ggsave("img/timing_breakdown.png", p4, width = 12, height = 8)


# MSA render time only (excluding page load and FASTA download)
render_only <- timings_summary %>%
  mutate(size_label = scales::comma(size)) %>%
  mutate(size_label = factor(size_label, levels = unique(size_label[order(size)])))

p5 <- ggplot(render_only, aes(x = size_label, y = renderTime, fill = program)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(
    x = "MSA size (total characters)",
    y = "Time (seconds)",
    fill = "Viewer",
    title = "MSA Render Time Only (excludes page load and FASTA download)"
  )

ggsave("img/render_time_only.png", p5, width = 12, height = 6)


# Line chart version of render time
p6 <- ggplot(timings_summary, aes(x = size, y = renderTime, color = program)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_log10(labels = scales::comma) +
  labs(
    x = "MSA size (total characters, log scale)",
    y = "Render time (seconds)",
    color = "Viewer",
    title = "MSA Render Time vs Size"
  )

ggsave("img/render_time_line.png", p6, width = 10, height = 6)


# Timing breakdown as line chart (shows scaling trends)
timings_line <- timings_summary %>%
  pivot_longer(
    cols = c(pageLoadTime, fastaDownloadTime, renderTime),
    names_to = "phase",
    values_to = "time"
  ) %>%
  mutate(phase = factor(phase,
    levels = c("pageLoadTime", "fastaDownloadTime", "renderTime"),
    labels = c("Page Load", "FASTA Download", "MSA Render")
  ))

p7 <- ggplot(timings_line, aes(x = size, y = time, color = program, linetype = phase)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_log10(labels = scales::comma) +
  labs(
    x = "MSA size (total characters, log scale)",
    y = "Time (seconds)",
    color = "Viewer",
    linetype = "Phase",
    title = "Time by Phase and Viewer"
  )

ggsave("img/timing_by_phase_line.png", p7, width = 12, height = 6)
}
