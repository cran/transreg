% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{calibrate}
\alias{calibrate}
\alias{.exp.multiple}
\alias{.iso.multiple}
\alias{.iso.fast.single}
\alias{.iso.slow.single}
\title{Internal functions}
\usage{
.exp.multiple(
  y,
  X,
  prior,
  family,
  switch = FALSE,
  select = TRUE,
  track = FALSE
)

.iso.multiple(
  y,
  X,
  prior,
  family,
  switch = FALSE,
  select = TRUE,
  track = FALSE
)

.iso.fast.single(y, X, prior, family)

.iso.slow.single(y, X, prior, family)
}
\arguments{
\item{y}{target: vector of length \eqn{n} (see \code{family})}

\item{X}{features: matrix with \eqn{n} rows (samples)
and \eqn{p} columns (features)}

\item{prior}{prior coefficients: matrix with \eqn{p} rows (features)
and \eqn{k} columns (sources of co-data)}

\item{family}{character "gaussian" (\eqn{y}: real numbers),
"binomial" (\eqn{y}: 0s and 1s),
or "poisson" (\eqn{y}: non-negative integers);}

\item{switch}{choose between positive and negative weights for each source: logical}

\item{select}{select from sources: logical}

\item{track}{show intermediate output (messages and plots): logical}
}
\description{
Internal functions called by
[transreg()],
depending on choice between
exponential and isotonic calibration.
}
\section{Functions}{
\itemize{
\item \code{.exp.multiple()}: called by `transreg` if `scale="exp"`

\item \code{.iso.multiple()}: called by `transreg` if `scale="iso"`

\item \code{.iso.fast.single()}: called by `transreg` if `scale="iso"` (via `.iso.multiple`)

\item \code{.iso.slow.single()}: replaced by `.iso.fast.single`

}}
\seealso{
Use [transreg()] for model fitting.
}
