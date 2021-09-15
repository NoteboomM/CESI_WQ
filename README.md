# CESI_WQ
Repository for NHS work on CESI for Water Quantity Indicators 2021 => ?

Initially I'm adding the files that Zhou Yang has refined; I have a separate repo for my tinkering.

Initial state is Zhou's versions as of 26/4/2021, uploaded here 4/5/2021. Next steps are integrating processing for flood and drought indicators.

Notes updated 15 September 2021, Matt Noteboom

As of September 2021 and final (?) data update for the 2022 water quantity indicator release, routines for 'new'
indicators have been reduced to a series of standalone functions ('Function_*.R') and the scripts that use those
and perform less repetitive calculations ('01*.R, '02*.R'). Following processing with R, there are two python scripts that run within
the QGIS interface (preferably V3.10, 3.16 returns odd results).


