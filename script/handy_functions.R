#********************************************************************#
# Handy functions
# 
# Aaron Greenville Oct 2022
#********************************************************************#


# calc standard error ####
se <- function(x){
  sd(x, na.rm = TRUE)/sqrt(length(x))
}