% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/folds.R
\name{BlockedCrossValidation}
\alias{BlockedCrossValidation}
\title{BlockedCrossValidation}
\usage{
BlockedCrossValidation(blockVar, balance = FALSE, bootstrap = FALSE)
}
\arguments{
\item{blockVar}{an integer vector of indicating the cross-vlaidation blocks. Each block is indicating by an unique integer.}

\item{balance}{logical indicating whether cross-validation blocks should automatically balanced, using undersampling if necessary.}

\item{bootstrap}{logical indicating whether training samples should be sampled with replacement.}
}
\description{
construct a cross-validation specification
}

