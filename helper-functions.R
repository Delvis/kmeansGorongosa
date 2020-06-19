library(paleobioDB)
hominidae <-  pbdb_occurrences(limit = "all",
                               base_name = "hominidae", vocab = "pbdb",
                               interval = "Neogene",             
                               show = c("coords", "phylo", "ident"))
head(hominidae)

pbdb_map(hominidae)

primates <-  pbdb_occurrences(limit = "all",
                              base_name = "primates", vocab = "pbdb",
                              interval = "Neogene", continent = "AFR",
                              show = c("coords", "phylo", "ident", "loc"))
par(mar=c(5.1,4.1,4.1,6))
pbdb_temp_range(primates, rank = "genus", col = 0:1)
abline(v = 3.5, col = 'red')
abline(v = 3, col = 'red')

pbdb_richness(primates, rank = "genus", temporal_extent = c(0,10), res = 1)

mgap <- pbdb_richness(primates, rank = "species", temporal_extent = c(0,20), res = 1)
mgap$temporal_intervals <- factor(mgap$temporal_intervals,
                                  levels = c("0-1", "1-2", "2-3", "3-4", "4-5",
                                             "5-6", "6-7", "7-8", "8-9", "9-10",
                                             "10-11", "11-12", "12-13", "13-14",
                                             "14-15", "15-16", "16-17", "17-18",
                                             "18-19", "19-20"))
mgap$lmio <- as.factor(c(rep(0,6), rep(1,5), rep(0,9)))


################
library(ggplot2)

ggplot(mgap, aes(x = temporal_intervals, y =  richness, fill = lmio)) + geom_col() +
  guides(fill = FALSE) + scale_fill_manual(values = c('grey30', 'black')) +
  #geom_rect(mapping = aes(xmin = 13.1, xmax = Inf, ymin = 31, ymax = Inf), fill = 'white') +
  #geom_rect(mapping = aes(xmin = -Inf, xmax = 5.9, ymin = 31, ymax = Inf), fill = 'white') +
  scale_y_continuous(limits = c(NA, 36.5)) +
  annotate("text", x = 2.5, y = 35, label = 'italic(Pan/Homo)~split', parse = TRUE) +
  ylab("African Primates Species Richness") + xlab("Million years before present") +
  annotate("text", x = 9, y = 7, label = 'atop(bold("Late Miocene gap"))', parse = TRUE) +
  # Add 0.5 to all values from now on because of the nature of the graph using intervals instead of natural numbers
  annotate("errorbarh", y = 36, xmin = 8.7, xmax = 10.18, colour = "#2980b9", size = 1.5) +
  annotate("errorbarh", y = 36, xmin = 10.71, xmax = 12.94, colour = "#2980b9", size = 1.5) +
  annotate("text", x = 17, y = 36.2, label = 'Montagnon et al. (2013)', colour = "#2980b9") +
  annotate("errorbarh", y = 35, xmin = 7, xmax = 9.8, colour = "#27ae60", size = 1.5) + 
  annotate("errorbarh", y = 35, xmin = 12.2, xmax = 13, colour = "#27ae60", size = 1.5) +
  annotate("text", x = 17, y = 35.1, label = 'Moorjani et al. (2016)', colour = "#27ae60") +
  annotate("errorbarh", y = 34, xmin = 6.45, xmax = 10.45, colour = "#f1c40f", size = 1.5) +
  annotate("text", x = 17, y = 33.9, label = 'Barba-Montoya et al. (2017)', colour = "#f1c40f") +
  annotate("errorbarh", y = 33, xmin = 7.8, xmax = 8.9, colour = "#8e44ad", size = 1.5) + 
  annotate("text", x = 17, y = 32.8, label = 'dos Reis and Young (2019)', colour = "#8e44ad") +
  theme_void() + theme(axis.text.x = element_text(angle = 45))

ggsave('FINAL_PAPER_00_helper.tiff', last_plot(), device = 'tiff', scale = 1, dpi = 'retina', type = "cairo")

ggplot(mgap, aes(x = temporal_intervals, y =  richness, fill = lmio)) + geom_col() +
  guides(fill = FALSE) + scale_fill_manual(values = c('grey30', 'black')) +
  ylab("African Primates Species Richness") + xlab("Million years before present") +
  annotate("text", x = 9, y = 7, label = 'atop(bold("Late Miocene gap"))', parse = TRUE) +
  theme_minimal() + theme(axis.text.x = element_text(angle = 45), axis.title.y = element_text(margin = margin(b = -100)))

