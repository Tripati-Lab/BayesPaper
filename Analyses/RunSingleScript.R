
source("https://raw.githubusercontent.com/Tripati-Lab/BayClump/dev/Functions/Calibration_BayesianNonBayesian.R")
source("https://raw.githubusercontent.com/Tripati-Lab/BayClump/dev/Functions/Predictions_Bayesian.R")
source("https://raw.githubusercontent.com/Tripati-Lab/BayClump/dev/Functions/Predictions_nonBayesian.R")
source("https://raw.githubusercontent.com/Tripati-Lab/BayClump/dev/global.R")

replicates = 100
samples = NULL
ngenerationsBayes = 5000
multicore = FALSE
priors="Informative"

RunSingleFullResults <- function(name="S1",
                                 replicates, 
                                 samples, 
                                 ngenerationsBayes, 
                                 priors){

calData <- read.csv(paste0("Datasets/Dataset_",name, ".csv"))
recData <-read.csv("Datasets/BayClump_reconstruction_template.csv") 


multicore=FALSE

calData$T2 <- calData$Temperature
lmcals <- simulateLM_measured(calData, replicates = replicates, samples = samples)
lminversecals <- simulateLM_inverseweights(calData, replicates = replicates, samples = samples)
yorkcals <- simulateYork_measured(calData, replicates = replicates, samples = samples)
demingcals <- simulateDeming(calData, replicates = replicates, samples = samples, multicore=multicore)
bayeslincals <- fitClumpedRegressions(calibrationData=calData, 
                                                 priors = priors,
                                                 n.iter = ngenerationsBayes,
                                                 samples = samples)
nonBayesianParamsComplete <- rbindlist(list("OLS"=lmcals,
     "WOLS"=lminversecals,
     "York"=yorkcals,
     "Deming"=demingcals), idcol = "Model")       
       
BayesianPosteriors <- rbindlist(list("BLM1_fit"=do.call(rbind.data.frame,as.mcmc(bayeslincals$BLM1_fit)),
                                     "BLM1_fit_NoErrors"=do.call(rbind.data.frame,as.mcmc(bayeslincals$BLM1_fit_NoErrors)),
                                     "BLM3_fit"=do.call(rbind.data.frame,as.mcmc(bayeslincals$BLM3_fit))), idcol = "Model", fill = T)  

Params <- rbind.data.frame(nonBayesianParamsComplete, BayesianPosteriors[,1:3])

ParamEstimates <- aggregate(. ~ Model, Params, function(x) c(mean = mean(x), se = sd(x)/sqrt(length(x)) ))

calData$Tc <- sqrt(10^6/(calData$T2))-273.15
calData$TcE <- abs((sqrt(10^6/(calData$T2))-273.15) - (sqrt(10^6/(calData$T2+abs(calData$TempError)))-273.15))
              
lmrecBayClump <-   do.call(rbind,lapply(1:nrow(recData), function(x){
                a <- predictTcInvest(calData=calData, 
                                     targety=recData$D47[x],
                                     targetyError=recData$D47error[x],
                                     nObs = recData$N[x],
                                     obCal=lmcals)
                cbind.data.frame("D47"=recData$D47[x],"D47se"=recData$D47error[x], "Tc"=a$temp, "se"=a$se)
              } ))
              

lmrecClassic <-  do.call(rbind,lapply(1:nrow(recData), function(x){
                a <- predictTc(calData, targety=recData$D47[x],obCal=lmcals)
                b <- predictTc(calData, targety=recData$D47[x]+recData$D47error[x], obCal=lmcals)
                cbind.data.frame("D47"=recData$D47[x],"D47se"=recData$D47error[x], "Tc"=a$temp, "se"=a$temp-b$temp)
              } ))
              
            

lminverserecBayClump <-   do.call(rbind,lapply(1:nrow(recData), function(x){
                a<-predictTcInvest(calData=calData, 
                                   targety=recData$D47[x],
                                   targetyError=recData$D47error[x],
                                   nObs = recData$N[x],
                                   obCal=lminversecals)
                cbind.data.frame("D47"=recData$D47[x],"D47se"=recData$D47error[x], "Tc"=a$temp, "se"=a$se)
              } ))
              

lminverserecClassic  <-  do.call(rbind,lapply(1:nrow(recData), function(x){
                a <- predictTc(calData, targety=recData$D47[x], obCal=lminversecals)
                b <- predictTc(calData, targety=recData$D47[x]+recData$D47error[x], obCal=lminversecals)
                cbind.data.frame("D47"=recData$D47[x],"D47se"=recData$D47error[x], "Tc"=a$temp, "se"=a$temp-b$temp)
              } ))
            
   
yorkrecBayClump <-   do.call(rbind,lapply(1:nrow(recData), function(x){
                a<-predictTcInvest(calData=calData, 
                                   targety=recData$D47[x],
                                   targetyError=recData$D47error[x],
                                   nObs = recData$N[x],
                                   obCal=yorkcals)
                cbind.data.frame("D47"=recData$D47[x],"D47se"=recData$D47error[x], "Tc"=a$temp, "se"=a$se)
              } ))
              
   
yorkrecClassic  <-   do.call(rbind,lapply(1:nrow(recData), function(x){
                a <- predictTc(calData, targety=recData$D47[x], obCal=yorkcals)
                b <- predictTc(calData, targety=recData$D47[x]+recData$D47error[x], obCal=yorkcals)
                cbind.data.frame("D47"=recData$D47[x],"D47se"=recData$D47error[x], "Tc"=a$temp, "se"=a$temp-b$temp)
              } ))
              


demingrecBayClump  <-   do.call(rbind,lapply(1:nrow(recData), function(x){
                a<-predictTcInvest(calData=calData, 
                                   targety=recData$D47[x],
                                   targetyError=recData$D47error[x],
                                   nObs = recData$N[x],
                                   obCal=demingcals)
                cbind.data.frame("D47"=recData$D47[x],"D47se"=recData$D47error[x], "Tc"=a$temp, "se"=a$se)
              } ))


demingrecClassic <- do.call(rbind,lapply(1:nrow(recData), function(x){
                a <- predictTc(calData, targety=recData$D47[x], obCal=demingcals)
                b <- predictTc(calData, targety=recData$D47[x]+recData$D47error[x], obCal=demingcals)
                cbind.data.frame("D47"=recData$D47[x],"D47se"=recData$D47error[x], "Tc"=a$temp, "se"=a$temp-b$temp)
              }))
            

infTempBayesian <- BayesianPredictions(bayeslincals=bayeslincals, 
                                                   D47Pred=recData$D47,
                                                   D47Prederror=ifelse(recData$D47error==0,0.00001,recData$D47error),
                                                   materialsPred=as.numeric(as.factor(ifelse(is.na(recData$Material), 1,recData$Material)))
            )
            
BayesianRecs <- rbindlist(lapply(infTempBayesian, as.data.frame), idcol = 'Model')
colnames(BayesianRecs)[2:3] <- c("Tc", "se")

BayesianRecs$D47 <- rep(yorkrecClassic$D47, nrow(BayesianRecs)/nrow(yorkrecClassic))
BayesianRecs$D47se <- rep(yorkrecClassic$D47se, nrow(BayesianRecs)/nrow(yorkrecClassic))


##Reconstructions

RecComplete <- rbindlist(list(
"Classic"= rbindlist(list("OLS"=lmrecClassic,
     "York"=yorkrecClassic,
     "Deming"=demingrecClassic,
     "WOLS"=lminverserecClassic),
idcol = "Model"),

"BayClump"= rbindlist(list("Deming"=demingrecBayClump,
     "OLS"=lmrecBayClump,
     "York"=yorkrecBayClump,
     "WOLS"=lminverserecBayClump),
     idcol="Model"),
Bayesian=BayesianRecs), idcol = "Type", fill=T
)



toRet <- list("ParameterEstimates"=ParamEstimates,
     "Reconstructions"=RecComplete,
     "RawParams"=Params,
     BayesianRecs,
     bayeslincals
     )

write.csv(ParamEstimates, paste0('Results/',name,"Replicates=", replicates,"Samples=",samples,priors ,"_ParameterEstimates.csv" ))
write.csv(RecComplete, paste0('Results/',name,"Replicates=", replicates,"Samples=",samples,priors ,"_Recs.csv" ))
write.csv(Params, paste0('Results/',name,"Replicates=", replicates,"Samples=",samples,priors ,"_ParamsFull.csv" ))

return(toRet)
}

