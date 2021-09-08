###################################################################################################
# CESI project-Trend Test
# Before running this code, make sure that you have access to the following:
# Function_MKTest.R
# Function_NegBinTest.R
# Function_HurdleTest.R
# Function_SummaryToShp.R
#
# This part of the code aims at finding both the existence and magnitude of trend within 
# metrics calculated in part 01. While normally Mann-Kendall Test is used normally, 
# there are times that the outcome of MK Test may not be robust enough. Specifically, 
# for a set of data that contains numerous zeros or ties, the trend detected by MK Test
# appear to be less reliable. Therefore, we incorporate the concept of general linear models
# that performs better when dealing with zeros. More specifically, we introcduce the hurdle as
# well as negative binomial models to help figuring out potential trend for metrics. 
###################################################################################################

################ libraries ####################
library("dplyr")
#library("pscl")
library("MASS")
#install.packages("countreg", repos="http://R-Forge.R-project.org") 
# might be a better way to do this; there's no point in reinstalling every time...
library("countreg")
library("zyp")
source('Function_MKTest.R')
source('Function_NegBinTest.R')
source('Function_HurdleTest.R')
source('Function_SummaryToShp.R')
source('Function_chk_hydat.R')  # Sourcing function for hydat setup

chk.hydat("../Dependencies/Hydat")

###############################################

################ Sourcing from the model building scripts&Setting environment ####################
stations <- read.csv("../Dependencies/RHBN_U.csv", header = TRUE) %>% filter(Use_for_CESI == 1)
list <-as.character(stations$STATION_NUMBER)

### Prompt to get the metric name
var_list = c( "ann_mean_yield", "pot_days") #
#, "pot_events",  "pot_max_dur",
# "X1_day_max", "dr_days", "dr_events", "dut_max_dur", "X7_day_min")
result_list = paste0(var_list, "_trend")
#var_list = c("X7_day_min")
# Use this when testing single variable
#var.t = 

snap <- list()
##################################################################################################


for (j in 1:length(var_list)){
  var.t = var_list[j]
  print(var.t)
  output_name = paste0("../Variables/Summary_", var.t, "_trends.csv")
  for (i in 1: length(list)){
    stn.id <- list[i]
    print(stn.id)
    output1 <- paste("../Variables/", stn.id, ".csv", sep= "")
    
    # defaults to NA if data requirements aren't met
    slope <- NA
    intercept <- NA
    years.for.trend <- NA
    CATTrend <- NA
    test <- NA
    mapslope <- NA
    hurdlechk <- NA
    area <- stations$Shp_Area[stations$STATION_NUMBER == stn.id]
    data <- read.csv(output1, header = TRUE)
    if (sum(!is.na(data[[var.t]]))>=30){
      data <- data[!is.na(data[[var.t]]),]
      data.p <- data[data$year>=1970,]
      data.p <- data.p[data.p$year<=2019,] # cap data range for 2022 CESI release
      
      # Data requirements: some data 1970-1975, >=30 points, no gap over 10 years
      goodyears <- data.p$year[!is.na(data.p[[var.t]])]
      gap.check <- na.omit(goodyears - lag(goodyears))
      
      if (all(any(goodyears %in% c(1970:1975)), (length(goodyears) >= 30), 
              (max(gap.check) <= 11))){
        
        if (var.t == "ann_mean_yield"){
          time <- case_when(grepl("yield", var.t) ~ 365*24*3600, # annual mean flow
                            grepl("X7", var.t) ~   7*24*3600, # 7-day min/max's
                            grepl("X1", var.t) ~   1*24*3600) # 1 day flows
          data.p[[var.t]] <- data.p[[var.t]]*time/(area*10^3)
        }
        
        # Are there any zero values?
        if((sum(data.p[[var.t]]==0)<=1)&(var.t %in% c("X1_day_max", "ann_mean_yield", "X7_day_min"))){
          print("Mann-Kendall test")
          mk.test(var.t)
        }else{
          # Is hurdle necessary?
          hurdle <- FALSE #default to False
          if (sum(data.p[[var.t]]==0) >= 3){
            model2 <- tryCatch(hurdle(data.p[[var.t]]~data.p$year, data.p, dist="negbin", zero.dist = "negbin"),
                               error=function(e){return("A")}, warning=function(w){return("B")})

            if(!is.character(model2)){
              hurdlechk <- hurdletest(model2)[2,4]
              if(!is.nan(hurdlechk)){
                hurdle <- ifelse(hurdlechk>0.1, TRUE, FALSE)
              }
            }
          }

          if(hurdle){
            #Apply the hurdle model
            print("Hurdle test")
            hurdle.test(var.t)
          } else {
            #Apply the negative binomial model
            print("Negative Binomial test")
            negbin(var.t)
          }
          CATTrend <- pass
        }
      }
    }

    # mapslope field only has values for likely/confident trends for mapping
    mapslope <- case_when( grepl("Likely", CATTrend)    ~ slope,
                           grepl("Confident", CATTrend) ~ slope)
    # Load data and subset
    snap[[i]] <- data.frame(STATION_NUMBER=stn.id, slope=slope, intercept=intercept,
                            years.for.trend=years.for.trend, CATTrend=CATTrend,
                            test=test, hurdlechk = hurdlechk, mapslope=mapslope)
  }
  
  snap.all <- bind_rows(snap)
  
  if (file.exists(output_name)){
   file.remove(output_name)
  }
  
  assign(result_list[j], snap.all)
  
  write.csv(snap.all, output_name, row.names = FALSE)
  
  summary.to.shp(snap.all, paste0(var.t,"_trend"), "../../../00_Shapefiles")
  snap <-list()
}



