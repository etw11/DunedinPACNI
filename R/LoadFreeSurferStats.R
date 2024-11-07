#' LoadFreeSurferStats
#'
#' This function is used to quickly read and format FreeSurfer .stats files to R. 
#' 
#' Written by Ethan Whitman (ethan.whitman@duke.edu)
#' 
#' @param fsdir character string of the path to your FreeSurfer subjects directory. This folder should contain
#'     each participant's subdirectory that contains their FreeSurfer output. Specifically, this function will read in files in the
#'     <subject>/stats/ subdirectory.
#'
#' @param sublist path and name of a .csv file with the participant ID list. This file should have one column with the header/first entry as "ID" and following
#'        entries with each participant ID, matching the format from the FreeSurfer subjects directory.
#'     
#' @param missing_gwr (optional) TRUE/FALSE as to whether gray-white signal intensity ratio phenotypes are unavailable. Default is FALSE.
#' 
#' @return The output of this function will be a data frame with regional FreeSurfer measures for each participant. Each row
#'     will have a unique participant and each column will have a different brain phenotype.
#'
#' @examples 
#' LoadFreeSurferStats(fsdir = '/Users/ew198/Documents/data/freesurfer_stats/',
#'                     sublist = '/Users/ew198/Documents/brainpace/data/sublist.csv')
#' @import progress
#' @export

