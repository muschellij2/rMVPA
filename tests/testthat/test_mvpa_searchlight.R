library(neuroim)


gen_regression_dataset <- function(D, nobs, spacing=c(1,1,1), folds=5) {
  mat <- array(rnorm(prod(D)*nobs), c(D,nobs))
  bspace <- BrainSpace(c(D,nobs), spacing)
  bvec <- BrainVector(mat, bspace)
  mask <- as.logical(BrainVolume(array(rep(1, prod(D)), D), BrainSpace(D, spacing)))
  Y <- rnorm(nobs)
  blockVar <- rep(1:folds, length.out=nobs)
  MVPADataset$new(trainVec=bvec, Y=Y, mask=mask, blockVar=blockVar, testVec=NULL, testY=NULL)
}

gen_dataset <- function(D, nobs, nlevels, spacing=c(1,1,1), folds=5) {
  
  mat <- array(rnorm(prod(D)*nobs), c(D,nobs))
  bspace <- BrainSpace(c(D,nobs), spacing)
  bvec <- BrainVector(mat, bspace)
  mask <- as.logical(BrainVolume(array(rep(1, prod(D)), D), BrainSpace(D, spacing)))
  Y <- sample(factor(rep(letters[1:nlevels], length.out=nobs)))
  blockVar <- rep(1:folds, length.out=nobs)
  
  
  MVPADataset$new(trainVec=bvec, Y=Y,mask=mask, blockVar=blockVar, testVec=NULL, testY=NULL, 
                  trainDesign=data.frame(Y=Y), testDesign=data.frame(Y=Y))
}

gen_surface_dataset <- function(nobs, nlevels, folds=5) {
  library(neuroim)
  fname <- system.file("extdata/std.lh.smoothwm.asc", package="neuroim")
  geom <- loadSurface(fname)
  nvert <- nrow(vertices(geom))
  mat <- matrix(rnorm(nvert*nobs), nvert, nobs)
  
  bvec <- BrainSurfaceVector(geom, 1:nvert, mat)
  Y <- sample(factor(rep(letters[1:nlevels], length.out=nobs)))
  blockVar <- rep(1:folds, length.out=nobs)
  
  dataset <- MVPASurfaceDataset$new(
                                    trainVec=bvec, 
                                    Y=Y, mask=indices(bvec), 
                                    blockVar=blockVar, 
                                    trainDesign=data.frame(Y=Y), 
                                    testDesign=data.frame(Y=Y))
  
  
}

gen_dataset_with_test <- function(D, nobs, nlevels, spacing=c(1,1,1), folds=5, splitvar=TRUE) {
  mat <- array(rnorm(prod(D)*nobs), c(D,nobs))
  bspace <- BrainSpace(c(D,nobs), spacing)
  bvec <- BrainVector(mat, bspace)
  mask <- as.logical(BrainVolume(array(rep(1, prod(D)), D), BrainSpace(D, spacing)))
  Y <- sample(factor(rep(letters[1:nlevels], length.out=nobs)))
  
  blockVar <- rep(1:folds, length.out=nobs)
  if (splitvar) {
    tsplit <- factor(rep(1:5, length.out=length(Y)))
    testSplits <- split(1:length(Y), tsplit)
    MVPADataset$new(trainVec=bvec, Y=Y, testVec=bvec, testY=Y, mask=mask, blockVar=blockVar, testSplitVar=tsplit, 
                    testSplits=testSplits)
  } else {
    MVPADataset$new(trainVec=bvec, Y=Y, testVec=bvec, testY=Y, mask=mask, blockVar=blockVar)
  }
}


test_that("standard mvpa_searchlight runs without error", {
  
  dataset <- gen_dataset(c(5,5,1), 100, 2)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  model <- loadModel("sda_notune", list(tuneGrid=NULL))
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, method="standard")
  
})

test_that("standard surface-based mvpa_searchlight runs without error", {
  
  dataset <- gen_surface_dataset(100, 6)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  model <- loadModel("sda_notune", list(tuneGrid=NULL))
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, method="standard")
  
})

test_that("randomized surface-based mvpa_searchlight runs without error", {
  
  dataset <- gen_surface_dataset(100, 12)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  model <- loadModel("sda_notune", list(tuneGrid=NULL))
  res <- mvpa_searchlight(dataset, model, crossVal, radius=7, method="randomized")
  
})

test_that("randomized mvpa_searchlight runs without error", {
  
  dataset <- gen_dataset(c(5,5,1), 100, 2)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  model <- loadModel("sda_notune", list(tuneGrid=NULL))
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, method="randomized")
  
})

test_that("randomized mvpa_searchlight runs with custom_performance", {
  
  custom <- function(x) {
    cnames <- colnames(x$probs)
    y <- x$testDesign$Y
    
    p1 <- x$probs[cbind(1:nrow(x$probs), as.integer(y))]
    ret <- c(m1 = mean(p1), m2=max(p1))
    ret
  }
  
  dataset <- gen_dataset(c(5,5,1), 100, 2)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  model <- loadModel("sda_notune", list(tuneGrid=NULL, custom_performance=custom))
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, method="randomized")
  
})

test_that("standard mvpa_searchlight and tune_grid runs without error", {
  
  dataset <- gen_dataset(c(2,2,1), 50, 2, folds=3)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  tuneGrid <- expand.grid(lambda=c(.1,.8), diagonal=c(TRUE))
  model <- loadModel("sda", list(tuneGrid=tuneGrid))
  
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, method="standard")
  
})

test_that("standard mvpa_searchlight and tune_grid with two-fold cross-validation runs without error", {
  
  dataset <- gen_dataset(c(2,2,1), 50, 2, folds=2)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  
  tuneGrid <- expand.grid(lambda=c(.1,.8), diagonal=c(TRUE))
  model <- loadModel("sda", list(tuneGrid=tuneGrid))
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, method="standard")
  
})

test_that("randomized mvpa_searchlight and tune_grid runs without error", {
  
  dataset <- gen_dataset(c(2,2,1), 100, 2, folds=3)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  tuneGrid <- expand.grid(lambda=c(.1,.8), diagonal=c(TRUE))
  model <- loadModel("sda", list(tuneGrid=tuneGrid))
  
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, niter=2,method="randomized")
  
})

test_that("randomized mvpa_searchlight works with regression", {
  
  dataset <- gen_regression_dataset(c(4,4,4), 100, folds=3)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  tuneGrid <- expand.grid(alpha=.5, lambda=c(.1,.2,32))
  model <- loadModel("glmnet", list(tuneGrid=tuneGrid))
  
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, niter=2,method="randomized")
  
})

test_that("mvpa_searchlight works with testset", {
  
  dataset <- gen_dataset_with_test(c(4,4,4), 100, 3, folds=3)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  tuneGrid <- expand.grid(alpha=.5, lambda=c(.1,.2,32))
  model <- loadModel("glmnet", list(tuneGrid=tuneGrid))
  
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, method="standard")
  
})

test_that("mvpa_searchlight works with testset and split_var", {
  
  dataset <- gen_dataset_with_test(c(4,4,4), 100, 3, folds=3, splitvar=TRUE)
  crossVal <- BlockedCrossValidation(dataset$blockVar)
  tuneGrid <- expand.grid(alpha=.5, lambda=c(.1))
  model <- loadModel("glmnet", list(tuneGrid=tuneGrid))
  
  res <- mvpa_searchlight(dataset, model, crossVal, radius=3, niter=2,method="randomized", classMetrics=TRUE)
  
})






