% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{print.transreg}
\alias{print.transreg}
\title{Print transreg-object}
\usage{
\method{print}{transreg}(x, ...)
}
\arguments{
\item{x}{object of class transreg}

\item{...}{(not applicable)}
}
\value{
Returns family of distributions,
elastic net mixing parameter (\eqn{alpha}),
number of samples (\eqn{n}),
number of features (\eqn{p}),
number of sources of co-data (\eqn{k}),
chosen calibration method (exponential or isotonic),
and chosen stacking method (standard or simultaneous).
}
\description{
Show summary of transreg-object
}
\examples{
#--- simulation ---
set.seed(1)
n <- 100; p <- 500
X <- matrix(rnorm(n=n*p),nrow=n,ncol=p)
beta <- rnorm(p)
prior <- beta + rnorm(p)
y <- X \%*\% beta

#--- print.transreg  ---
object <- transreg(y=y,X=X,prior=prior)
object

}
