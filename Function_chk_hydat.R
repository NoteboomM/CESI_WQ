

chk.hydat <- function(hydat.path = NULL){
  print("Ignore tidyhydat error on first run; package looks in default location.")
  
  library(tidyhydat)
  
  hy_file <- paste0(hydat.path,"/Hydat.sqlite3")
  print(hy_file)
  if( length( grep("Hydat.sqlite", list.files(hydat.path)))==0){
    
    # hydat file will be downloaded in dependencies and subsequent tidyhydat calls will use this file
    # Highly suggest keeping a file folder with old Hydat versions to be able to reproduce old work
    
    print(paste("No hydat database found in", hydat.path))
    
    download_hydat(dl_hydat_here = hydat.path)
    
    hy_set_default_db(hydat_path = hy_file)
    
  } else {

    hy_set_default_db(hydat_path = hy_file)
    
  }
  
  version <- hy_version(hydat_path = hy_file)
  assign("version", substring(version$Date,0,7), envir = globalenv())
  
}

