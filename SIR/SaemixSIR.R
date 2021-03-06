####################################################################################
####                         SaemixSIR class - definition                       ####
####################################################################################
#' Class "SaemixSIR"
#' 
#' An object of the SaemixSIR class, representing the results of a computation 
#' through the SIR algorithm of a SaemixObject.
#' 
#' 
#' 
#' @section Objects from the Class: 
#' An object of the SaemixSIR class can be created by using the function \code{\link{saemixSIR}} and contain the following slots:
#' @
#' 
#'  @section Methods:
#'   \describe{
#'     \item{initialize}{\code{signature(.Object = "SaemixSIR")}: internal function to initialise object, not to be used}
#'     \item{plot}{\code{signature(object = "SaemixSIR")} gives the 3 diagnostic plots (dOFV, spatial trends, temporal trends) }
#'     

setClass(Class="SaemixSIR",
  representation=representation(
    SaemixObject='SaemixObject', # SaemixObject with model, data and results
    M='numeric', #number of samples from the proposal distribution
    m='numeric', #number of resamples 
    est.mu='numeric', #vector of estimations of parameters
    prop.distr='matrix', #proposal distribution (can be covariance matrix, or another proposal distribution)
    inflation='numeric', #inflation coefficient
    inflprop.distr="matrix", #inflated covariance matrix = inflated proposal distribution
    name.param='character', #names of the estimated parameters
    optionll='character', #option for log-likelihood calculation
           
    #sampling
    sampled.theta='matrix', # samples from the proposal distribution
    samptries='numeric', #number of tries fro sampling (to be compared to M)
    #IR
    OFVi='numeric', #vector of OFVs of the sampled.theta
    IR='numeric', # vector of importance ratios for each vector of parameter sample
    #resampling
    resampled.theta='matrix',
    resamples.order='numeric',#a vector with id number of sampled vectors that are resampled (in order of resampling)
    sdSIR='numeric',
    
    warnings='logical' 
    
  ),
  validity=function(object){
    
    validObject(object@SaemixObject)
    if (inflation <0){
      message("[ inflation : Error ] inflation coefficient must be positive")
      return("negative inflation")
    }
    return(TRUE)
  }
)

###############################
# Initialize

#' @rdname initialize-methods
#' 
#' @param SaemixObject a SaemixObject from which the algorithm SIR is computed
#' @param M number of samples from the proposal distribution
#' @param m number of resamples
#' @param inflation inflation coefficient
#' @param est.mu a vector of the estimated parameters
#' @param prop.distr proposal distribution of parameters (covariance matrix or other)
#' @param optionll option for log-likelihood computation
#' @param warnings option for warnings printing
#' 
#' @exportMethod initialize

setMethod(
  f="initialize",
  signature="SaemixSIR",
  definition= function(.Object, SaemixObject, M, m, inflation, est.mu, prop.distr, optionll, warnings){
    #    cat ("--- initialising SaemixSIR Object --- \n")
    if(missing(SaemixObject)) {
      message('[SaemixObject: Error] Missing SaemixObject.')
      return(.Object)
    }
    .Object@SaemixObject <- SaemixObject
    if(missing(M)) M<-5000
    .Object@M <- M
    if(missing(m)) m<-1000
    .Object@m <- m 
    if (M<m) {
      message("[ M and m: Error] M (number of samples from proposal distribution) must be greater than m (number of resamples).")
      return(.Object)
    }
    if(missing(inflation)) inflation <- 1
    .Object@inflation<-inflation
    
    
    est <- estpar.vector(SaemixObject)
    l <- length(est)
    if(missing(est.mu)) est.mu <- estpar.vector(SaemixObject)
    if (length(est.mu)!=l) {
      message("[est.mu: Error] Length of est.mu is not equal to number of estimated parameters in SaemixObject.")
      return(.Object)
    }
    .Object@est.mu <- est.mu
    
    
    if(missing(prop.distr)) prop.distr <- solve(SaemixObject@results@fim)
    if(dim(prop.distr)[1]!=dim(prop.distr)[2]){
      message("[prop.distr: Error] Proposal distribution is not a square matrix.")
      return(.Object)
    }
    if(dim(prop.distr)[1]!=l){
      message("[prop.distr: Error] Proposal distribution does not have the right dimensions (number of columns and rows should be equal to the number of estimated parameters)")
      return(.Object)
    }
    .Object@prop.distr <- prop.distr
    
    
    .Object@inflprop.distr <- inflation*prop.distr
    
    .Object@sampled.theta <- matrix()
    .Object@samptries <- 0
    .Object@OFVi <- numeric(0)
    .Object@IR <- numeric(0)
    .Object@resampled.theta <- matrix()
    .Object@resamples.order <- numeric(0)
    .Object@sdSIR <- numeric(0)
    
    if(missing(warnings)) warnings<-TRUE
    .Object@warnings <- warnings
    
   
    name.fixed <- SaemixObject@model@name.fixed #name of fixed effects
    name.covomega <- name.covomega(SaemixObject)
    indx.res <- SaemixObject@results@indx.res
    name.sigma <- SaemixObject@model@name.sigma[indx.res]
    
    name.param <- c(name.fixed, name.covomega, name.sigma)
    name.param <- name.param[1:length(est.mu)]
    .Object@name.param <- name.param
    names(.Object@est.mu) <- name.param
    
    
    #    if(missing()) <-
    #    .Object@<-
    
    if(missing(optionll)) optionll <- 'importance_sampling'
    if(!(optionll %in% c('importance_sampling', 'gaussian_quadrature'))){
      message("[optionll: Error] Option of log-likelihood computation not available")
      return(.Object)
    }
    .Object@optionll <- optionll
    
  
    return (.Object)
  }
)



