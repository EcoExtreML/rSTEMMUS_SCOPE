## README
------------------------------------------------------------------------
## rSTEMMUS_SCOPE
Codes to run the STEMMUS_SCOPE model in MATLAB from R. Integrated code of SCOPE and STEMMUS. SCOPE is a radiative transfer and energy balance model (see https://github.com/AlbyDR/rSCOPE), and STEMMUS model is a two-phase mass and heat transfer model. For more information about the coupling between these two models, please check this [reference](https://gmd.copernicus.org/articles/14/1379/2021/). 

### To install rSTEMMUS_SCOPE, use:
``` r
devtools::install_github("EcoExtreML/rSTEMMUS_SCOPE")
library(rSTEMMUSSCOPE)
```
You may need to install the rhdf5 package before using BiocManager, as shown below.
``` r
install.packages("BiocManager")
BiocManager::install("rhdf5")
```
------------------------------------------------------------------------
#### Model Documentation

The documentation of the STEMMUS_SCOPE model can be found [here](https://ecoextreml.github.io/STEMMUS_SCOPE).

MATLAB R2015b or superior is required to run STEMMUS_SCOPE, and the MATLAB codes need to be downloaded and unzipped using the function ```initial_setup()```.

**directory structure**

After run ```initial_setup(patch = "D:/model/rSTEMMUS_SCOPE/")```, the following structure should be created.

```
D:/model/rSTEMMUS_SCOPE/
   - input/
     - directional/
     - fluspect_parameters/
     - leafangles/
     - radiationdata/
     - soil_spectrum/
     - files (template_config.txt, Mdata.txt, input_data.xls, forcing_globals.mat, soil_parameters.mat and soil_init.mat)
   - output/
      - AR-SLu_2024-01-25-0911 (output example)
   - runs/
      - file (path.txt)
      - AR-SLu_2024-01-25-0911 (input example)
   - src/
      - ... (MATLAB codes)
```

To check the installation by running the test dataset as below.

```
run_inMATLAB(patch = "D:/model/rSTEMMUS_SCOPE/",
             site_name = "AR-SLu",
             run_name = "2024-01-25-0911")
```             
note: change the patch according to the ```initial_setup()``` choice and include the patch in MATLAB ```"D:/model/rSTEMMUS_SCOPE/src/"```
             
------------------------------------------------------------------------
#### Steps to run the model for a time series at a specific location

After collecting and organising the data required to run the model (see input variables below), there will be four steps (functions) to run a time series simulation for a specific location.
[see here the steps](https://github.com/EcoExtreML/rSTEMMUS_SCOPE/blob/master/run_steps.md)

------------------------------------------------------------------------

**Main model outputs from the simulations**

| output file | variable                     |   unit    | observation         |
|:-------|:-----------------------------|:---------:|:--------------------|
| Sim_Theta | Soil Water Content (SWC) | [m3 m-3] | per depth (1 to 500 cm) |
| Sim_Temp  | Soil Temperature (Ts)    |   [°C]   | per depth (1 to 500 cm) |
| Sim_hh  | Soil Water Potential (SWP)    |   [cm]   | per depth (1 to 500 cm) |
| surftemp | Surface Temperature (LST)  |   [°C]   | soil skin and canopy |
| waterPotential | Leaf Water Potential (LWP)  |   [m]   |  |
| waterStreessFactor | Soil Water Stress (factor)  |   [-]   | from 0 to 1 |
| fluxes | Evapotranspiration (ET) | [W m-2] | divide by soil (Evap) and plant (Trap) |
| fluxes | Heat Fluxes (lE, H, G) | [W m-2] | divide by soil (s) and canopy (c) |
| fluxes | Net Ecosystem Carbon Exchange (NEE) | [Kg m-2 s-1] |  |
| fluxes | Vegetation Gross Primary Production (GPP) | [Kg m-2 s-1] |  |
| fluxes | other variables (A, Rn, Resp, aPAR) | [W m-2; umol m-2 s-1] |  |
| aerodyn | aerodynmic parameters (raa, rawc, raws, ustar, rac, ras) | [s m-1] |  |
| fluoreecence | Fluorecence | [W m-2 um-1 sr-1] | wavelengths 640 to 850 nm |
| reflectance | Fraction of Radiation (in observation direction *pi/irradiance) | [-] | from 400 to 2400 nm |

**Soil-Vegetation-Atmophere interactions**

![image](https://github.com/user-attachments/assets/74685153-ec0b-44e3-8e44-1a101485712f)


------------------------------------------------------------------------

**The required input data are divided into:**

```         
  1.1 Meteorological and vegetation properties time series inputs
  
  1.2 Site-specific characteristics

  1.3 Soil Initial Conditions
  
  1.4 Soil Properties

  1.5 Constants and model settings
```

------------------------------------------------------------------------
#### 1.1 Time Series inputs (vectors .dat)

| symbol | variable                     |   unit    | observation         |
|:-------|:-----------------------------|:---------:|:--------------------|
| rain\_ | Precipitation                | [cm s-1]  | 1 cm/s = 36000 mm/h |
| Ta\_   | Air Temperature              |   [°C]    |                     |
| RH\_   | Relative Humidity            |    [%]    | 0 \<= RH \<= 100    |
| p\_    | Atmospheric Pressure         |   [hPa]   |                     |
| u\_    | Wind speed                   |  [m s-1]  | u \>= 0.05          |
| CO2\_  | Carbon Dioxide Concentration | [mg m-3]  |                     |
| Rin\_  | Incoming Shortwave Radiation |  [W m-2]  |                     |
| Rli\_  | Incoming Longwave Radiation  |  [W m-2]  |                     |
| LAI\_  | Leaf Area Index              | [m2 m-2]  | LAI \>= 0.01        |
| ea\_   | Air Vapor Pressure           |   [hPa]   | eq-01               |
| VPD\_  | Vapor Pressure Deficit       |   [hPa]   | eq-02               |
| tts\_  | Zenith Solar Angle           |    [-]    |                     |
| t\_    | Timestamp (doy_float)        |    [-]    | decimal Julian day  |
| year\_ | Year                         | [integer] | Calendar year       |
| Cab\_  | Chlorophyll ab               | [ug cm-2] |                     |
| hc\_   | Canopy Height                |    [m]    | hc \>= 0.01         |

### $`ea = 6.107*10^{7.5 * Ta \choose 237.3 + Ta}* {RH\choose 100}`$            **(eq-01)** 

### $`VPD = 6.107*10^{7.5 * Ta \choose 237.3 + Ta}* 1 - {RH\choose 100}`$       **(eq-02)**

------------------------------------------------------------------------
#### 1.2 Site-specific characteristics

| symbol | variable | unit | observation |
|:---------------|:---------------------|:--------------:|:------------------|
| sitename | Name on the site | string | 2 chr - 3 chr (DE-C01) |
| Dur_tot | Number of timestamps | double |  |
| DELT | Timestep size in seconds | double | 60x30min or 60x60min hourly |
| latitude | Latitude (x) | degree |  |
| longitude | Longitude (y) | degree |  |
| elevation | Altitude (DEM) | [m] |  |
| reference_height | Measurement Height (z) | [m] |  |
| IGBP_veg_long | Long name IGBP vegetation class | string |  |
| canopy_height | Canopy Height (hc) | [m] |  |

------------------------------------------------------------------------
#### 1.3 Soil Initial Conditions (soil_init.mat)

| symbol | variable | unit | observation |
|:-----------|:-----------|:----------:|:------------------------------------|
| SWC | Initial soil water content | m3 m-3 | “volumetric soil water” layer 1 to 4 (swvl1, swvl2, swvl3, swvl4) |
| Ts | Initial soil temperature | °C | "Skin temperature” (skt) and “Soil temperature” level 1 to 4 (stl1, stl2, stl3, stl4) |

note: data from CDS ERA5 Land

------------------------------------------------------------------------
#### 1.4 Soil Properties (soil_parameters.mat)

| symbol | variable | unit | observation |
|:--------------|:-----------------|:-------------:|:----------------------|
| SaturatedK<sup>1</sup> | Saturated hydraulic conductivity | [cm s-1] | 1x6 [Ks]/(24\*3600) *cm d-1* |
| ks0<sup>1</sup> | First element of SaturatedK vector | [cm s-1] | 1x1 |
| porosity<sup>1</sup> | Porosity | [m3 m-3] | 1x6 [thetas] |
| theta_s0<sup>1</sup> | First element of porosity vector | [m3 m-3] | 1x1 |
| SaturatedMC<sup>1</sup> | Saturated SWC | [m3 m-3] | 1x6 [thetas] |
| ResidualMC<sup>1</sup> | Residual SWC | [m3 m-3] | 1x6 [thetar] |
| Coefficient_Alpha<sup>1</sup> | Coefficient Alpha | [cm-1] | 1x6 [alpha] |
| Coefficient_n<sup>1</sup> | Coefficient n | [-] | 1x6 [n] |
| fieldMC<sup>2</sup> | Field Capacity | [m3 m-3] | 6x1 |
| FOS<sup>3</sup> | Sandy Fraction | fraction (/100) | 6x1x1 [SAND1/2] |
| FOC<sup>3</sup> | Clay | fraction (/100) | 6x1x1 [CLAY1/2] |
| MSOC<sup>3</sup> | Organic Fraction (Carbon) | fraction (/10000) | 6x1x1 [OC1/2] |
| fmax |  | [-] | 1x1 surfdata |
| Coef_Lamda<sup>4</sup> | Lambda per depth | [-] | 6x1x1 Lambda folder |

<sup>[1]</sup> Derived from the **PTF_SoilGrids_Schaap** datasets (*n, alpha, Ks, thetas, thetar) from the valid depths: 0, 5, 15, 30, 60, 100 and 200 cm (sl1* to sl7), excluding *sl3 (15cm).*

<sup>[2]</sup> Calculated field capacity form field moisture content\
#### $`fieldMC = theta_r + (theta_s - theta_r) / (1 + (alpha*phi_fc)^{coef_n})^{(1 - (1 / coef_n))}`$            **(eq-03)** 

*where phifc = 341.9 - soil water potential at field capacity (cm)*

<sup>3</sup> Both layers (1, 2) are combined, and the values from depths 1,3,5,6,7,8 are used per variable

<sup>4</sup> Only the Lambda file layers l1, l3, l5, l6, l7, l8 (depth_indices) were combined and used

### To download global maps to extract the above variables run the follow code:

```
# the file is 24GB, so you may need more time ...
# download, unzip in the folder ../input/SoilProperty/ using ...                       
download_SoilProperty("D:/model/rSTEMMUS_SCOPE/", timeout = 1000)   

# extract to your location using the argument latitude and longitude (+proj=longlat +datum=WGS8)
Soil_property_loc1 <- get_SoilProperties(patch = "D:/model/rSTEMMUS_SCOPE/input/SoilProperty/",
                                         lon = 107.688,
                                         lat = 37.829)
```

##### note: you can also download manually from https://zenodo.org/api/records/15488066/files/SoilProperty.zip/content, then unzip and place it in "D:/model/rSTEMMUS_SCOPE/input/" or inside the "input" folder in your patch choice
------------------------------------------------------------------------
#### 1.5 Constants and model settings
Use functions of the family "info", "check" and "change" to get more information about which constant (model parameters) and model settings from STEMMUS and SCOPE can be changed to calibrate the model for the site characteristics.
