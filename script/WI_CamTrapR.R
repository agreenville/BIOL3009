########################################################################### #
# Wildlife Insights workflow to CamTrapR                                    #
#    Example script                                                         #
#                                                                           #
# Aaron Greenville Aug 2022; update Aug 2023                                #
########################################################################### #

#****************************************************************************
# Load packages ####
#****************************************************************************
 
# uncomment and run lines below to install packages if you don't have them:

# Package names
# packages <- c("tidyverse", "camtrapR", "lubridate", "scales")
# 
# # Install packages not yet installed
# installed_packages <- packages %in% rownames(installed.packages())
# if (any(installed_packages == FALSE)) {
#   install.packages(packages[!installed_packages])
# }


library(camtrapR)
library(tidyverse)
library(lubridate)

#****************************************************************************
# Load data from WI ####
#****************************************************************************

## Change filenames and path to suit your data

cam <- read.csv("data/2023/wildlife-insights_2023_data/images.csv",
                header = TRUE)

## Load camera station/deployments from WI ####
stations <- read.csv("data/2023/wildlife-insights_2023_data/deployments.csv", 
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


# records_filter5_min <- camtrapR:::assessTemporalIndependence(intable = cam.stations,
#                                                                    deltaTimeComparedTo = "lastIndependentRecord",  
#                                                                    columnOfInterest = "common_name", # species name 
#                                                                    stationCol = "deployment_id",
#                                                                    cameraCol = "placename",
#                                                                    camerasIndependent = TRUE,
#                                                                    minDeltaTime = 5 # 5 min threshold for independence
# )

# OR use camtrapRdeluxe (faster)....

# To install camtrapRdeluxe:

# install.packages("remotes")
# remotes::install_github("carlopacioni/camtrapRdeluxe",force = TRUE) 

# Warning this is not yet a completed package but it seems to be working for
# the purposes we require.
# Note working under R.4.2.x or below. Have had issues working in 4.3.x

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

#****************************************************************************
# Camera summary ####
#****************************************************************************

load("data/BIoL3009_WI_5min_data_2023.RData") # if needed, and change to your filename to current year


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


#****************************************************************************
# Exploring the data: detection maps ####
#****************************************************************************

## Read in camera data, if saved earlier. Ignore if already loaded from above code.
load(file = "data/BIoL3009_WI_5min_data_2023.RData") # if needed


## Detection maps
detectionMaps(CTtable = Ctable.WI,
                          recordTable = records_filter5_min,
                          Xcol = "longitude",
                          Ycol = "latitude",
                          #speciesToShow = "Swamp Wallaby",
                          stationCol = "placename",
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

#****************************************************************************
# Exploring the data: examples of diel activity ####
#****************************************************************************

## What species are detected ####
unique(records_filter5_min$common_name)

## Activity #### 
activityDensity(recordTable = records_filter5_min, 
                speciesCol = "common_name",
                allSpecies  = TRUE,
                writePNG    = FALSE,
                plotDirectory = "output/",
                plotR       = TRUE,
                recordDateTimeCol = "DateTimeOriginal",
                recordDateTimeFormat = "ymd HMS",
                add.rug     = TRUE)

activityRadial(recordTable = records_filter5_min, 
               speciesCol = "common_name",
               allSpecies  = TRUE,
               writePNG    = FALSE,
               plotR       = TRUE,
               recordDateTimeCol = "DateTimeOriginal",
               recordDateTimeFormat = "ymd HMS",
               add.rug     = TRUE)

activityOverlap(recordTable = records_filter5_min, 
                speciesCol = "common_name",
                speciesA    = "Rattus Species",    # change species names to match your dataset
                speciesB    = "Antechinus Species",  # change species names to match your dataset
                legendPosition = "topleft",
                writePNG    = FALSE,
                plotDirectory = "output/",
                plotR       = TRUE)

#****************************************************************************
# Exploring the data: number of images per site ####
#****************************************************************************

library(scales)

# Read in function to calc SE
source("script/handy_functions.R") 

# If we have unequal sampling effort across our cameras, we can standarise
# each camera by the number of nights it was active - i.e. effort.

## count up number of photos per species ####
species.count <- records_filter5_min %>% 
  group_by(placename, camera_name, common_name, subproject_name) %>%
  tally()


## add effort and calc mean and se per site ####

# Note this is using each camera per site to calc the mean, but are they independent?

species.count.effort <- left_join(species.count, effort, by = "placename") %>%
  mutate(RAI = n/days*3) %>%
  group_by(subproject_name, common_name) %>%
  summarise_if(is.numeric, list(mean,se)) %>%
  dplyr::select(-days_fn2) %>%
  rename(., c(mean = "n_fn1", days =  "days_fn1", se_mean = "n_fn2",
              RAI_mean = "RAI_fn1", RAI_se = "RAI_fn2"))


## Graphing images per site ####
# Note we have calc relative activity index (RAI), which is:
# (the number of images/number of days the camera was active)*3 days
#
# If there were no camera failures and all cameras were active for the same amount of time (3 days),
# then the mean number of images per camera is the same as the RAI.


overall.site.means <- species.count.effort %>% 
  #filter(common_name %in% speciesToPlot) %>%
  ggplot(aes(reorder(common_name, -RAI_mean), RAI_mean, colour=subproject_name, fill=subproject_name)) +
  geom_col(position=position_dodge())+
  geom_errorbar(aes(ymin=RAI_mean-RAI_se, ymax=RAI_mean+RAI_se), color="black", width=.5,
                position =  position_dodge(width = 0.9))+
  theme_classic() +
  theme(axis.text.x = element_text(angle=60, hjust=1),
        axis.title.x=element_blank()) +
  scale_y_continuous(expand = c(0, 0), limits = c(0,17), oob = rescale_none)

overall.site.means

# to save plot out uncomment the below line
# ggsave(plot = overall.site.means,
#         "output/BIOL3009_RAI_allSpecies.png", width = 12, height = 7)

# if you want to select different species to plot:

## Specis to plot
# add of remove species common names to choose what you want to plot.

speciesToPlot <- c("Rattus Species",    
                "Antechinus Species", 
                "Long-nosed Bandicoot",
                "Common Brushtail Possum")
      

species.site.means <- species.count.effort %>% 
  filter(common_name %in% speciesToPlot) %>%
  ggplot(aes(reorder(common_name, -RAI_mean), RAI_mean, colour=subproject_name, fill=subproject_name)) +
  geom_col(position=position_dodge())+
  geom_errorbar(aes(ymin=RAI_mean-RAI_se, ymax=RAI_mean+RAI_se), color="black", width=.5,
                position =  position_dodge(width = 0.9))+
  theme_classic() +
  theme(axis.text.x = element_text(angle=60, hjust=1),
        axis.title.x=element_blank()) +
  scale_y_continuous(expand = c(0, 0), limits = c(0,17), oob = rescale_none)

species.site.means

# to save plot out uncomment the below line
# ggsave(plot = species.site.means ,
#            "output/BIOL3009_RAI_Species.png", width = 12, height = 7)

#****************************************************************************
# Exploring the data: species richness per site ####
#****************************************************************************

## Mean species richness per site ####

sp.richness <- species.count %>% 
  group_by(placename, subproject_name) %>%
  summarise(n = n_distinct(common_name)) %>%
  rename(., speciesRichness = n) %>%
  group_by(subproject_name) %>%
  summarise(mean = mean(speciesRichness), se = se(speciesRichness))

## Plotting mean species richness per site ####

sp.richness.plot <- sp.richness %>% 
  ggplot(aes(reorder(subproject_name, -mean), mean)) +
  geom_col(position=position_dodge())+
  geom_errorbar(aes(ymin=mean-se, ymax=mean+se), color="black", width=.5,
                position =  position_dodge(width = 0.9))+
  theme_classic() +
  ylab("Mean species richness") +
  theme(axis.text.x = element_text(angle=60, hjust=1),
        axis.title.x=element_blank()) +
  scale_y_continuous(expand = c(0, 0), limits = c(0,10), oob = rescale_none)

sp.richness.plot

# to save plot out uncomment the below line
# ggsave(plot = sp.richness.plot,
#        "output/BIOL3009_SpeciesRichness.png", width = 12, height = 7)


#****************************************************************************
#*Exploring the data: species diversity ####
#****************************************************************************

#*Species diversity per site ####

## Simpson's diversity index ####

# Simpson's diversity index is calculated as:

# D = 1 - sum(p_i^2)
#
# where p_i is the proportion of species i in the community.
#
# We can calculate this for each site and plot the results.
#
# Note: This is a measure of species diversity, not richness.
#
# Richness is the number of species present in a community, while diversity
# is a measure of the number of species and their relative abundance.
#
# A community with many species, but where one species dominates, will have
# a lower diversity than a community with fewer species but where they are
# more evenly distributed.

## Calculate Simpson's diversity index ####

species.diversity.simpson <- species.count %>% 
  group_by(placename, subproject_name) %>%
  mutate(proportion = n/sum(n)) %>%
  summarise(Simpson = 1 - sum(proportion^2)) %>%
  group_by(subproject_name) %>%
  summarise(mean = mean(Simpson), se = se(Simpson))

## Plotting Simpson's diversity index ####

species.diversity.simpson.plot <- species.diversity.simpson %>% 
  ggplot(aes(reorder(subproject_name, -mean), mean)) +
  geom_col(position=position_dodge())+
  geom_errorbar(aes(ymin=mean-se, ymax=mean+se), color="black", width=.5,
                position =  position_dodge(width = 0.9))+
  theme_classic() +
  ylab("Simpson's diversity index") +
  theme(axis.text.x = element_text(angle=60, hjust=1),
        axis.title.x=element_blank()) +
  scale_y_continuous(expand = c(0, 0), limits = c(0,1), oob = rescale_none)

species.diversity.simpson.plot

# to save plot out uncomment the below line
# ggsave(plot = species.diversity.simpson.plot,
#        "output/BIOL3009_SpeciesDiversitySimpson.png", width = 12, height = 7)

## Shannon's diversity index ####
# Shannon's diversity index is calculated as:

#H = -sum(p_i * ln(p_i))
#
#where p_i is the proportion of species i in the community.
#
#We can calculate this for each site and plot the results.

## Calculate Shannon's diversity index ####

species.diversity <- species.count %>% 
  group_by(placename, subproject_name) %>%
  mutate(proportion = n/sum(n)) %>%
  summarise(Shannon = -sum(proportion * log(proportion))) %>%
  group_by(subproject_name) %>%
  summarise(mean = mean(Shannon), se = se(Shannon))

## Plotting Shannon's diversity index ####

species.diversity.plot <- species.diversity %>% 
  ggplot(aes(reorder(subproject_name, -mean), mean)) +
  geom_col(position=position_dodge())+
  geom_errorbar(aes(ymin=mean-se, ymax=mean+se), color="black", width=.5,
                position =  position_dodge(width = 0.9))+
  theme_classic() +
  ylab("Shannon's diversity index") +
  theme(axis.text.x = element_text(angle=60, hjust=1),
        axis.title.x=element_blank()) +
  scale_y_continuous(expand = c(0, 0), limits = c(0,2), oob = rescale_none)

species.diversity.plot

# to save plot out uncomment the below line
# ggsave(plot = species.diversity.plot,
#        "output/BIOL3009_SpeciesDiversity.png", width = 12, height = 7)