####################################################################################
####                        SaemixSIR class - accesseur                         ####
####################################################################################

#' Get/set methods for SaemixModel object
#' 
#' Access slots of a SaemixModel object using the object["slot"] format
#' 
#' @param x object
#' @param i element to be replaced
#' @param j element to replace with
#' @param drop whether to drop unused dimensions
#' @keywords methods
#' @exportMethod [
#' @exportMethod [<-


# Getteur
setMethod(
  f ="[",
  signature = "SaemixSIR" ,
  definition = function (x,i,j,drop ){
    switch (EXPR=i,
            "SaemixObject"={return(x@SaemixObject)},
            "M"={return(x@M)},
            "m"={return(x@m)},
            "est.mu"={return(x@est.mu)},
            "prop.distr"={return(x@prop.distr)},
            "name.param"={return(x@name.param)},
            "optionll"={return(x@optionll)},
            "inflation"={return(x@inflation)},
            "inflprop.distr"={return(x@inflprop.distr)},
            "sampled.theta"={return(x@sampled.theta)},
            "OFVi"={return(x@OFVi)},
            "IR"={return(x@IR)},
            "resampled.theta"={return(x@resampled.theta)},
            "resamples.order"={return(x@resamples.order)},
            "sdSIR"={return(x@sdSIR)},
            "warnings"={return(x@warnings)},

            stop("No such attribute\n")
    )
  }
)

###################################################################################


####################################################################################
####				SaemixSIR class - summary method			####
####################################################################################
#' @rdname summary-methods
#' 
#' @exportMethod summary

setMethod("summary","SaemixSIR",
          function(object, print=TRUE, ...) {
            if(length(object@resampled.theta)==0) {
              cat("Object of class SaemixSIR, no SIR computed yet.\n")
              return()
            }
            
            M <- object@M
            m <- object@m
            infl <- object@inflation
            optionll <- object@optionll
            name.param <- object@name.param
            prop.distr <- object@prop.distr
            est.mu <- object@est.mu
            sdSIR <- object@sdSIR
            
            if(print) {
              cat("----------------------------------------------------\n")
              cat("-----------------  Options of SIR  -----------------\n")
              cat("----------------------------------------------------\n")
              cat("M (number of samples) =", M, "\n")
              cat("m (number of resamples) =", m, "\n")
              cat("inflation =", infl, "\n")
              cat("log-likelihood computation method =", optionll, "\n")
            }
            
            if(print){
              cat("----------------------------------------------------\n")
              cat("-----------------  Results of SIR  -----------------\n")
              cat("----------------------------------------------------\n")
              sd <- sqrt(diag(prop.distr))
              tab <- rbind(est.mu, sd,sdSIR)
              colnames(tab)<- name.param
              row.names(tab)<- c('Estimated parameters', 'Standard deviation before SIR','Standard deviation after SIR')
              print(tab)
            }
          
          }

)
