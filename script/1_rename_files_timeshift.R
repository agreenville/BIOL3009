#******************************************************************************#
# Script for changing photo times and renaming images 
#
#Aaron Greenville Sep 2022
#******************************************************************************#

# Load packages ####
library(camtrapR)
library(tidyverse)

# 1.Changing times ####
# if needed

timeShiftTable <- read.csv("data/timeshift.csv")

wd_images_ID_copy <- file.path("C:/BM_photos") 


timeshift_run <- timeShiftImages(inDir                = wd_images_ID_copy,
                                 timeShiftTable       = timeShiftTable,
                                 stationCol           = "Station",
                                 cameraCol            = "camera",
                                 hasCameraFolders     = TRUE,
                                 timeShiftColumn      = "timeshift",
                                 timeShiftSignColumn  = "sign",
                                 undo                 = FALSE
)

# 2.Changing filenames ###

# define raw image location
wd_images_raw <- file.path("D:/Terrestrial Ecology Camera trap Files/BIOL3X09 Terrestrial Field Ecology/") 

# define destination for renamed images
wd_images_raw_renamed <- file.path("D:/Terrestrial Ecology Camera trap Files/renamed/")       



renaming.table2 <- imageRename(inDir               = wd_images_raw,
                               outDir              = wd_images_raw_renamed,       
                               hasCameraFolders    = TRUE,
                               keepCameraSubfolders = TRUE,
                               copyImages          = TRUE,
                               writecsv            = TRUE
)

# show output files
list.files(wd_images_raw_renamed, recursive = TRUE)

# output table
renaming.table2

# 3. moving files into subfolders containing <10k of images ####
## for uploading to WI

## folder with all the renames images
folder.images <- file.path("D:/2022_12_rename/Burnt_1/B1_11/BM72/")

AllFiles <- list.files(folder.images)

## Make all of the new sub-folders
FolderNumber <- floor(1:length(AllFiles)/10000) + 1 # note 10,000 here means organise by groups of 10k images. Change for a different size.
FolderName <- sprintf("Folder%03d", FolderNumber)

for(f in unique(FolderName)) { dir.create(paste(folder.images, f, sep="/")) }

## Move the files into sub-folders

### set up progress bar
pb <- txtProgressBar(min = 1, max = length(AllFiles), style = 3)
### run for loop (to do: upgrade to use parallel processing)
for(i in 1:length(AllFiles)) {
  file.rename(paste(folder.images, AllFiles[i], sep="/"),
              paste(folder.images, FolderName[i], AllFiles[i], sep="/"))
  setTxtProgressBar(pb, i)
}
close(pb) # close progress bar


