################################################################################
# BIOL3007 workflow to CamTrapR
# 
# 
# Aaron Greenville Aug 2022
################################################################################

#### Load packages ####
library(camtrapR)
library(tidyverse)


# Load camera data ####
cam <- read.csv("data/Dungog Camera Data 2022-data-entry_site1.csv  ", header = TRUE)

# create unique camera station id and combined date/time coln
cam <- cam %>%
  mutate(CamId = str_c(Site,Trap.Location, sep = "_" )) %>%
  mutate(DateTime = str_c(Date, Time, sep = " " ))

# create DateTimeOrginal column in proper format for function
cam$DateTimeOriginal <- strptime(cam$DateTime, format =
                                          "%d/%m/%Y %H:%M", tz = "UTC")

str(cam)

### to do - add camera gps points

# Load camera station/deployments  ####
# stations <- read.csv("data/wildlife-insights_BMCC_test_data/wildlife-insights_e957eae5-e680-48f5-9704-a1cc75abc2d1_project-2002996_data/deployments.csv", header = TRUE)

# join station locations with effort
# cam.stations <- left_join(cam, stations, by="deployment_id")


# internal function in CampTrapR package. Notice the 3 colons.
records_filter5_min <- camtrapR:::assessTemporalIndependence(intable = cam,
                                      deltaTimeComparedTo = "lastIndependentRecord",  
                                      columnOfInterest = "Species",
                                      stationCol = "CamId", # to change to site
                                      cameraCol = "CamId", # individual camera location
                                      camerasIndependent = TRUE,
                                      minDeltaTime = 5
                                      )
# check structure
str(records_filter5_min)

# convert date to a factor for data exploration below
records_filter5_min$DateTimeOriginal <- as.factor(records_filter5_min$DateTimeOriginal)

# What species are detected
unique(cam$Species)

### Save records ####
write.csv(records_filter5_min,"data/BIOL3009_site1_5min_data.csv",
          row.names = FALSE)

#saveRDS(records_filter5_min, "data/BIOL3009_site1_5min_data.rds")

#*******************************************************************#
#* Exploring the data
#* *****************************************************************#


act.site1 <- activityDensity(recordTable = records_filter5_min,
                allSpecies  = TRUE,
                writePNG    = FALSE,
                plotR       = TRUE,
                recordDateTimeCol = "DateTimeOriginal",
                recordDateTimeFormat = "ymd HMS",
                add.rug     = TRUE)

activityOverlap (recordTable = records_filter5_min,
                 speciesA    = "Rattus fuscipes",    
                 speciesB    = "Antechinus stuartii",  
                 legendPosition = "top",
                 writePNG    = FALSE,
                 plotR       = TRUE
)

## to do
Maps <- detectionMaps(CTtable = stations,
                          recordTable = records_filter5_min,
                          Xcol = "longitude",
                          Ycol = "latitude",
                          #speciesToShow = "Swamp Wallaby",
                          stationCol = "deployment_id",
                          speciesCol = "common_name",
                          # backgroundPolygon =tm_polygons("HPI")  , # need good polygon
                          writePNG = FALSE,
                          plotR = TRUE,
                          printLabels = FALSE,
                          richnessPlot = TRUE,
                          addLegend = TRUE,
                          writeShapefile = FALSE,
                          speciesPlots = TRUE,
                          shapefileName = "BMCC_Species",
                          shapefileDirectory = "output/",	
                          shapefileProjection	="+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs"
  ) 

