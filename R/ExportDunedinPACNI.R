#' ExportDunedinPACNI
#'
#' This function is used to estimate DunedinPACNI scores from FreeSurfer output.
#' 
#' Written by Ethan Whitman (ethan.whitman@duke.edu)
#'  
#' @param data Data.frame with the output of LoadFreeSurferStats().
#' 
#' @param modeldir Character string of the path to the directory where the DunedinPACNI model coefficients are saved.
#'
#' @param outdir Character string of the path to the desired output directory. 
#' 
#' @param missing_ROIs (optional) Character vector of ROIs that you do not have in your data. ROI names should be formatted according to conventions
#'     output from LoadFreeSurferStats(). Default is NULL.
#'     
#'     IF YOU HAVE MISSING ROIS: this may reduce the accuracy of the output DunedinPACNI scores. Not all ROIs are included in the final model,
#'     this function will automatically list the ROIs you are missing that will directly impact scores.
#
#'     If you are missing ROIs that are included in the DunedinPACNI algorithm, we will automatically impute the mean value from the Dunedin Study
#'     for that ROI. Each imputed ROI will slightly decrease the accuracy of the overall estimates, so having a lot of missing ROIs reduces 
#'     confidence in the scores. Also bear in mind, the Dunedin Study is a cohort of 45-year-olds, so missing ROIs (i.e. imputed ROIs) may have
#'     more dramatic effects in datasets that differ substantially in age from the Dunedin Study members.
#'
#'     This command will throw an error if you are missing more than >20 percent of the ROIs needed for the DunedinPACNI algorithm
#' 
#' @param imputedir (optional) Character string of the path to the directory where the mean values from the Dunedin Study are saved. You only need
#'    this argument if you are missing ROIs. Default is NULL.
#'    
#' @return The output of this function will be a data.frame with DunedinPACNI scores for your dataset. This function will also automatically save this object to an .Rdata file labeled:
#' 
#'       <outdir>/<date and time>_df_pacni.Rdata
#' @examples 
#' ExportDunedinPACNI(data = df,
#'                    modeldir = '/Users/ew198/Documents/brainpace/scripts/pacni_package/',
#'                    outdir = '/Users/ew198/Documents/brainpace/scripts/pacni_package/')
#' 
#' ExportDunedinPACNI(data = df,
#'                    modeldir = '/Users/ew198/Documents/brainpace/scripts/pacni_package/',
#'                    outdir = '/Users/ew198/Documents/brainpace/scripts/pacni_package/',
#'                    missing_ROIs = c('GWR_parsopercularis_right', 'GWR_parsorbitalis_right'),
#'                    imputedir = '/Users/ew198/Documents/brainpace/results/impute/')
#' @export

