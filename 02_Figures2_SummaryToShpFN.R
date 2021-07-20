
# # function to set up a data frame with station, coords, selected metric and output to
# # a shapefile for GIS.

summary.to.shp <- function(summary.data, metric, path.shp){
  
  library(sp)

  var2 <- metric

  print(var2)
  
  metricdata <- left_join(stn_data,summary.data,by="STATION_NUMBER")
  
  # print(paste("stn_xy:",nrow(stn_xy), "metricdata:", nrow(metricdata)))
  
  metricplot <- SpatialPointsDataFrame(coords = stn_xy, data = metricdata,
                                     proj4string = crs_wgs)
  metricplot <- spTransform(metricplot, CRSobj = crs)
  
  outstring <- paste0(path.shp, "/RHBN_U_pts_", metric, "_Hydat_", version, ".shp")

  if (!file.exists(outstring)){
    writeOGR(metricplot, outstring,
             layer=basename(outstring),
             driver="ESRI Shapefile")
  }
}
