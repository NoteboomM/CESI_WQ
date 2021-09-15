# CESI_WQ
Repository for NHS work on CESI for Water Quantity Indicators 2021 => ?

Initially I'm adding the files that Zhou Yang has refined; I have a separate repo for my tinkering.

Initial state is Zhou Yang's versions as of 26/4/2021, uploaded here 4/5/2021. Next steps are integrating
processing for flood and drought indicators.

## Notes updated 15 September 2021, Matt Noteboom (matthew.noteboom@ec.gc.ca)

Dependencies not included in this repository (and not calculated/downloaded by scripts):
Folder 
  ..\/Dependencies
  ..\/Variables
Files
  \/Dependencies\/RHBN_NandU_watershedareas.csv
  \/Dependencies\/RHBN_U.csv

As of September 2021 and final (?) data update for the 2022 water quantity indicator release, routines 
for 'new' indicators have been reduced to a series of standalone functions ('Function\_*.R') and the 
scripts that use those and perform less repetitive calculations ('01?\_\*.R', '02\_\*.R'). Following 
processing with R, there are two python scripts ('IDW\_\*.py) that run within the QGIS interface
(preferably V3.10, 3.16 returns odd results) to generate and clip the raster images for maps.

'01\_Variables...R' calls the two 01a scripts as well as 'Function\_chk\_hydat.R' to load dependencies
including hydat if present or download hydat if not, then calculate various flow metrics for all stations
stored in hydat for all years data is valid. If variable files already exist, script clips last 10 lines
and recalculates to last year in the database (for time saving). To recalculate all metrics and all years,
remove files in ..\/Variables.

02\_Summarise...R calls 'Function\_chk\_hydat.R' function as well as 'Function\_SummaryToShp.R' to load
Variables files, extract Annual Mean Yield for each year, then output values for 2001-2019 and their
percentile ranks compared to the 1981-2010 range to a summary CSV and a shapefile for mapping.

02\_Trends_Main.R calculates trends using selections from the three test functions:
  Function\_HurdleTest.R - 'hurdle' test to handle excess zeroes
  Function\_MKTest.R - Mann-Kendall test for data with few zeroes\/ties (most years' Annual Mean Yield)
  Function\_NegBinTest.R - Negative Binomial test for data with few zeroes, but excess ties for MK




