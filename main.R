RNGkind(sample.kind = "Rounding") # for reproducibility in future versions of R

# load relevant packages
library(tidyverse)
library(raster)
library(rgdal)
library(rgeos)
library(maptools)
library(readxl)
library(ggplot2)

# define coordinate system
crs <- '+proj=utm +zone=36 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0'

## the part commented below is the original code
## however, I created a RDS file so users can run the code without downloading the satellite images (heavy files)

## read landsat8 data
#raw.list <- list.files("landsat8/", pattern = glob2rx("*band*.tif$"), full.names = T)
## you need to download the same files, see descriptions in materials.
## Check with the .txt and .xml I provided in this folder if they are
## the EXACT same files (should have the EXACT same name when you download them).

#A <- stack(raw.list)
#saveRDS(A, "landsat8data.RDS")

## saving in RDS allows people to test the code without downloading the landsat 8 files

## read landsat8 data:
A <- readRDS("landsat8data.RDS")
lcsfbr <- brick(A)

# Crop Landsat
source("getting_coords.R") # and coordinates
# east, west, south, north extent for Gorongosa Paleontological Localities
l_crop <- crop(lcsfbr, extent(zone))
crs(l_crop)


#### CLUSTERING ####

nr <- getValues(l_crop) # extract numeric values
storage.mode(nr) <- "integer" # makes it faster
set.seed(1) # reproducibility

## kmeans ##

nr.km <- kmeans(na.omit(nr), centers = 8, iter.max = 1600,
                nstart = 3, algorithm = "Lloyd")
lc <- as.matrix(nr.km$cluster)

# calculate % of classifier cluster reduction
table(lc)[[1]]/sum(table(lc)) * 100

# create a rasterized version of the clustering results

clustercover <- raster(lc, crs = crs(l_crop), template = l_crop)

# VISULIZATION
# helpers

cluster_spdf <- as(clustercover, "SpatialPixelsDataFrame")
cluster_df <- as.data.frame(cluster_spdf)
colnames(cluster_df) <- c("value", "longitude", "latitude")

my_palette <- c("#fefff2", rev(viridis::cividis(n = 7)))

ds16_17 <- coo[-c(12:15),] # removes gpl 9 to 12b, because this is plot before going to the field
ds16_17 <- ds16_17[ds16_17$`Fossil sites` != 'Non-localities 2018',]

# Figure 3

ggplot() +  
  geom_tile(data = cluster_df, aes(longitude, latitude, fill = factor(value))) + 
  scale_fill_manual(values = my_palette) + coord_equal() +
  geom_point(
    data = ds16_17,
    aes(Long, Lat,
        color = `Fossil sites`,
        shape = `Fossil sites`,
        size = `Fossil sites`),
    stroke = 1.75) +
  scale_colour_manual(values = c(rep('#ff00de', 4), 'red')) +
  scale_shape_manual(values = c(1,21,22,25,4)) +
  scale_size_manual(values = c(3,5,5,2,1.5)) +
  theme_minimal() + labs(fill = 'k clusters')

ggsave('kmeansGorongosa_Figure_03.png', last_plot(), width = 8, height = 6,
       device = 'png', scale = 1.3, dpi = 'retina', type = 'cairo')

# Figure 5

cluster_df$value2 <- cluster_df$value != 1
cluster_df$value2 <- as.factor(cluster_df$value2)
levels(cluster_df$value2) <- c('Fossils (Prediction)', 'Other 7 clusters combined')

ggplot() +  
  geom_tile(data = cluster_df, aes(longitude, latitude, fill = factor(value2))) + 
  scale_fill_manual(values = c(my_palette[[1]], my_palette[[7]])) + coord_equal() +
  geom_point(
    data = coo,
    aes(Long, Lat,
        color = `Fossil sites`,
        shape = `Fossil sites`,
        size = `Fossil sites`),
    stroke = 1.75) +
  scale_colour_manual(values = c(rep('#ff00de', 4), rep('red', 2))) +
  scale_shape_manual(values = c(1,21,22,25,4,3)) +
  scale_size_manual(values = c(3,5,5,2,1.5,1.5)) +
  geom_path(data = day1, aes(Long, Lat), size = 0.5, alpha = 0.3) +
  geom_path(data = day2, aes(Long, Lat), size = 0.5, alpha = 0.3) +
  geom_path(data = day3, aes(Long, Lat), size = 0.5, alpha = 0.3) +
  geom_path(data = day4, aes(Long, Lat), size = 0.5, alpha = 0.3) +
  geom_path(data = day7, aes(Long, Lat), size = 0.5, alpha = 0.3) +
  geom_path(data = day9, aes(Long, Lat), size = 0.5, alpha = 0.3) +
  geom_path(data = day10, aes(Long, Lat), size = 0.5, alpha = 0.3) +
  theme_minimal() + labs(fill = 'k clusters')

