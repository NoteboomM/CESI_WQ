###################################################################################################
# CESI project part 8-Creating Summary Tables
# Overall Descriptions: 
# This section takes all the metrics calculated before to create summary tables containing
# stations with a row for every station-parameter pair, and columns of summary stats
# and result/percentile for each year 1970-2016 (or end of the data available).
###################################################################################################


###########      Library             ###########
library(dplyr)     # For data tidying and data tables     
library(tidyr)     # For data tidying
library(zyp)       # For applying trend tests
source('02_Figures2_SummaryToShpFN.R')  # Sourcing function for shapefile output
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


##### Creating Summary tables for Metrics  #####
# for each station, extract the metric in question, then alter by watershed area if needed
if (file.exists(paste0("../Variables/Summary.AnnMeanYield.csv"))){
  results.all <- read.csv(paste0("../Variables/Summary.AnnMeanYield.csv"), header = TRUE)
} else {
  snap <- list()
  for (k in 1:length(stn.list.full)){
    var.name <- list.var.name[1]
    var.t <- list.var[1]
    
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
    data$yearplot <- NA
    data$yearplot <- case_when( (data$year >= trend.minyr) ~ data$year )

    # calculate the 25th and 75th percentile for the 1981-2010 period,
    # provided there are at least 20 years of data within that period.
    if (sum(!is.na(data.ref[[var.t]]))>=20){
      q.var <- quantile(data.ref[[var.t]], c(0.25, 0.75), na.rm=TRUE)
      median <- median(data[[var.t]], na.rm=TRUE)
    } else {
      q.var <- c(NA, NA)
      median <- NA
    }
    goodyears <- data$yearplot[!is.na(data$yearplot) & !is.na(data[[var.t]])]
    gap.check <- goodyears - lag(goodyears)
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
  # This file was created by extracting 2016 result row from variable csv files and bind_rows 
  # Create summary tables for high-low-normal
  results.all  <- left_join(stations[,c("ECOREGION", "STATION_NUMBER")], snap.all, 
                          by=c("STATION_NUMBER"="STATION_NUMBER"))
  # results.all$CAT2016 <- case_when(results.all$result.2016 < results.all$q25 ~ "Low",
  #                                 results.all$result.2016 >= results.all$q25 & results.all$result.2016 <= results.all$q75 ~ "Normal",
  #                                 results.all$result.2016 > results.all$q75 ~ "High")
  # results.all$CATTrend <- case_when(results.all$Z <= -1.28 ~ "Confident Downward",
  #                                  results.all$Z  > -1.28 & results.all$Z <= -0.52 ~ "Likely Downward",
  #                                  results.all$Z  > -0.52 & results.all$Z  <  0.52 ~ "Uncertain",
  #                                  results.all$Z >=  0.52 & results.all$Z  <  1.28 ~ "Likely Upward",
  #                                  results.all$Z >=  1.28 ~ "Confident Upward")
  write.csv(results.all, paste0("../Variables/Summary.AnnMeanYield.csv"), row.names = FALSE)
}

summary.to.shp(results.all, "Ann_Mean_Yield", "../../../00_Shapefiles")

# if (file.exists(paste0("../Variables/Summary.Variables.", ref, ".csv"))){
#   Summary.v <- read.csv(paste0("../Variables/Summary.Variables.", ref, ".csv"), header = TRUE)
# } else {
#   Summary.v <- results.all %>% group_by(variable) %>% summarise(Low = sum(CAT2016 == "Low", na.rm=TRUE), 
#                                                                Normal = sum(CAT2016 == "Normal", na.rm = TRUE),
#                                                                High = sum(CAT2016 == "High", na.rm = TRUE))
#   write.csv(Summary.v, paste0("../Variables/Summary.Variables.", ref, ".csv"), row.names = FALSE)
# }
# 
# 
# ##### Creating summary tables for trends #####
# snap <- list()
# for (k in 1:length(stn.list.full)){
#   stn <- stn.list.full[k]
#   # print(stn)
#   # load data
#   data <- read.csv(paste0("../Variables/", stn, ".csv"), header = TRUE)
#   data$station <- as.character(data$station)
#   
#   # extract variable of interest
#   q <- data.frame(matrix(ncol=4, nrow=length(list.var), 
#                          dimnames= list(NULL, c("STATION_NUMBER","variable","Sen.slope", "Z"))))
#   q$STATION_NUMBER <- stn
#   q$variable <- list.var
#   
#   # Change variable dates from month-day to julian date
#   for (i in 1:length(list.var.name)) {
#     # if variable needs it, scale variable by watershed size. Units will now be in mm/time,
#     # where time is either one year, 7 days, or one day.
#     if (var.t %in% c("ann_mean_yield", "X7_day_min", "X1_day_max")){
#       watershed <- stations[stations$STATION_NUMBER == stn, "Shp_Area"]
#       time <- case_when(var.t ==  "ann_mean_yield"  ~ 365*24*3600,
#                         var.t ==  "X7_day_min"       ~ 7*24*3600,
#                         var.t ==  "X1_day_max"       ~ 1*24*3600)
#       data[[var.t]] <- data[[var.t]]*time/(watershed*10^3)
#     }}
#   
#   for (i in 1:length(list.var.name)) {
#     var.name <- list.var.name[i]
#     var.t <- list.var[i]
#     if (nrow(data[!is.na(data[[var.t]]),]) >= 10 & sd(data[[var.t]], na.rm = TRUE)>0){
#       # Assess Sens trend slope, whether it meets alpha=10%, and set anotation
#       x<- data$year[!is.na(data[[var.t]])]
#       y<- data[[var.t]][!is.na(data[[var.t]])]
#       sen <- zyp.sen(y~x)
#       corr<- cor.test(y, x, method = "kendall", alternative = "two.sided", exact = FALSE)
#       q[q$STATION_NUMBER==stn & q$variable==var.t, "Sen.slope"] <- sen$coefficients[[2]]
#       q[q$STATION_NUMBER==stn & q$variable==var.t, "Z"] <- corr$statistic[["z"]]
#     } 
#     #if any(data[[var.t]]<=0.001)
#   }
#   snap[[k]] <- q
# }
# # Combine stations
# snap.all <- bind_rows(snap)
# # Creat summary tables for high-low-normal
# Ind.trends <- left_join(stations[,c("ECOREGION", "STATION_NUMBER")], snap.all, 
#                         by=c("STATION_NUMBER"="STATION_NUMBER"))
# write.csv(Ind.trends, paste0("../Variables/Summary.trends.csv"), row.names = FALSE)
# trend.v <- Ind.trends %>% group_by(variable) %>% 
#   summarise(Sig.pos = sum(Z>=0.84, na.rm=TRUE), 
#             None = n() - sum(Z>=0.84, na.rm=TRUE) - sum(Z<=-0.84, na.rm = TRUE),
#             Sig.neg = sum(Z<=-0.84, na.rm = TRUE))
# write.csv(trend.v, paste0("../Variables/Summary.Variables.trends_", aggmethod, ".csv"), row.names = FALSE)
# 
# # Remove redundant variables to save memory space
# remove(snap,stn,data,q,var.name,var.t,watershed,time,data.ref,q.var,median,goodyears,gap.check,latest, 
#        refyear, x, y, trend.n, sen, corr, Z, msen, bsen, snap.all)
# gc()
