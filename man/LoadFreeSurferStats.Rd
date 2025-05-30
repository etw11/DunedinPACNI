% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/LoadFreeSurferStats.R
\name{LoadFreeSurferStats}
\alias{LoadFreeSurferStats}
\title{LoadFreeSurferStats}
\usage{
LoadFreeSurferStats(fsdir, sublist, missing_gwr)
}
\arguments{
\item{fsdir}{character string of the path to your FreeSurfer subjects directory. This folder should contain
each participant's subdirectory that contains their FreeSurfer output. Specifically, this function will read in files in the
<subject>/stats/ subdirectory.}

\item{sublist}{path and name of a .csv file with the participant ID list. This file should have one column with the header/first entry as "ID" and following
entries with each participant ID, matching the format from the FreeSurfer subjects directory.}

\item{missing_gwr}{(optional) TRUE/FALSE as to whether gray-white signal intensity ratio phenotypes are unavailable. Default is FALSE.}
}
\value{
The output of this function will be a data frame with regional FreeSurfer measures for each participant. Each row
    will have a unique participant and each column will have a different brain phenotype.
}
\description{
This function is used to quickly read and format FreeSurfer .stats files to R.
}
\details{
Written by Ethan Whitman (ethan.whitman@duke.edu)
}
\examples{
LoadFreeSurferStats(fsdir = '/Users/ew198/Documents/data/freesurfer_stats/',
                    sublist = '/Users/ew198/Documents/brainpace/data/sublist.csv')
}
