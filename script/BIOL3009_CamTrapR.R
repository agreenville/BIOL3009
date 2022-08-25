#*****************************************************************************##
# BIOL3009 camera trap data from Google Sheets to CamTrapR ####
# 
# 
# Aaron Greenville Aug 2022
#*****************************************************************************##

## Load packages ####
library(camtrapR)
library(tidyverse)
library(janitor)

## Load camera data ####
# Note data for each site combined into one csv file after cleaning up each coln


cam <- read.csv("data/sites/All_cam_sites.csv", header = TRUE)

# create unique camera station id and combined date/time coln
cam <- cam %>%
  clean_names() %>%
  mutate(CamId = str_c(site, trap_location, sep = "_" )) %>%
  mutate(DateTime = str_c(date, time, sep = " " ))

# create DateTimeOrginal column in proper format for function
cam$DateTimeOriginal <- strptime(cam$DateTime, format =
                                          "%d/%m/%Y %H:%M:%S", tz = "UTC")

str(cam)



# Need to remove records taken at the same time of same species and location
# Reconyx rapidfire cameras can take photos quick enough that they
# can have the same time stamp or students don't enter seconds
cam.d <- cam[!duplicated(cam[c('DateTimeOriginal', 'species',
                                                    'site',
                                                    'CamId' ) ]), ] 

str(cam.d)

## Apply an independence rule ####
# Here we use 5 min
# internal function in CampTrapR package. Notice the 3 colons.
records_filter5_min <- camtrapR:::assessTemporalIndependence(intable = cam.d,
                                      deltaTimeComparedTo = "lastIndependentRecord",  
                                      columnOfInterest = "species",
                                      stationCol = "site", # site
                                      cameraCol = "CamId", # individual camera location
                                      camerasIndependent = TRUE, # Setting cameras as independent of each other, but are they?
                                      minDeltaTime = 5    # Independence rule set to 5 min.
                                      )

# check structure
str(records_filter5_min)

# convert date to a factor for data exploration below
records_filter5_min$DateTimeOriginal <- as.factor(records_filter5_min$DateTimeOriginal)

# filter for current year's records
records_filter5_min.2022 <- records_filter5_min %>%
  filter(between(as.Date(DateTimeOriginal), as.Date("2022-01-01"),
                 as.Date("2022-12-31")))

str(records_filter5_min.2022)

## Save records ####
write.csv(records_filter5_min,"data/BIOL3009_Allsites_2022_5min_data.csv",
          row.names = FALSE)

write.csv(records_filter5_min.2022,"data/BIOL3009_Allsites_yr2022_5min_data.csv",
          row.names = FALSE)

#saveRDS(records_filter5_min, "data/BIOL3009_site1_5min_data.rds")

#*******************************************************************#
# Exploring the data: examples of diel activity ####
#* *****************************************************************#

## What species are detected ####
unique(cam$species)

## Activity #### 
activityDensity(recordTable = records_filter5_min.2022,
                speciesCol = "species",
                allSpecies  = TRUE,
                writePNG    = FALSE,
                plotDirectory = "output/",
                plotR       = TRUE,
                recordDateTimeCol = "DateTimeOriginal",
                recordDateTimeFormat = "ymd HMS",
                add.rug     = TRUE)

activityRadial(recordTable = records_filter5_min,
                speciesCol = "species",
                allSpecies  = TRUE,
                writePNG    = FALSE,
                plotR       = TRUE,
                recordDateTimeCol = "DateTimeOriginal",
                recordDateTimeFormat = "ymd HMS",
                add.rug     = TRUE)

activityOverlap(recordTable = records_filter5_min.2022,
                speciesCol = "species",
                 speciesA    = "Rattus fuscipes",    
                 speciesB    = "Antechinus stuartii",  
                 legendPosition = "top",
                 writePNG    = FALSE,
                plotDirectory = "output/",
                 plotR       = TRUE)


