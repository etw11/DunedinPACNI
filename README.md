# DunedinPACNI
DunedinPACNI is novel brain-based aging biomarker of the pace of biological aging. DunedinPACNI scores represent the **speed** of aging, with higher scores indicating faster aging and lower scores indicating slower aging.

## Background
The DunedinPACNI algorithm was designed to predict the longitudinal [Pace of Aging phenotype](https://www.nature.com/articles/s43587-021-00044-4) in the Dunedin Study. Briefly, the Pace of Aging phenotype is a composite of decline in 19 biomarkers of 6 organ systems measured longitudinally as the cohort aged from 26 to 45 years old.

Using brain MRI scans from the Dunedin Study at age 45, we developed an algorithm to accurately estimate the Pace of Aging phenotype among Dunedin Study members. Specifically, the algorithm uses FreeSurfer-derived measures of cortical thickness, cortical surface area, cortical gray matter volume, cortical gray-white signal intensity ratio all according to the Desikan-Killiany parcellation and subcortical and cerebellar volumes according to the FreeSurfer ASEG output.

## How do we know DunedinPACNI works?
In our recent paper, we exported DunedinPACNI to three external neuroimaging samples (Human Connectome Project, Alzheimer's Disease Neuroimaging Initiative, and UK Biobank) to test the utility of DunedinPACNI in new data. We found that DunedinPACNI has excellent test-retest reliability, is associated with cognition, cognitive impairment, predicts cognitive decline, predicts hippocampal atrophy, predicts chronic disease onset, predicts death, and is associated with socioeconomic inequality.

## How to use this package
To estimate DunedinPACNI in new data, you will need brain MRI data parcellated using FreeSurfer. DunedinPACNI was developed using FreeSurfer v6.0, though the algorithm will work with other FreeSurfer versions. If you have .stats files output from FreeSurfer, this package will read in those files directly to R and format them appropriately.

If you do not have .stats output from FreeSurfer, you will need to format your data in a .csv file to be read into R.

You will also need a .csv files of all participant IDs.

# R package

**Installation**

You can install and load the DunedinPACNI package using the following code:
```
devtools::install_github("etw11/DunedinPACNI")
library(DunedinPACNI)
```

The R package for generating DunedinPACNI scores consists of two steps: LoadFreeSurferStats() and then ExportDunedinPACNI().

**LoadFreeSurferStats**

LoadFreeSurferStats() will directly read in a large number of .stats files to an R session and format them for the next step. If you have access to .stats files output from FreeSurfer, you can simply pass the path to those files to LoadFreeSurferStats() as shown below. You also need to pass the path of a .csv file with an ID list for your dataset.

```
LoadFreeSurferStats(fsdir = '/Users/ew198/Documents/data/freesurfer_stats/',
                    sublistdir = '/Users/ew198/Documents/data/')
```

This process may take a bit of time depending on the number of subjects you are reading in. For example, loading ~40,000 UK Biobank scans takes around 1 hour.

This function outputs a data.frame of formatted FreeSurfer phenotypes for all subjects.

**ExportDunedinPACNI**

ExportDunedinPACNI() applies the DunedinPACNI algorithm to your data and outputs DunedinPACNI scores for each scan. You can pass the output from LoadFreeSurferStats() directly to ExportDunedinPACNI().

If you are missing any ROIs in your data, you should pass a list of those ROIs to ExportDunedinPACNI() to have them imputed using the mean value from the Dunedin Study. Each missing ROI will slightly reduce the accuracy of resulting DunedinPACNI scores. Because the same value is being imputed for all subjects, imputed ROIs should have a uniform effect on DunedinPACNI scores in your sample, to preserve within-group comparisons. If you are missing >20% of the ROIs included in the DunedinPACNI algorithm, we think that is too much missingness to estimate DunedinPACNI and this function will throw an error.

Example without missing ROIs (default):
```
ExportDunedinPACNI(data = df,
                   modeldir = '/Users/ew198/Documents/data/model/',
                   outdir = '/Users/ew198/Documents/results/')
```

Example with missing ROIs:
```
ExportDunedinPACNI(data = df,
                   modeldir = '/Users/ew198/Documents/data/model/',
                   outdir = '/Users/ew198/Documents/results/',
                   missing_ROIs = c('GWR_parsopercularis_right', 'GWR_parsorbitalis_right'),
                   imputedir = '/Users/ew198/Documents/data/impute'))
```


