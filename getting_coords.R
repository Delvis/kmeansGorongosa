zone <- extent(672000, 678000, -2097000, -2091000) # coords extracted from inside the training area


# get coordinates from Gorongosa
coords <- as.data.frame(read_excel("gpl.xlsx"))

# dataset cleaning and pre-processing
negID <- coords$`Fossil sites` == 'Non-localities' | coords$`Fossil sites` == 'Non-localities 2018'
coords_NOT <- coords[negID,]
# remove menguere points for aesthetics / plotting
coords_NOT <- coords_NOT[coords_NOT$Long > 670200,]

# test set
coordsx <- coords[!negID,]


source('sorting_repeated_data.R')

coo <- rbind(coords, coords_NOT)
coo$`Fossil sites` <- factor(
  coo$`Fossil sites`,
  levels = c("Single vertebrate find",
             "Vertebrates + Invertebrates",
             "Invertebrates",
             "Fossilized wood",
             "Non-localities",
             "Non-localities 2018"))