##50
###Informative
a <- RunSingleFullResults(name="S1",
                     replicates=1000, 
                     samples=50, 
                     ngenerationsBayes=20000, 
                     priors='Informative')

b <-RunSingleFullResults(name="S2",
                     replicates=1000, 
                     samples=50, 
                     ngenerationsBayes=20000, 
                     priors='Informative')


c <-RunSingleFullResults(name="S3",
                     replicates=1000, 
                     samples=50, 
                     ngenerationsBayes=20000, 
                     priors='Informative')

###Difuse

a1 <-RunSingleFullResults(name="S1",
                     replicates=1000, 
                     samples=50, 
                     ngenerationsBayes=20000, 
                     priors='Difuse')

b1 <-RunSingleFullResults(name="S2",
                     replicates=1000, 
                     samples=50, 
                     ngenerationsBayes=20000, 
                     priors='Difuse')


c1 <-RunSingleFullResults(name="S3",
                     replicates=1000, 
                     samples=50, 
                     ngenerationsBayes=20000, 
                     priors='Difuse')

##500
###Informative
d <-RunSingleFullResults(name="S1",
                     replicates=1000, 
                     samples=500, 
                     ngenerationsBayes=20000, 
                     priors='Informative')

e <-RunSingleFullResults(name="S2",
                     replicates=1000, 
                     samples=500, 
                     ngenerationsBayes=20000, 
                     priors='Informative')