ggsave('FINAL_PAPER_00_a.tiff', last_plot(), device = 'tiff', scale = 1, dpi = 'retina', type = "cairo")

################
library(ggmap)

# primatesLM <-  pbdb_occurrences(limit = "all",
#                               base_name = "primates", vocab = "pbdb",
#                               interval = "Late Miocene", continent = "AFR",
#                               show = c("coords", "phylo", "ident", "loc"))

sites_Africa <- read.csv("~/My R environment/ExperimentsSpatialPackages/LateMioceneSitesAfrica.csv",fileEncoding="UTF-8-BOM")
sites_Africa$fossil.sites <- factor(sites_Africa$fossil.sites,
                                    levels = c("MAMMALS", "Niger 885", "Nakalipithecus",
                                               "Samburupithecus", "Chororapithecus", "Sahelanthropus",
                                               "Lothagam", "Orrorin", "A. kadabba"))
colnames(sites_Africa)[4] <- "Late Miocene sites"

library(rgeos)
gnp <- data.frame(lon = c(34.5), lat = c(-19))
coordinates(gnp) <- ~ lon + lat
projection(gnp) <- "+init=epsg:4326"
gnp <- spTransform(gnp, CRS = CRS("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs"))

gap <- gBuffer(gnp, width = 1700000, quadsegs = 50) # width in meters thanks to projection above
gap <- spTransform(gap, CRS("+init=epsg:4326"))
gap <- fortify(gap)

afr <- c(left = -20, bottom = -36, right = 52, top = 40)

lbs <- c("MAMMALS", "Niger 885", expression(italic("Nakalipithecus")),
         expression(italic("Samburupithecus")), expression(italic("Chororapithecus")),
         expression(italic("Sahelanthropus")), expression(italic("Lothagam")),
         expression(italic("Orrorin")), expression(italic("A. kadabba")))

mapafrica <- ggmap(get_stamenmap(afr, zoom = 5, maptype = "terrain-background")) +
  geom_path(data = gap, aes(long, lat, group = group), color = "#f1c40f", size = 0.8) +
  geom_hline(yintercept = 0, linetype = "dotted", alpha = 0.4) +
  geom_hline(yintercept = 23.43667, linetype = "dotted", alpha = 0.2) +
  geom_hline(yintercept = -23.43667, linetype = "dotted", alpha = 0.2) +
  geom_point(
    data = sites_Africa,
    aes(x = lon, y = lat,
        colour = `Late Miocene sites`,
        shape = `Late Miocene sites`,
        size = `Late Miocene sites`,
        stroke = 0.8)) +
  scale_shape_manual(values = c(18, 1, 4, 2, 0, 1, 4, 2, 0), labels = lbs) +
  scale_colour_manual(values = c("#2c3e50", rep("#c0392b", 4), rep("#3498db", 4)), labels = lbs) +
  scale_size_manual(values = rep(2, 9), labels = lbs) +
  geom_rect(xmin = 33.75, xmax = 35.25, ymin = -20, ymax = -18, color = 'black', fill = '#8FD744FF', alpha = 0.1) +
  annotate("text", x = 34, y = -21.1, label = "Urema/Gorongosa", size = 3) +
  annotate("text", x = -3.5, y = -20, label = 'atop(bold("Southeast gap"))', color = "#f1c40f", parse = TRUE, size = 5.6) +
  annotate("text", x = -3.5, y = -22.5, label = 'atop(bold("radius = 1700 km"))', color = "#f1c40f", parse = TRUE, size = 4.4) +
  xlab("longitude") + ylab("latitude") + theme_minimal() + theme(legend.text.align = 0)

ggsave('FINAL_PAPER_00b.tiff', mapafrica, device = 'tiff', width = 6.5, height = 5.6, scale = 1, dpi = 'retina', type = "cairo")
# retain size at Saving 6.38 x 5.54 in image
#labels = c("Automatic", expression(italic("Manual")))
#######



moz <- c(left = 33.5, bottom = -20, right = 35.5, top = -17)
ggmap(get_stamenmap(moz, zoom = 9, maptype = "terrain")) +
  theme_minimal()

ggsave('FINAL_PAPER_00c.tiff', last_plot(), device = 'tiff', scale = 1, dpi = 'retina', type = "cairo")
