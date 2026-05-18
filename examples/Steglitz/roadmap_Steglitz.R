
# roadmap_steglitz.R — Reusable script to set up and run rSTEMMUS-SCOPE for a site
# Purpose: Prepare inputs, configure, and run STEMMUS-SCOPE for a given site/time period

# --- 1. User Configuration (CHANGE THESE ONLY) ---
site_name       <- "DE-STG"              # Site code (e.g., DE-STG for Steglitz)
start_time      <- "2019-01-01T00:00"    # Format: YYYY-MM-DDTHH:MM
end_time        <- "2020-12-31T23:00"    # Format: YYYY-MM-DDTHH:MM
latitude        <- 52.45723              # Site latitude
longitude       <- 13.31583              # Site longitude
elevation       <- 50                    # Approximate elevation (m)
canopy_height   <- 5                     # Mean canopy height (m)
igbp_class      <- "Closed Shrublands"   # IGBP vegetation class

# Default experiment settings
# These values are used only if they were not defined by a run_*.R launcher script
if (!exists("run_name")) {
  run_name <- "Steglitz_default"
}

if (!exists("porosity_adjust")) {
  porosity_adjust <- 0
}

# Data paths (relative or absolute — change if needed)
data_file       <- "EC_DWD_ROTH_clean.rds"          # Your cleaned EC + soil data RDS
patch_path      <- "D:/model/rSTEMMUS_SCOPE/"       # Base path to rSTEMMUS-SCOPE installation

# --- 2. Load libraries ---
library(rSTEMMUSSCOPE)
library(tidyverse)
library(lubridate)
library(here)  # Optional: install if needed (devtools::install_github("r-lib/here"))

# --- 3. Initialize package & directories ---
initial_setup(patch = patch_path)
cat("Package initialized at:", patch_path, "\n")

# Create new run directory
new_run(
  patch      = patch_path,
  StartTime  = start_time,
  EndTime    = end_time,
  site_name  = site_name,
  run_name   = run_name,
  output_name = format(Sys.time(), "%Y%m%d_%H%M")
)
cat("New run directory created:", file.path(patch_path, "runs", paste0(site_name, "_", run_name)), "\n")

# --- 4. Load and prepare observational data ---
steg_df <- readRDS(data_file)
cat("Loaded data from:", data_file, "\n")

# Compute decimal day of year (t_)
steg_df <- steg_df %>%
  mutate(
    timestamp = as.POSIXct(timestamp, tz = "UTC"),
    t_ = yday(timestamp) + hour(timestamp)/24 + minute(timestamp)/(24*60)
  ) %>%
  filter(timestamp >= as.POSIXct(start_time) & timestamp <= as.POSIXct(end_time))

# Create time-series tibble for input_timeseries()
ts_input <- tibble(
  t_       = steg_df$t_,
  timestamp = steg_df$timestamp,
  Rin_sun  = as.numeric(steg_df$Rin),
  Rli_     = as.numeric(steg_df$Rli),
  p_       = as.numeric(steg_df$p),
  Ta_      = as.numeric(steg_df$Ta),
  RH_      = as.numeric(steg_df$RH),
  u_       = as.numeric(steg_df$ws),
  rain_    = as.numeric(steg_df$prec_mm) / 36000,  # mm/h → cm/s
  LAI_     = as.numeric(steg_df$LAI_FP),
  co2      = 415  # constant fallback; replace with data if available
)

# Improved VPD calculation (in hPa)
ts_input <- ts_input %>%
  mutate(
    es    = 6.107 * 10^((7.5 * Ta_) / (237.3 + Ta_)),
    VPD_  = es * (1 - RH_ / 100),
    ea_   = es * (RH_ / 100)
  )

# Quick integrity check
cat("Time-series input summary:\n")
summary(ts_input)

# --- 5. Load and adjust soil properties ---
Soil_property <- get_SoilProperties(
  patch = file.path(patch_path, "input/SoilProperty/"),
  lon   = longitude,
  lat   = latitude
)

# Apply porosity adjustment (if > 0)
if (porosity_adjust > 0) {
  cat("Applying porosity adjustment of +", porosity_adjust, "to layers 4–6\n")
  Soil_property$porosity[4:6] <- Soil_property$porosity[4:6] + porosity_adjust
}

# --- 6. Set initial conditions from first data row ---
init_row <- steg_df[1, ]
initial_soil_temp <- data.frame(
  skt  = init_row$soil_temp10cm,
  stl1 = init_row$soil_temp10cm,
  stl2 = init_row$soil_temp20cm,
  stl3 = init_row$soil_temp30cm,
  stl4 = init_row$soil_temp50cm
)
initial_soil_water <- data.frame(
  swvl1 = init_row$SMC_10cm,
  swvl2 = init_row$SMC_20cm,
  swvl3 = init_row$SMC_30cm,
  swvl4 = init_row$SMC_60cm
)

# --- 7. Configure static inputs ---
input_constants(
  patch      = patch_path,
  site_name  = site_name,
  run_name   = run_name,
  LAT        = latitude,
  LON        = longitude,
  elevation  = elevation,
  IGBP_veg_long = igbp_class,
  hc         = canopy_height,
  n_timestamps = nrow(ts_input),
  timestep_min = 60,
  initial_soil_temperature = initial_soil_temp,
  initial_volumetric_soil_water = initial_soil_water,
  soil_property_list = Soil_property,
  startDOY   = 1,
  endDOY     = 365,
  timezn     = 1,
  setoptions = c(1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1)
)
cat("Static constants and initial conditions set.\n")

# --- 8. Set time-series inputs ---
input_timeseries(
  patch      = patch_path,
  site_name  = site_name,
  run_name   = run_name,
  t_file     = ts_input$t_,
  year_file  = year(ts_input$timestamp),
  Rin_file   = ts_input$Rin_sun,
  Rli_file   = ts_input$Rli_,
  p_file     = ts_input$p_,
  Ta_file    = ts_input$Ta_,
  RH_file    = ts_input$RH_,
  ea_file    = ts_input$ea_,
  VPD_file   = ts_input$VPD_,
  u_file     = ts_input$u_,
  rain_file  = ts_input$rain_,
  LAI_file   = ts_input$LAI_,
  CO2_file   = ts_input$co2
)
cat("Time-series inputs set.\n")

# --- 9. Run the model ---
cat("Starting simulation...\n")
run_inMATLAB(
  patch     = patch_path,
  site_name = site_name,
  run_name  = run_name
)
cat("Simulation complete. Results saved to output/ folder.\n")

# Optional: Open output folder
shell.exec(file.path(patch_path, "output"))