f <-RunSingleFullResults(name="S3",
                     replicates=1000, 
                     samples=500, 
                     ngenerationsBayes=20000, 
                     priors='Informative')


###Difuse
d1 <-RunSingleFullResults(name="S1",
                     replicates=1000, 
                     samples= 500, 
                     ngenerationsBayes=20000, 
                     priors='Difuse')

e1 <-RunSingleFullResults(name="S2",
                     replicates=1000, 
                     samples= 500, 
                     ngenerationsBayes=20000, 
                     priors='Difuse')


f1 <-RunSingleFullResults(name="S3",
                     replicates=1000, 
                     samples= 500, 
                     ngenerationsBayes=20000, 
                     priors='Difuse')


##10
###Informative
g <-RunSingleFullResults(name="S1",
                     replicates=1000, 
                     samples=10, 
                     ngenerationsBayes=20000, 
                     priors='Informative')

h <-RunSingleFullResults(name="S2",
                     replicates=1000, 
                     samples=10, 
                     ngenerationsBayes=20000, 
                     priors='Informative')


i <-RunSingleFullResults(name="S3",
                     replicates=1000, 
                     samples=10, 
                     ngenerationsBayes=20000, 
                     priors='Informative')


###Difuse
g1 <-RunSingleFullResults(name="S1",
                     replicates=1000, 
                     samples= 10, 
                     ngenerationsBayes=20000, 
                     priors='Difuse')

h1 <-RunSingleFullResults(name="S2",
                     replicates=1000, 
                     samples= 10, 
                     ngenerationsBayes=20000, 
                     priors='Difuse')


i1 <-RunSingleFullResults(name="S3",
                     replicates=1000, 
                     samples= 10, 
                     ngenerationsBayes=20000, 
                     priors='Difuse')

