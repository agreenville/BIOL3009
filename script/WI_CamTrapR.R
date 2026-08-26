########################################################################### #
# Wildlife Insights workflow to CamTrapR                                    #
#    Example script                                                         #
#                                                                           #
# Aaron Greenville Aug 2022; update Aug 2023; update Jul 2024               #
########################################################################### #

#****************************************************************************
# Load packages ####
#****************************************************************************
 
# Uncomment and run lines below to install packages if you don't have them:

# Package names
# packages <- c("ggplot2", "camtrapR", "lubridate", "scales", "dplyr", "tibble")
# 
# # Install packages not yet installed
# installed_packages <- packages %in% rownames(installed.packages())
# if (any(installed_packages == FALSE)) {
#   install.packages(packages[!installed_packages])
# }


library(camtrapR)
#library(tidyverse)
library(dplyr)
library(ggplot2)
library(tibble)
library(lubridate)

#****************************************************************************
# Load data from WI ####
#****************************************************************************

## Change filenames and path to suit your data

cam <- read.csv("data/2026/images_2004409.csv",
                header = TRUE)

## Load camera station/deployments from WI ####
stations <- read.csv("data/2026/deployments.csv", 
                     header = TRUE)
 
# join station locations with effort
cam.stations <- left_join(cam, stations, by="deployment_id")

#****************************************************************************
# Create Ctable for camtrapR ###
#****************************************************************************
# For using data without blanks and humans  

Ctable.WI <- cam.stations %>%
  select(placename, longitude, latitude, start_date, end_date, camera_id, camera_name, 
         subproject_name, timestamp) %>%
  group_by(placename, longitude, latitude,camera_id, camera_name, subproject_name) %>%
  summarise(start_date= as_date(min(start_date)), end_date= as_date(max(end_date)))


# create DateTimeOrginal column in proper format for function
cam.stations$DateTimeOriginal <- as.POSIXct(strptime(cam.stations$timestamp, format =
                                                       "%Y-%m-%d %H:%M:%S", tz = "UTC")) 

#****************************************************************************
# Generate species record table with 'independent' records ####
#****************************************************************************
# Rule here is 5 min

# Internal function in CampTrapR package. Notice the 3 colons.
# Can take some time to run if there are a lot of photos.

# Need to remove records taken at the same time of same species and location
# as Reconyx rapidfire cameras can take photos quick enough that they
# can have the same time stamp
# Don't need the below if using camtrapRDeluxe

# For CamTrapR - very slow!!
# cam.stations.d <- cam.stations[!duplicated(cam.stations[c('DateTimeOriginal',
#                                                           'common_name',
#                                                           'deployment_id',
#                                                           'placename' ,
#                                                           'camera_id') ]), ]


records_filter5_min <- camtrapR:::assessTemporalIndependence(intable = cam.stations,
                                                                   deltaTimeComparedTo = "lastIndependentRecord",
                                                                   columnOfInterest = "common_name", # species name
                                                                   stationCol = "deployment_id",
                                                                   cameraCol = "placename",
                                                                   camerasIndependent = TRUE,
                                                                   minDeltaTime = 5 # 5 min threshold for independence
)

# OR use camtrapRdeluxe (faster)....

# To install camtrapRdeluxe:

# install.packages("remotes")
# remotes::install_github("carlopacioni/camtrapRdeluxe",force = TRUE) 

# Warning this is not yet a completed package but it seems to be working for
# the purposes we require.
# Note working under R.4.2.x or below. Have had issues working in 4.3.x
# 
# records_filter5_min <- camtrapRdeluxe:::assessTemporalIndependence(intable = cam.stations,
#                                                                    deltaTimeComparedTo = "lastIndependentRecord",  
#                                                                    columnOfInterest = "common_name", # species name 
#                                                                    stationCol = "deployment_id",
#                                                                    cameraCol = "placename",
#                                                                    camerasIndependent = TRUE,
#                                                                    minDeltaTime = 5 # 5 min threshold for independence
# )


str(records_filter5_min)

## species list ####
unique(records_filter5_min$common_name)


## Save records ####
write.csv(records_filter5_min,
          "data/2026/BIOL3009_WI_5min_data_2026.csv", # change filename
          row.names = FALSE)

write.csv(Ctable.WI,
          "data/2026/Ctable.WI_2026.csv", # change filename
          row.names = FALSE)

# Save both record table and CTable out into an .RData file
# to load back into R, use load() and both records_filter5_min and
# Ctable.WI will load into your R Environment.
# Note code below assumes you have a folder called data in your
# working dir.
save(records_filter5_min, Ctable.WI,
     file = "data/2026/BIoL3009_WI_5min_data_2026.RData") # change filename

#****************************************************************************
# Camera summary ####
#****************************************************************************

#load("data/2026/BIoL3009_WI_5min_data_2026.RData") # if needed, and change to your filename to current year


### calc number of days active ####
camop_op <- cameraOperation(CTtable      = Ctable.WI, 
                            stationCol   = "placename", 
                            setupCol     = "start_date",
                            retrievalCol = "end_date",
                            writecsv     = FALSE,
                            hasProblems  = FALSE,
                            dateFormat   = "ymd"
)


str(camop_op)


report <- surveyReport(recordTable          = records_filter5_min,
                        CTtable              = Ctable.WI,
                        camOp                = camop_op,
                        speciesCol           = "common_name",
                        stationCol           = "placename",
                        setupCol             = "start_date",
                        retrievalCol         = "end_date",
                        CTDateFormat         = "ymd", 
                        recordDateTimeCol    = "DateTimeOriginal",
                        recordDateTimeFormat = "ymd HMS")

effort <- camop_op %>% #  
  rowSums(.,na.rm=TRUE) %>%
  data.frame(.) %>%
  rownames_to_column("placename") %>%
  rename(., days =  "." )


