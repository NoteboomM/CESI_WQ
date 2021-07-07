
# # function to set up a data frame with station, coords, selected metric and output to
# # a shapefile for GIS.

summary.to.shp <- function(summary.data, metric, path.shp){

  var2 <- metric

  print(var2)
  
  metricdata <- left_join(stn_data,Ind.2016.r,by="STATION_NUMBER")
  metricdata <- metricdata[metricdata$variable == var2,]
  metricplot <- SpatialPointsDataFrame(coords = stn_xy, data = metricdata,
                                     proj4string = crs_wgs)
  metricplot <- sp::spTransform(metricplot, CRSobj = crs)
  
  outstring <- paste0(path.shp, "/RHBN_U_pts_", metric, "_Hydat_", version, ".shp")

  if (!file.exists(outstring)){
    writeOGR(metricplot, outstring,
             layer=basename(outstring),
             driver="ESRI Shapefile")
  }
}
