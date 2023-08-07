#********************************************************************#
# Wildlife Insights workflow to CamTrapR
#    Calc camera operations and effort
# 
# Aaron Greenville Oct 2022
#********************************************************************#

# Load packages ####
library(camtrapR)
library(tidyverse)

#*********************************************************************
# Camera summary ####
#********************************************************************

# load in recordtable and CT table from WI_CamTrapR script.
load(file = "data/WI_data.RData") # if needed

## calc number of days active ####
camop_op <- cameraOperation(CTtable      = Ctable.WI,
                            stationCol   = "placename",
                            setupCol     = "start_date",
                            retrievalCol = "end_date",
                            writecsv     = FALSE,
                            hasProblems  = FALSE,
                            dateFormat   = "ymd"
)


str(camop_op)

## summary report ####
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

## Calc effort ####
# number of days each camera was operational
effort <- camop_op %>% #  
  rowSums(.,na.rm=TRUE) %>%
  data.frame(.) %>%
  rownames_to_column("placename") %>%
  rename(., days =  "." )

## count up number of photos per species ####
species.count <- records_filter5_min %>% 
  group_by(placename, camera_name, common_name, subproject_name) %>%
  tally()

# add burnt and unburnt treatments
species.count <- species.count %>%
  mutate(fire_class = case_when( 
    subproject_name == "Low_Freq"|subproject_name == "High_Freq" ~ "Unburnt",
    TRUE ~ "Burnt"))

## Optional: Save tallies ####
write.csv(species.count,"data/WI_camera_species_count.csv",
          row.names = FALSE)
