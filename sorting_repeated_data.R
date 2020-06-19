coords <- coords[coords$`Fossil sites` != 'Non-localities' & coords$`Fossil sites` != 'Non-localities 18',]
coords_NOT <- coords_NOT[coords_NOT$Long > zone@xmin & coords_NOT$Long < zone@xmax &
                           coords_NOT$Lat > zone@ymin & coords_NOT$Lat < zone@ymax,]

newdf1 <- round(coords_NOT[2:3], -2)
newdf2 <- round(coords[2:3], -2)
newdf1$coder <- "A"
newdf2$coder <- "B"

df <- rbind(newdf1, newdf2)

findDuplicates <- function (df, idcol) { 
  # Get the data columns to use for finding matches
  datacols <- setdiff(names(df), idcol) 
  # Sort by idcol, then datacols. Save order so we can undo the sorting later.
  sortorder <- do.call(order, df)
  df <- df[sortorder,] 
  # Find duplicates within each id group (first copy not marked)
  dupWithin <- duplicated(df) 
  # With duplicates within each group filtered out, find duplicates between groups. 
  # Need to scan up and down with duplicated() because first copy is not marked.
  dupBetween = rep(NA, nrow(df))
  dupBetween[!dupWithin] <- duplicated(df[!dupWithin,datacols])
  dupBetween[!dupWithin] <- duplicated(df[!dupWithin,datacols], fromLast = TRUE) | dupBetween[!dupWithin] 
  # ============= Replace NA's with previous non-NA value ==============
  # This is why we sorted earlier - it was necessary to do this part efficiently 
  # Get indexes of non-NA's
  goodIdx <- !is.na(dupBetween)  
  # These are the non-NA values from x only
  # Add a leading NA for later use when we index into this vector
  goodVals <- c(NA, dupBetween[goodIdx]) 
  # Fill the indices of the output vector with the indices pulled from
  # these offsets of goodVals. Add 1 to avoid indexing to zero.
  fillIdx <- cumsum(goodIdx) + 1  
  # The original vector, now with gaps filled
  dupBetween <- goodVals[fillIdx] 
  # Undo the original sort
  dupBetween[sortorder] <- dupBetween  
  # Return the vector of which entries are duplicated across groups
  return(dupBetween)
}

dupRows <- findDuplicates(df, "coder")
dfDup <- cbind(df, dup = dupRows)
dfA <- subset(dfDup, coder == "A", select = -coder)
dfB <- subset(dfDup, coder == "B", select = -coder)
coords_ESC <- dfA[dfA$dup == F,]
coords_ESC <- coords_ESC[, -3]
coords_NOT <- coords_NOT[rownames(coords_ESC),]
