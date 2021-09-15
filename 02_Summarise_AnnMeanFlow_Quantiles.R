###################################################################################################
# CESI project part 8-Creating Summary Tables
###################################################################################################


###########      Library             ###########
library(dplyr)     # For data tidying and data tables     
library(tidyr)     # For data tidying
library(zyp)       # For applying trend tests
source('Function_SummaryToShp.R')  # Sourcing function for shapefile output
source('Function_chk_hydat.R')

#########  Function:percentile.ranked  #########
# percentile.ranked find the percentile rank of reference year compared to 
# reference period (1981-2010)
# precentile.ranked: (vectorof numeric) numeric -> numeric
percentile.ranked <- function(a.vector, value) {
  numerator <- length(sort(a.vector)[a.vector < value]) 
  denominator <- length(a.vector)
  round(numerator/denominator,2)*100 
}

chk.hydat("../Dependencies/Hydat")

stations <- read.csv("../Dependencies/RHBN_U.csv", header = TRUE)
stn.list.full <- as.character(stations$STATION_NUMBER)
ref.range <- c(2001:2019)

##### Creating Summary tables for Metrics  #####
# for each station, extract the metric in question, then alter by watershed area if needed
if (file.exists(paste0("../Variables/Summary.AnnMeanYield.csv"))){
  results.all <- read.csv(paste0("../Variables/Summary.AnnMeanYield.csv"), header = TRUE)
} else {
  snap <- list()
  for (k in 1:length(stn.list.full)){
    var.name <- "Annual Mean Yield"
    var.t <- "ann_mean_yield"
    
    stn <- stn.list.full[k]
    print(stn)
    # load data
    data <- read.csv(paste0("../Variables/", stn, ".csv"), header = TRUE)
    data$station <- as.character(data$station)
    # extract variable of interest
    q <- data.frame(matrix(ncol=5, nrow=1, 
                           dimnames= list(NULL, c("STATION_NUMBER","variable","q25", "q75", "median"))))
    q$STATION_NUMBER <- stn
    q$variable <- var.t
    # if variable needs it, scale variable by watershed size. Units will now be in mm/time,
    # where time is either one year, 7 days, or one day.

    watershed <- stations[stations$STATION_NUMBER == stn, "Shp_Area"]
    time <-  365*24*3600
    
    data[[var.t]] <- data[[var.t]]*time/(watershed*10^3) 

    # calculate quantiles, ranks, trends for each variable
    data.ref <- data %>% filter(year>=1981, year<=2010)

    # calculate the 25th and 75th percentile for the 1981-2010 period,
    # provided there are at least 20 years of data within that period.
    if (sum(!is.na(data.ref[[var.t]]))>=20){
      q.var <- quantile(data.ref[[var.t]], c(0.25, 0.75), na.rm=TRUE)
      median <- median(data[[var.t]], na.rm=TRUE)
    } else {
      q.var <- c(NA, NA)
      median <- NA
    }
    q[q$variable==var.t, c("q25", "q75")] <- q.var
    q[q$variable==var.t, "median"] <- median
    
    results <- list()
    ranks <- list()
    
    for (refyear in ref.range){
      if (refyear %in% data$year){
        latest <- data[data$year == refyear, var.t]
        print(refyear)
      } else {
        latest <- NA
      }
      q[q$variable==var.t, paste0("res.", refyear)] <- latest # abbreviated names for shp export
    }
    for (refyear in ref.range){
      if (refyear %in% data$year){
        latest <- data[data$year == refyear, var.t]
      } else {
        latest <- NA
      }
      if (!is.na(latest) & !is.na(median)){
        q[q$variable==var.t, paste0("rk.", refyear)] <- as.integer(percentile.ranked(data.ref[[var.t]], latest))
      } else {
        q[q$variable==var.t, paste0("rk.", refyear)] <- NA # abbreviated names for shp export
      }
    }
    
    
  
    snap[[k]] <- q
  }
  # Combine stations
  snap.all <- bind_rows(snap)

  results.all  <- left_join(stations[,c("ECOREGION", "STATION_NUMBER")], snap.all, 
                          by=c("STATION_NUMBER"="STATION_NUMBER"))
  
  write.csv(results.all, paste0("../Variables/Summary.AnnMeanYield.csv"), row.names = FALSE)
}

summary.to.shp(results.all, "Ann_Mean_Yield", "../../../00_Shapefiles")

