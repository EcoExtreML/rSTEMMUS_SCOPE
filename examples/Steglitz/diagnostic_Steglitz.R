# ========================================================
# diagnostic.R - 
# Observed vs simulated soil moisture comparison
# ========================================================

# ==================== USER CONFIGURATION ====================

# Path to the STEMMUS-SCOPE simulation output folder.
# This folder must contain the file:
#   Sim_Theta.csv
#
# Example:
# output/DE-STG_Test3_Steglitz_2025Jul23_1548
#
# Change this path to your own simulation output directory.



obs_data_file <- "D:/data_Steglitz/11_07_2025/EC_DWD_ROTH_clean.rds"

# Path to the observed soil moisture dataset.
#
# The file should contain:
# - a timestamp column named: timestamp
# - soil moisture columns such as:
#     SMC_5cm
#     SMC_10cm
#     SMC_20cm
#     SMC_30cm
#     SMC_60cm
#     SMC_1m
#
# Soil moisture values are expected in percentage (%).
#
# Change this path to your own observation dataset.



target_depth <- 60

# Target soil depth (cm) used for the comparison.
#
# In this Steglitz example, we compare:
# - observed soil moisture at 60 cm
# - simulated soil moisture at the corresponding 60 cm model layer
#
# Users can change this value to evaluate another soil depth.



obs_column <- "SMC_60cm"

# Observed soil moisture column corresponding to the selected depth.
#
# Examples:
# "SMC_5cm"
# "SMC_10cm"
# "SMC_30cm"
# "SMC_60cm"
# "SMC_1m"
#
# Change this variable if you want to compare another observed depth.



sim_column <- "depth_60_5"

# Simulated soil moisture column corresponding to the selected depth.
#
# The simulated columns are generated automatically from:
# - depth center
# - layer thickness
#
# Example:
# depth_60_5
# means:
# - depth centered at 60 cm
# - layer thickness = 5 cm
#
# Change this variable to compare another simulated soil layer.



simulation_start_time <- "2019-01-01 00:00:00"

# Start timestamp of the STEMMUS-SCOPE simulation.
# Used to reconstruct the simulation time series.

# ============================================================


# ==================== LOAD PACKAGES ====================

library(tidyverse)
library(lubridate)
library(hydroGOF)

cat("=== Diagnostic Started ===\n")


# ==================== 1. LOAD SIMULATION ====================

sim_path <- file.path(sim_folder, "Sim_Theta.csv")

sim_df <- read_csv(
  sim_path,
  skip = 3,
  col_names = FALSE,
  show_col_types = FALSE
)

depth_theta <- c(
  1, 2, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25,
  27.5, 30, 32.5, 35, 40, 45, 50, 55, 60,
  70, 80, 90, 100, 110, 120, 130, 140, 150, 160,
  170, 180, 190, 200, 210, 220, 230, 245, 260,
  280, 300, 320, 340, 360, 380, 400, 420, 440,
  460, 480, 500
)

depth_layer <- c(
  1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  2, 2.5, 2.5, 2.5, 2.5, 5, 5, 5, 5, 5,
  10, 10, 10, 10, 10, 10, 10, 10,
  10, 10, 10, 10, 10, 10, 10, 10, 10,
  15, 15, 20, 20, 20, 20, 20, 20,
  20, 20, 20, 20, 20, 20
)

names(sim_df) <- paste0("depth_", depth_theta, "_", depth_layer)

sim_df <- sim_df %>%
  mutate(
    timestamp = seq(
      as.POSIXct(simulation_start_time, tz = "UTC"),
      by = "hour",
      length.out = n()
    )
  )


# ==================== 2. CHECK SELECTED COLUMNS ====================

if (!obs_column %in% names(readRDS(obs_data_file))) {
  stop(paste("Observed column not found:", obs_column))
}

if (!sim_column %in% names(sim_df)) {
  stop(paste("Simulated column not found:", sim_column))
}


# ==================== 3. LOAD OBSERVED DATA ====================

steg_df <- readRDS(obs_data_file)

obs_df <- steg_df %>%
  mutate(timestamp = as.POSIXct(timestamp, tz = "UTC")) %>%
  select(timestamp, all_of(obs_column)) %>%
  rename(Observed = all_of(obs_column)) %>%
  mutate(Observed = Observed / 100)


# ==================== 4. MERGE OBSERVED AND SIMULATED ====================

combined_df <- inner_join(obs_df, sim_df, by = "timestamp")


# ==================== 5. EXTRACT SIMULATED DEPTH ====================

combined_df <- combined_df %>%
  mutate(
    Simulated = .data[[sim_column]],
    Simulated = pmax(Simulated, 0.05)
  )

cat("✓ Data merged and selected depth extracted\n")
cat("Observed column:", obs_column, "\n")
cat("Simulated column:", sim_column, "\n")


# ==================== 6. PLOT ====================

p <- ggplot(combined_df, aes(x = timestamp)) +
  geom_line(aes(y = Observed, color = "Observed"), linewidth = 1.1) +
  geom_line(aes(y = Simulated, color = "Simulated"), linewidth = 1.0) +
  scale_color_manual(values = c("Observed" = "black", "Simulated" = "blue")) +
  labs(
    title = paste0("Observed vs Simulated Soil Moisture at ", target_depth, " cm"),
    subtitle = basename(sim_folder),
    x = "Date",
    y = "Volumetric Soil Moisture [m³/m³]",
    color = "Legend"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "top")

print(p)


# ==================== 7. SAVE PLOT ====================

plot_file <- file.path(
  sim_folder,
  paste0("SM_", target_depth, "cm_comparison.png")
)

ggsave(
  plot_file,
  plot = p,
  width = 11,
  height = 6.5,
  dpi = 300
)

cat("✓ Plot saved:", plot_file, "\n")


# ==================== 8. MODEL PERFORMANCE ====================

KGE_result <- hydroGOF::KGE(
  sim = combined_df$Simulated,
  obs = combined_df$Observed,
  out.type = "full"
)

print(KGE_result)

cat("=== Diagnostic Finished ===\n")