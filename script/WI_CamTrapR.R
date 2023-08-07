#********************************************************************#
# Wildlife Insights workflow to CamTrapR
#    Example script
# 
# Aaron Greenville Aug 2022; update Aug 2023
#********************************************************************#

# Load packages ####
library(camtrapR)
library(tidyverse)
library(lubridate)

# Load data from WI ####
## Load camera data ####
## Change filenames after each data download

cam <- read.csv("data/wildlife-insights_BMCC_20230701_data/wildlife-insights_336007e2-fd19-45fa-b496-333668b76f0e_project-2002996_data/images.csv",
                header = TRUE)
## Load camera station/deployments from WI ####
stations <- read.csv("data/wildlife-insights_BMCC_20230701_data/wildlife-insights_336007e2-fd19-45fa-b496-333668b76f0e_project-2002996_data/deployments.csv", header = TRUE)
 

# join station locations with effort
cam.stations <- left_join(cam, stations, by="deployment_id")

## Create Ctable for camtrapR ###
# For using data without blanks and humans        
Ctable.WI <- cam.stations %>%
  select(placename, longitude, latitude, start_date, end_date, camera_id, camera_name, 
         subproject_name, timestamp) %>%
  group_by(placename, longitude, latitude,camera_id, camera_name, subproject_name) %>%
  summarise(start_date= as_date(min(start_date)), end_date= as_date(max(end_date)))


# create DateTimeOrginal column in proper format for function
cam.stations$DateTimeOriginal <- as.POSIXct(strptime(cam.stations$timestamp, format =
                                                       "%Y-%m-%d %H:%M:%S", tz = "UTC")) 

# Generate species record table with 'independent' records ####
# Rule here is 5 min
# internal function in CampTrapR package. Notice the 3 colons.
# Can take some time to run if there are a lot of photos.
# need to remove records taken at the same time of same species and location
# Reconyx rapidfire cameras can take photos quick enough that they
# can have the same time stamp
# Don't need the below if using camtrapR deluxe

# For CamTrapR - very slow!!
# cam.stations.d <- cam.stations[!duplicated(cam.stations[c('DateTimeOriginal',
#                                                           'common_name',
#                                                           'deployment_id',
#                                                           'placename' ,
#                                                           'camera_id') ]), ]


# records_filter5_min <- camtrapR:::assessTemporalIndependence(intable = cam.stations,
#                                                                    deltaTimeComparedTo = "lastIndependentRecord",  
#                                                                    columnOfInterest = "common_name", # species name 
#                                                                    stationCol = "deployment_id",
#                                                                    cameraCol = "placename",
#                                                                    camerasIndependent = TRUE,
#                                                                    minDeltaTime = 5 # 5 min threshold for independence
# )



# Generate species record table with 'independent' records ####
# Rule here is 5 min
# internal function in CampTrapR package. Notice the 3 colons.
# Can take some time to run if there are a lot of photos.
# To install camtrapRdeluxe (faster)
# install.packages("remotes")
# remotes::install_github("carlopacioni/camtrapRdeluxe",force = TRUE) #Warning this is not yet a completed package but it seems to be working for the purposes we require.
# Note only working under R.4.2.x or below. Not working in 4.3.x

records_filter5_min <- camtrapRdeluxe:::assessTemporalIndependence(intable = cam.stations,
                                                                   deltaTimeComparedTo = "lastIndependentRecord",  
                                                                   columnOfInterest = "common_name", # species name 
                                                                   stationCol = "deployment_id",
                                                                   cameraCol = "placename",
                                                                   camerasIndependent = TRUE,
                                                                   minDeltaTime = 5 # 5 min threshold for independence
)


str(records_filter5_min)

## species list ####
unique(records_filter5_min$common_name)


## Save records ####
write.csv(records_filter5_min,
          "data/BIOL3009_WI_5min_data_2023.csv", # change filename
          row.names = FALSE)


# Save both record table and CTable out into an .RData file
# to load back into R, use load() and both records_filter5_min and
# Ctable.WI will load into your R Environment.
# Note code below assumes you have a folder called data in your
# working dir.
save(records_filter5_min, Ctable.WI,
     file = "data/BIoL3009_WI_5min_data_2023.RData") # change filename

#*********************************************************************
# Camera summary ####
#********************************************************************

load("data/BIoL3009_WI_5min_data_2023.RData") # if needed, and change to your filename to curent year


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


#*******************************************************************#
# Exploring the data: detection maps ####
#******************************************************************#

## Read in camera data, if saved earlier. Ignore if already loaded from above code.
load(file = "data/BIoL3009_WI_5min_data_2023.RData") # if needed


## Detection maps
detectionMaps(CTtable = Ctable.WI,
                          recordTable = records_filter5_min,
                          Xcol = "longitude",
                          Ycol = "latitude",
                          #speciesToShow = "Swamp Wallaby",
                          stationCol = "deployment_id",
                          speciesCol = "common_name",
                          writePNG = FALSE,
                          plotR = TRUE,
                          printLabels = FALSE,
                          richnessPlot = TRUE,
                          addLegend = TRUE,
                          writeShapefile = FALSE,
                          speciesPlots = TRUE,
                          shapefileName = "BIOL3009_Species_2023", # change filename to current year
                          shapefileDirectory = "output/",	
                          shapefileProjection	="+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs"
  ) 

#*******************************************************************#
# Exploring the data: examples of diel activity ####
#* *****************************************************************#

## What species are detected ####
unique(records_filter5_min.2022$species)

## Activity #### 
activityDensity(recordTable = records_filter5_min, # change to current dataset
                speciesCol = "species",
                allSpecies  = TRUE,
                writePNG    = FALSE,
                plotDirectory = "output/",
                plotR       = TRUE,
                recordDateTimeCol = "DateTimeOriginal",
                recordDateTimeFormat = "ymd HMS",
                add.rug     = TRUE)

activityRadial(recordTable = records_filter5_min, # change to current dataset
               speciesCol = "species",
               allSpecies  = TRUE,
               writePNG    = FALSE,
               plotR       = TRUE,
               recordDateTimeCol = "DateTimeOriginal",
               recordDateTimeFormat = "ymd HMS",
               add.rug     = TRUE)

activityOverlap(recordTable = records_filter5_min, # change to current dataset
                speciesCol = "species",
                speciesA    = "Rattus fuscipes",    
                speciesB    = "Antechinus stuartii",  
                legendPosition = "top",
                writePNG    = FALSE,
                plotDirectory = "output/",
                plotR       = TRUE)

#****************************************************************#
# Exploring the data: number of images per site #### to finish
#****************************************************************#

#library(scales)

# if we have unequal sampling effort across our cameras, we can standarise
# each camera by the number of nights it was active - i.e. effort.

## count up number of photos per species ####
species.count <- records_filter5_min %>% 
  group_by(placename, camera_name, common_name, subproject_name) %>%
  tally()


## add effort and calc mean and se per fire treatment ####

species.count.effort <- left_join(species.count, effort, by = "placename") %>%
  group_by(subproject_name, common_name) %>%
  summarise_if(is.numeric, list(mean,se)) %>%
  dplyr::select(-days_fn2) %>%
  rename(., c(mean = "n_fn1", days =  "days_fn1", se = "n_fn2")) %>%
  mutate(RAI = mean/days*100) %>%
  ungroup() %>%
  complete(nesting(subproject_name, fire_class, days), common_name, fill = list(mean = 0, se = 0, RAI = 0)) 







