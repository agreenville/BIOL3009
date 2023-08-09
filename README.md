# BIOL3009
R scripts for BIOL3009 Terrestrial Field Ecology.  
Aaron Greenville (aaron.greenville@sydney.edu.au)

Below is the workflow for getting camera trap images ready and uploading to Wildlife Insights.

Note: staff will have done most of these steps for you.

## 1. Fix any time errors and rename files

`1_rename_files_timeshift.R` - example script to fix files with the wrong date/time (i.e. there was an error when setting up the date/time on the camera) and then batch rename photos to have a unique filename.

Make sure you organsie your images using the following folder structure:

BIOL3009/Site/trap_number/[images]...

Note if the camera has created multiple folders, then just copy across all the folders to avoid having photos with the same filename causing conflicts.



## 2. Deployment sheet

Download Wildlife Insight deployment sheet and fill in for each camera. e.g.

`Blank depoyment bulk upload template.csv` - Wildlife Insight deployment template. Check for updated version before using.

Link to [BIOL3009 bulk upload sheet and tagging progress](https://docs.google.com/spreadsheets/d/16pZj3O4XxI4AVXv3wRbDPvQBViGvBTyxMURWwnEkkPc/edit?usp=sharing)

Upload completed deployment sheet.

## 3. Upload photos to Wildlife Insights

i.  Select the project you want to upload your photos too.\
ii. Upload batches of photos from each camera to it's corresponding deployment.\
iii. Fill out data tracker sheet ([link](https://docs.google.com/spreadsheets/d/16pZj3O4XxI4AVXv3wRbDPvQBViGvBTyxMURWwnEkkPc/edit?usp=sharing))

Hints: 
- Can use multiple browser tabs to upload photos.
- Double check deployment details before hitting upload.

Add a new sheet for each deployment and fill in details for each upload. Cross-check dates and times are correct in the images.

## 4. Tag images on Wildlife Insights

This is one of the main steps that students will do. Identifying animals in the images!

See [tutorials](https://www.wildlifeinsights.org/get-started)

## 5. Wildlife Insights downloads to CamTrapR

`WI_CamTrapR.R` - example script to take a data export from Wildlife Insights to be compatible with the R package CamTrapR.

Once all images are processed, staff will download the data from Wildlife Insights so students can use the above script to process it.

## Additional scripts

`2_camera_op.R` - script to calculate when each camera is operational and effort (days operational). Plus script can be used to tally up the number of photos per species and join with effort table for further analysis.

`handy_functions.R` - collection of handy functions in R. At present only contains function for calculating SE.

`BIOL3009_CamTrapR.R` - script to process camera trap data that is manually entered into spreadsheets.