LoadFreeSurferStats <- function(fsdir, 
                                sublist,
                                missing_gwr){
  
  # setting default settings
  if (missing(missing_gwr)){
    missing_gwr <- FALSE
  }
  
  # add missing "/" to paths just in case
  if (substring(fsdir,nchar(fsdir)) != "/"){
    fsdir <- paste0(fsdir, "/")
  }
  
  # load ID list and remove trailing "/" if there is one
  idlist <- read.csv(paste0(sublist))$ID
  if ("/" %in% substring(idlist,nchar(idlist))){
    idlist <- gsub("/", "", idlist)
  }
  
  # use first participant to make label
  example_sub <- idlist[1]
    
    # load and format data from freesurfer to set up empty object for everyone
    
    aseg <- read.table(paste0(fsdir, example_sub, '/stats/aseg.stats'))
    lh_aparc <- read.table(paste0(fsdir, example_sub, '/stats/lh.aparc.stats'))
    rh_aparc <- read.table(paste0(fsdir, example_sub, '/stats/rh.aparc.stats'))
    if (missing_gwr == FALSE){
      lh_wg <- read.table(paste0(fsdir, example_sub, '/stats/lh.w-g.pct.stats'))
      rh_wg <- read.table(paste0(fsdir, example_sub, '/stats/rh.w-g.pct.stats'))
    }

    # label hemispheres
    
    lh_aparc$label <- paste0(lh_aparc$V1, '_left')
    rh_aparc$label <- paste0(rh_aparc$V1, '_right')
    if (missing_gwr == FALSE){
      lh_wg$label <- paste0(lh_wg$V5, '_left')
      rh_wg$label <- paste0(rh_wg$V5, '_right')
    }

    # label phenotypes 
    aseg_temp <- t(aseg[,c('V5', 'V6')])
    aseg_temp[1,] <- gsub("^(Right|Left)-(.*)$", "\\2_\\1", aseg_temp[1,])
    aseg_temp[1,] <- gsub("3rd-Ventricle", "X3rd.Ventricle", aseg_temp[1,])
    aseg_temp[1,] <- gsub("4th-Ventricle", "X4th.Ventricle", aseg_temp[1,])
    aseg_temp[1,] <- gsub("5th-Ventricle", "X5th.Ventricle", aseg_temp[1,])
    
    surfarea_temp <- cbind(t(lh_aparc[,c('label', 'V3')]),
                           t(rh_aparc[,c('label', 'V3')]))
    surfarea_temp[1,] <- paste0('SA_',surfarea_temp[1,])
    
    thickavg_temp <-  cbind(t(lh_aparc[,c('label', 'V5')]),
                            t(rh_aparc[,c('label', 'V5')]))
    thickavg_temp[1,] <- paste0('CT_',thickavg_temp[1,])
    
    grayvol_temp <-  cbind(t(lh_aparc[,c('label', 'V4')]),
                           t(rh_aparc[,c('label', 'V4')]))
    grayvol_temp[1,] <- paste0('GMV_',grayvol_temp[1,])
    
    if (missing_gwr == FALSE){
      wg_temp <-  cbind(t(lh_wg[,c('label', 'V6')]),
                      t(rh_wg[,c('label', 'V6')]))
      wg_temp[1,] <- paste0('GWR_',wg_temp[1,])
    }

    # combine into one object
    if (missing_gwr == FALSE){
      labels <- cbind('ID', aseg_temp, surfarea_temp, thickavg_temp, grayvol_temp, wg_temp)[1,]
    } else if (missing_gwr == TRUE){
      labels <- cbind('ID', aseg_temp, surfarea_temp, thickavg_temp, grayvol_temp)[1,]
    }
    
    data <- data.frame(matrix(ncol=length(labels), nrow = length(idlist)))
    colnames(data) <- labels
    
    # load everyone at once
    x <- 1
    asegs <- vector(mode = 'list', length = length(idlist))
    lh_aparcs <- vector(mode = 'list', length = length(idlist))
    rh_aparcs <- vector(mode = 'list', length = length(idlist))
    if (missing_gwr == FALSE){
      lh_wgs <- vector(mode = 'list', length = length(idlist))
      rh_wgs <- vector(mode = 'list', length = length(idlist))
    }
    # set up progress bar
    pb <- progress_bar$new(format = "[:bar] Reading FreeSurfer file :current/:total (:percent), eta: :eta", total = length(idlist))
    for (sub in idlist){
      pb$tick()
      Sys.sleep(1 / 100)
      asegs[[x]] <- read.table(paste0(fsdir, sub, '/stats/aseg.stats'))
      lh_aparcs[[x]] <- read.table(paste0(fsdir, sub, '/stats/lh.aparc.stats'))
      rh_aparcs[[x]] <- read.table(paste0(fsdir, sub, '/stats/rh.aparc.stats'))
      if (missing_gwr == FALSE){
        lh_wgs[[x]] <- read.table(paste0(fsdir, sub, '/stats/lh.w-g.pct.stats'))
        rh_wgs[[x]] <- read.table(paste0(fsdir, sub, '/stats/rh.w-g.pct.stats'))
      }
      x <- x+1
    }
    
    print('Formatting data...')
    
    # load labels
    aseg_txt <- readLines(file(paste0(fsdir, sub, '/stats/aseg.stats')))
    aseg_colheaders <- c(strsplit(aseg_txt[grep('# ColHeaders', aseg_txt)], "\\s+")[[1]])
    lh_aparc_txt <- readLines(file(paste0(fsdir, sub, '/stats/lh.aparc.stats')))
    lh_aparc_colheaders <- c(strsplit(lh_aparc_txt[grep('# ColHeaders', lh_aparc_txt)], "\\s+")[[1]])
    rh_aparc_txt <- readLines(file(paste0(fsdir, sub, '/stats/rh.aparc.stats')))
    rh_aparc_colheaders <- c(strsplit(rh_aparc_txt[grep('# ColHeaders', rh_aparc_txt)], "\\s+")[[1]])
    if (missing_gwr == FALSE){
      lh_wg_txt <- readLines(file(paste0(fsdir, sub, '/stats/lh.w-g.pct.stats')))
      lh_wg_colheaders <- c(strsplit(lh_wg_txt[grep('# ColHeaders', lh_wg_txt)], "\\s+")[[1]])
      rh_wg_txt <- readLines(file(paste0(fsdir, sub, '/stats/rh.w-g.pct.stats')))
      rh_wg_colheaders <- c(strsplit(rh_wg_txt[grep('# ColHeaders', rh_wg_txt)], "\\s+")[[1]])
    }
    
    # rename 
    y <- 1
    for (sub in idlist){
      aseg <- asegs[[y]]
      colnames(aseg) <- aseg_colheaders[3:length(aseg_colheaders)]
      
      lh_aparc <- lh_aparcs[[y]]
      colnames(lh_aparc) <- lh_aparc_colheaders[3:length(lh_aparc_colheaders)]
      
      rh_aparc <- rh_aparcs[[y]]
      colnames(rh_aparc) <- rh_aparc_colheaders[3:length(rh_aparc_colheaders)]    
      
      if (missing_gwr == FALSE){
        lh_wg <- lh_wgs[[y]]
        colnames(lh_wg) <- lh_wg_colheaders[3:length(lh_wg_colheaders)]
      
        rh_wg <- rh_wgs[[y]]
        colnames(rh_wg) <- rh_wg_colheaders[3:length(rh_wg_colheaders)] 
      }
      
      # label hemispheres
      
      lh_aparc$StructName <- paste0(lh_aparc$StructName, '_left')
      rh_aparc$StructName <- paste0(rh_aparc$StructName, '_right')
      if (missing_gwr == FALSE){
        lh_wg$StructName <- paste0(lh_wg$StructName, '_left')
        rh_wg$StructName <- paste0(rh_wg$StructName, '_right')
      }
      
      # label phenotypes 
      aseg_temp <- t(aseg[,c('StructName', 'Volume_mm3')])
      aseg_temp[1,] <- gsub("^(Right|Left)-(.*)$", "\\2_\\1", aseg_temp[1,])
      aseg_temp[1,] <- gsub("3rd-Ventricle", "X3rd.Ventricle", aseg_temp[1,])
      aseg_temp[1,] <- gsub("4th-Ventricle", "X4th.Ventricle", aseg_temp[1,])
      aseg_temp[1,] <- gsub("5th-Ventricle", "X5th.Ventricle", aseg_temp[1,])
      
      
      surfarea_temp <- cbind(t(lh_aparc[,c('StructName', 'SurfArea')]),
                             t(rh_aparc[,c('StructName', 'SurfArea')]))
      surfarea_temp[1,] <- paste0('SA_',surfarea_temp[1,])
      
      thickavg_temp <-  cbind(t(lh_aparc[,c('StructName', 'ThickAvg')]),
                              t(rh_aparc[,c('StructName', 'ThickAvg')]))
      thickavg_temp[1,] <- paste0('CT_',thickavg_temp[1,])
      
      grayvol_temp <-  cbind(t(lh_aparc[,c('StructName', 'GrayVol')]),
                             t(rh_aparc[,c('StructName', 'GrayVol')]))
      grayvol_temp[1,] <- paste0('GMV_',grayvol_temp[1,])
      
      if (missing_gwr == FALSE){
        wg_temp <-  cbind(t(lh_wg[,c('StructName', 'Mean')]),
                         t(rh_wg[,c('StructName', 'Mean')]))
        wg_temp[1,] <- paste0('GWR_',wg_temp[1,])
      }
      
      if (missing_gwr == FALSE){
        data_temp <- cbind(c('ID',paste0(sub)), aseg_temp, surfarea_temp, thickavg_temp, grayvol_temp, wg_temp)
      } else if (missing_gwr == TRUE){
        data_temp <- cbind(c('ID',paste0(sub)), aseg_temp, surfarea_temp, thickavg_temp, grayvol_temp)
      }
      
      colnames(data_temp) <- data_temp[1,]
      rownames(data_temp) <- c('label', 'value')
      
      if (ncol(data_temp) == ncol(data)){
        data[y,] <- data_temp[2,]
      } else if (ncol(data_temp) < ncol(data)){
        data[y,] <- c(sub, rep(NA, 319))
        print(paste0('sub ', paste0(sub), ' missing some ROIs'))
      }
      y <- y+1
      
    }
  
  # check for missing data
    
  if (sum(colSums(is.na(data))[colSums(is.na(data)) != 0]) == 0){
    print('Looks like you have no missing data. Great!')
  } else if (sum(colSums(is.na(data))[colSums(is.na(data)) != 0]) > 0){
    
    cat("\033[31mLooks like you have some missing data. Here is the N missing values from your data:\033[0m\n")
    print(colSums(is.na(data))[colSums(is.na(data)) != 0])
    
    cat("\033[If you have certain ROIs with high incidences of missingness, you could
    consider just excluding those ROIs. If you do this (or have missing ROIs for some other reason), 
    we will automatically impute with data from the Dunedin Study in our DunedinPACNI estimates.
    BEAR IN MIND: imputing ROI data from the Dunedin Study will worsen the accuracy of 
    DunedinPACNI estimates.\033[0m\n")
  }
  
  data <- data %>% mutate_at(c(2:320), as.numeric)
  return(data)
 
}

