
# path to kaggle data and other files
setwd("C:\\Users\\milewows\\Documents\\towerProperty")
setwd("~/Documents/towerProperty") # Matt's wd path

source("config.r")
source("helpers.r")
source("data.r")

library(kernlab)

setConfigForMyEnvironment() # special helper function for Matt's environment
includeLibraries()


filter = "" 
rawData = readData(FALSE)
allPredictors = preparePredictors(rawData, filter)
allData = prepareSplits(rawData, allPredictors, c(0))

filter = "199|200|2010|price.level|add_no|TELEMAN|JOHANN|ROSSINI|conc_missed|add_price|add_tickets|add_tickets_seats|section_2013_2014|multiple.subs|billing.city|is.us|relationship|outside|City|State|Lat|Long|package|section|location|geo|hotspot" 
useLogTransform = FALSE 
kernel="besseldot"
sigma=.001
C=100
epsilon=0.25
tol = 0.05
cross = 5
numfolds = 10
clean = T
type = "C-svc"
degree = 1
scale = 1
offset = 0
order = 10
kpar =  list(sigma=sigma, order=order, degree=degree) #"automatic" #list(sigma=sigma)

rawData = readData(useLogTransform)

polyOrder = 2
formula = prepareFormula(useLogTransform)

set.seed(551724)
folds = sample(1:numfolds, nrow(allData$allSet), replace=T)

predictors = preparePredictors(rawData, filter)


## ----- skip this CV section ----
trainError = 0
testError = 0
testErrorInact = 0
testErrorVar = 0

for(i in 1:numfolds) {
  
  data = prepareSplits(rawData, predictors, which(folds == i))
  if(clean) {
    data = cleanData(data)    
  }
  data$trainSet$total = as.factor(data$trainSet$total) # change to factors
  
  #options(error=recover)
  print(paste("Start ksvm fold ", i))
  ksvm.fit = ksvm(total~.,data=data$trainSet, scaled=T, kernel=kernel, kpar=kpar,
                  C=C, epsilon=epsilon, tol=tol, cross=cross, type=type)
  print(ksvm.fit)
  ksvm.pred = predict(ksvm.fit, newdata=data$testSet)
  ksvm.train = predict(ksvm.fit, newdata=data$trainSet)
  print("Train prediction")
  #trainError = trainError + evaluateModel(ksvm.train, data$trainSet$total, useLogTransform)
  trainError = trainError + (1-mean(ksvm.train==data$trainSet$total))
  print(trainError/i)
  print("Raw prediction")
  #testError = testError + evaluateModel(ksvm.pred, data$testAnswers, useLogTransform)
  testError = testError + (1-mean(ksvm.pred==data$testAnswers))
  print(testError/i)
  
  #print("Adjusting for inactive")
  #adjusted = adjustPredictionsInactive(ksvm.pred, data.frame("account.id"=data$testAccounts), allData$predictors)
  #testErrorInact = testErrorInact + evaluateModel(adjusted, data$testAnswers, useLogTransform)
  
  #print("Adjusting for invariance")
  #adjusted2 = adjustPredictionsInvariant(ksvm.pred, data.frame("account.id"=data$testAccounts), allData$predictors)
 # testErrorVar = testErrorVar + evaluateModel(adjusted2, data$testAnswers, useLogTransform)
  
}

#tries = numfolds
#print(paste("Final train error raw prediction=", trainError / tries, " based on ", tries, " tries"))
#print(paste("Final test error raw prediction=", testError / tries, " based on ", tries, " tries"))
#print(paste("Final test error with inactive adj=", testErrorInact / tries, " based on ", tries, " tries"))
#print(paste("Final test error with no variance adj =", testErrorVar / tries, " based on ", tries, " tries"))

## ----

ksvm.fit = ksvm(as.factor(total)~.,data=data$trainSet, scaled=T, kernel=kernel, kpar=kpar,
                C=C, epsilon=epsilon, tol=tol, cross=cross, type=type)
ksvm.fit
predictSet = prepareDataToPredict(data$predictors)
predictSetAll = prepareDataToPredict(allData$predictors)
predictions = predict(ksvm.fit, newdata=predictSet$testSet)#, n.trees=trees)

#predictions = adjustPredictionsInactive(predictions, data.frame("account.id"=predictSet$accounts), 
                                        predictSetAll$testSetAll)

if(useLogTransform) {
  predictions = exp(predictions)-1
}

#dumpResponse("MS_svm_c-scv_sub", predictSet$accounts)
prefix =  "MS_svm_c-scv_sub"
entry=cbind(predictSet$accounts, as.character(predictions))
write.csv(entry, paste(prefix, format(Sys.time(), "%b_%d_%Y"),".csv", sep=""), row.names = FALSE)  