ExportDunedinPACNI <- function(data,
                               modeldir,
                               outdir,
                               missing_ROIs,
                               imputedir, 
                               missing_gwr){

  # setting default settings
     
   if (!missing(missing_ROIs) && missing(imputedir)){
     stop("you indicated that you are missing ROIs but did not add the path to the Dunedin Study means. 
          need to add an argument for imputedir for ROI imputation")
   } else if (missing(missing_ROIs) && missing(imputedir)){
     missing_ROIs <- NULL
     imputedir <- NULL
   }
  
  
  if (missing(missing_gwr)){
    missing_gwr <- FALSE
  }

  library(ggplot2)
  library(gridExtra)
  library(ggseg)
  
   # fix column names
   data_remove_cols <- !grepl("hypointensities_|non-WM-hypointensities_", colnames(data))
   data <- data[,data_remove_cols]

   # order data columns
   data <- data[,order(colnames(data))]
    
   # remove punctuation differences
   colnames(data) <- gsub("[-.]", "", colnames(data))

   # order
   data <- data[,order(colnames(data))]
   data <- data[, c(setdiff(names(data), c("ID")), c("ID"))]
  
  if (!is.null(missing_ROIs)){
    
    # fix punctuation
    missing_ROIs <- gsub("[-.]", "", missing_ROIs)
    
    load(paste0(imputedir, 'dunedin_dk_gwr_means.Rdata'))
    
    # fix punctuation
    names(dunedin_dk_gwr_means) <- gsub("[-.]", "", names(dunedin_dk_gwr_means))
    
    ROIs_to_impute <- dunedin_dk_gwr_means[which(names(dunedin_dk_gwr_means) %in% missing_ROIs)]
    ROIs_to_impute_df <- t(data.frame(ROIs_to_impute))
    ROIs_to_impute_rep <- ROIs_to_impute_df[rep(seq_len(nrow(ROIs_to_impute_df)), nrow(data)), ]
    rownames(ROIs_to_impute_rep) <- NULL
    
    data <- cbind(data, ROIs_to_impute_rep)
    
    # reorder columns with imputed ROIs
    data <- data[,order(colnames(data))]
    data <- data[, c(setdiff(names(data), c("ID")), c("ID"))]
    }
  
  # load in model weights for PACNI algorithm
   if (missing_gwr == FALSE){
     load(paste0(modeldir,'coefs_dk_gwr.Rdata'))
     coefs <- coefs_dk_gwr
   } else if (missing_gwr == TRUE){
     load(paste0(modeldir,'coefs_dk.Rdata'))
     coefs <- coefs_dk
   }
   
  # order variables
  coefs <- coefs[order(names(coefs))]
  
  # add column for pacni scores
  data$pacni <- rep(NA, nrow(data))
  
  # remove punctuation differences
  names(coefs) <- gsub("[-.]", "", names(coefs))
  
  if (!is.null(missing_ROIs)){
    missing_ROIs <- gsub("[-.]", "", missing_ROIs)
    pacni_ROIs <- names(coefs[coefs!=0])
    
    # list which missing ROIs have weights in the actual PACNI algorithm
    missing_pacni_ROIs <- missing_ROIs[missing_ROIs %in% pacni_ROIs]
    missing_pacni_percent <- round(100*length(missing_pacni_ROIs)/(length(pacni_ROIs)-1),2)
    
    if (missing_pacni_percent < 20){
      
      warning(paste0("you are missing ", missing_pacni_percent, "% of ROIS included in the DunedinPACNI algorithm.
      Values for these ROIs have been imputed with the mean values from the Dunedin Study.

      ** This will reduce the accuracy of your predictions ** - potentially a lot depending on how dissimilar
      your participants are to the Dunedin Study members.
      
      If you have a lot of missingness, we recommend checking your FreeSurfer output to see if you can recover any of this data.
      If not, you might consider more sophisticated imputation techniques:
      https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6829024/"))
      
    } else if (missing_pacni_percent >= 20){
      
      stop(paste0("YOU ARE MISSING ", missing_pacni_percent, "% OF ROIS INCLUDED IN THE DUNEDINPACNI ALGORITHM.
      
      ** THIS IS TOO MUCH MISSINGNESS TO ESTIMATE DUNEDINPACNI ***
      
      We recommend checking your FreeSurfer output to see whether you can recover any of this data.
      If not, you. might consider more sophisticated imputation techniques:
      https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6829024/"))
    }
    
  }
  
  if (all(names(coefs)[2:length(names(coefs))] == colnames(data)[1:(ncol(data)-2)]) != TRUE){
    coefs_names <- names(coefs)[2:length(names(coefs))]
    data_names <- colnames(data)[1:(ncol(data)-2)]
    
    if (length(data_names) > length(coefs_names)){
      cat("\033[31myou have some variables in your data that we dont have in the DunedinPACNI algorithm. specifically:\033[0m\n")
      print(data_names[!(data_names %in% coefs_names)])
      cat("please remove these variables from your data to continue \n")
    } else if (length(data_names) < length(coefs_names)){
      cat("\033[31myou are missing some variables in your data that we have in the DunedinPACNI algorithm. specifically:\033[0m\n")
      print(coefs_names[!(coefs_names %in% data_names)])
      cat("please add these variables to your data to continue \n")
    }
      
      
    stop('**** FREESURFER VARIABLES ARE MISALIGNED ****
         
         see list of misaligned variables above
           
           possible ways to fix this:
           -make sure that your data is in the Desikan-Killiany parcellation
           -check whether you are missing any FreeSurfer ROIs. if so, indicate which ones in the option "missing_ROIs"
           -make sure the names of your ROIs from LoadFreeSurferStats() differ from the names of Dunedin ROIs')
  }
  
  # loop through participants and apply the weights to each person's brain features to yield an estimate of their PACNI score
  x<-1
  for (s in 1:nrow(data)){
    suppressWarnings({
      data$pacni[x] <- sum(as.numeric(data[s,])[1:c(ncol(data)-2)]*as.numeric(coefs)[2:length(coefs)], coefs[1], na.rm=T)
    })
    x<-x+1
  }
  df_pacni <- data[,c('ID', 'pacni')]
  
  # save out
  outname <- paste0(gsub(" ", "_", gsub(":","_",date())), "_", round(runif(1,100,999),0))
  save(df_pacni, file = paste0(outdir, outname, '_df_pacni', '.Rdata'))
  
  return(df_pacni)
}



