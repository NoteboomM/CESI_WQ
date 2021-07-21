
# function to set up a data frame with station, coords, selected metric and output to
# a shapefile for GIS.

# Inputs:
# metric.data - data frame of data to be output to shp; must include 'STATION_NUMBER'
# metric - string of metric to be output for file naming
# path.shp - relative path from working dir to shapefile location

summary.to.shp <- function(metric.data, metric, path.shp){
  
  library(sp)
  library(rgdal)
  library(tidyhydat)
  
  var2 <- metric

  print(var2)
  
  station.list <- as.character(metric.data$STATION_NUMBER)
  
  CanadaBound <- readOGR(dsn = "../Dependencies", "CanadaBound")
  crs <- CanadaBound@proj4string
  crs_wgs  <- CRS( "+init=epsg:4326")
  stn_data <- as.data.frame(hy_stations() %>% dplyr::select(STATION_NUMBER, LATITUDE, LONGITUDE))
  stn_data <- stn_data[stn_data$STATION_NUMBER %in% station.list,]
  stn_xy   <- stn_data[,c("LONGITUDE", "LATITUDE")]
  
  metricdata <- left_join(stn_data,metric.data,by="STATION_NUMBER")
  
  # print(paste("stn_xy:",nrow(stn_xy), "metricdata:", nrow(metricdata)))
  
  metricplot <- SpatialPointsDataFrame(coords = stn_xy, data = metricdata,
                                     proj4string = crs_wgs)
  metricplot <- spTransform(metricplot, CRSobj = crs)
  
  outstring <- paste0(path.shp, "/RHBN_U_pts_", metric, "_Hydat_", version, ".shp")

  if (!file.exists(outstring)){
    rgdal::writeOGR(metricplot, outstring,
             layer=basename(outstring),
             driver="ESRI Shapefile")
  }
}