ggsave('kmeansGorongosa_Figure_05.png', last_plot(), width = 8, height = 6, device = 'png', scale = 1.3, dpi = 'retina', type = 'cairo')

# generate variable importance
library(randomForest)
set.seed(1)

# prepare data
tree_set <- cbind(cluster_df, nr)
colnames(tree_set) <- c('cluster', 'longitude', 'latitude', 'prediction',
                        'ultrablue', 'blue', 'green', 'red',
                        'nearinfrared', 'SWIR1', 'SWIR2')

# randomForest for supervised classification of clusters
treeModel <- randomForest(as.factor(cluster) ~ ultrablue + blue + green + red + nearinfrared + SWIR1 + SWIR2,
                          data = tree_set, importance = TRUE)

# save the varImp object
imp <- varImpPlot(treeModel, type = 1) 

# convert to dataframe
impDF <- as.data.frame(imp)

# code for plot aesthetics
impDF$varnames <- rownames(impDF) # row names to column
impDF$cluster1 <- treeModel$importance[,1]/treeModel$importanceSD[,1] # cluster 1 specific data
impDF$varnames <- factor(impDF$varnames, c('ultrablue', 'blue', 'green', 'red',
                                           'nearinfrared', 'SWIR1', 'SWIR2'))
rownames(impDF) <- NULL 
# nice colours: 
clrplts <- c("#5034db","#3498db","#2ecc71","#e74c3c","#c0392b","#e73c64","#e73cb1")


# Figure 4

data_tbl <- readRDS('data_tbl.rds')
long_data_tbl <- data_tbl %>%
  gather(5:11, key = Band, value = "Value") %>%
  mutate_if(is_character, factor)

long_data_tbl$cluster <- factor(long_data_tbl$cluster, c("Fossil Sites", 1:8))
levels(long_data_tbl$cluster) <- c("Fossil Sites", paste("Cluster", 1:8))
long_data_tbl$Band <- factor(long_data_tbl$Band, c('ultrablue', 'blue', 'green', 'red', 'nearinfrared', 'SWIR1', 'SWIR2'))
levels(long_data_tbl$Band) <- c('A) ultrablue', 'B) blue', 'C) green', 'D) red', 'E) nearinfrared', 'F) SWIR1', 'G) SWIR2')

ggplot(long_data_tbl) + 
  geom_violin(aes(x = cluster, y = Value, fill = cluster), trim = FALSE, scale = "width") +
  scale_fill_manual(values = c('#ff00de', my_palette), guide = guide_legend(title = "Key", ncol = 3, direction = "horizontal"))  +
  facet_wrap(~ Band, scales = "free") + theme_bw() + labs(x = '', y = '') + 
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), legend.position = c(0.7, 0.1)) +
  theme(strip.background = element_rect(fill = my_palette[[8]])) +
  theme(strip.text = element_text(colour = 'white', face = "bold"))

ggsave('kmeansGorongosa_Figure_04.png', last_plot(), width = 6, height = 6, device = 'png', scale = 1, dpi = 'retina', type = 'cairo')


# Figure 6

ggplot(impDF, aes(x = varnames, y = MeanDecreaseAccuracy, color = as.factor(varnames))) + 
  geom_segment(aes(x = varnames, xend = varnames, y = 0, yend = MeanDecreaseAccuracy), size = 3) +
  geom_point(aes(y = cluster1), size = 3, shape = 21, fill = 'white', stroke = 2) +
  scale_color_manual(values = clrplts, guide = FALSE) +
  ylab("average increase in prediction error as a variable is permuted (%IncMSE)") + xlab("") +
  coord_flip() + theme_minimal()

ggsave('kmeansGorongosa_Figure_06.png', last_plot(), width = 9, height = 3.75, device = 'png', scale = 0.75,  dpi = 'retina', type = 'cairo')
