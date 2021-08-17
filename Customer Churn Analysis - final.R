#shows working directory
setwd('N:\\OneDrive - The George Washington University\\Sum & Fall 2021\\6214 AI Foundation\\hw')

getwd()
library(ggplot2)
library(dplyr)
library(Amelia)
library(caTools)
library(tidyverse)

ctmchurn_df <- read.table('TelcoCustomerChurnDataset.csv',sep=",", header=TRUE)

#-------------------------------------Data Clean & Exploration------------------------------------------------------------------------------------------------------------------
#drop customer id
ctmchurn_df <- ctmchurn_df[,-1]

# Find missing Data and drop any rows with null values
any(is.na(ctmchurn_df))
missmap(ctmchurn_df, main = 'Missing Map', col=c('white', 'black'), legend=F)
# find some missing data in total charges 

# drop null values with 0
ctmchurn_df <- na.omit(ctmchurn_df)

str(ctmchurn_df)

# Demographic info
# convert gender, whether they have partners and dependents 
ctmchurn_df$gender <- as.factor(ctmchurn_df$gender)
ctmchurn_df$Partner<- as.factor(ctmchurn_df$Partner)
ctmchurn_df$Dependents <- as.factor(ctmchurn_df$Dependents)

# Services signed up
# set a function that simply converts values in rows contains "No ..." into "No" 
edit_serviceCol <- function(service) {
  out <- service
  for (i in 1:length(service)){
    if (grepl('No', service) == T){
      out[i] <- 'No'
    } else {
      out[i]
    }
  }
  out <- as.factor(out)
  return(out)
}

# Convert the columns about Services
ctmchurn_df$PhoneService <- sapply(ctmchurn_df$PhoneService, edit_serviceCol)
ctmchurn_df$MultipleLines <- sapply(ctmchurn_df$MultipleLines, edit_serviceCol)
ctmchurn_df$InternetService <- sapply(ctmchurn_df$InternetService, edit_serviceCol)
ctmchurn_df$OnlineSecurity <- sapply(ctmchurn_df$OnlineSecurity, edit_serviceCol)
ctmchurn_df$OnlineBackup <- sapply(ctmchurn_df$OnlineBackup, edit_serviceCol)
ctmchurn_df$DeviceProtection <- sapply(ctmchurn_df$DeviceProtection, edit_serviceCol)
ctmchurn_df$TechSupport <- sapply(ctmchurn_df$TechSupport, edit_serviceCol)
ctmchurn_df$StreamingTV <- sapply(ctmchurn_df$StreamingTV, edit_serviceCol)
ctmchurn_df$StreamingMovies <- sapply(ctmchurn_df$StreamingMovies, edit_serviceCol)
str(ctmchurn_df)

# Account Info
ctmchurn_df$Contract <- as.factor(ctmchurn_df$Contract)
ctmchurn_df$PaperlessBilling <- as.factor(ctmchurn_df$PaperlessBilling)
ctmchurn_df$PaymentMethod <- as.factor(ctmchurn_df$PaymentMethod)
# Churn
ctmchurn_df$Churn <- as.factor(ctmchurn_df$Churn)

# After factorize some columns, visualize some numeric variables

# Demographic info viz
for (i in 1:4) {
  print(ggplot(ctmchurn_df, aes(x=ctmchurn_df[,i]))+
          geom_bar(fill='pink') +
          xlab(colnames(ctmchurn_df)[i]))
  Sys.sleep(2)
}
#hist(x=ctmchurn_df$tenure, breaks = 30)
ggplot(ctmchurn_df, aes(x=tenure))+ 
  geom_histogram(aes(y=..density..), color='blue',fill='white', bins=30) +
  geom_density(color='red') +
  xlim(0,80)+
  ggtitle("Histogram of tenure")

# the percentage of customers who have used Telco over 2 years
nrow(subset(ctmchurn_df, tenure >= 24))/ nrow(ctmchurn_df)

# the percentage of customers who have used Telco less than 1 year
nrow(subset(ctmchurn_df, tenure < 12))/ nrow(ctmchurn_df)


# Service viz
for (i in 6:14) {
  print(ggplot(ctmchurn_df, aes(x=ctmchurn_df[,i]))+
          geom_bar(fill='blue')+
          xlab(colnames(ctmchurn_df)[i]))
  Sys.sleep(2)
}

# barchart of tenure and internet service 
ggplot(ctmchurn_df, aes(x=tenure))+
  geom_bar(aes(fill=InternetService))

nrow(subset(ctmchurn_df, tenure < 12 & InternetService !='No'))/ nrow(subset(ctmchurn_df, tenure < 12))
nrow(subset(ctmchurn_df, tenure >= 24 & InternetService !='No'))/ nrow(subset(ctmchurn_df, tenure >= 24))


nrow(subset(ctmchurn_df, tenure < 12 & PhoneService !='No'))/ nrow(subset(ctmchurn_df, tenure < 12))
nrow(subset(ctmchurn_df, tenure >= 24 & PhoneService !='No'))/ nrow(subset(ctmchurn_df, tenure >= 24))

mean(ctmchurn_df$MonthlyCharges) *24

# Account info viz
for (i in 15:17) {
  print(ggplot(ctmchurn_df, aes(x=ctmchurn_df[,i]))+
          geom_bar(fill='orange')+
          xlab(colnames(ctmchurn_df)[i]))
  Sys.sleep(2)
}
hist(ctmchurn_df$MonthlyCharges, breaks = 20, labels=F, main='Histogram of Monthly Charges', xlab='Monthly charge')
hist(ctmchurn_df$TotalCharges, breaks = 20, labels=F, main='Histogram of Total Charges', xlab='Total charge')
hist(ctmchurn_df$TotalCharges, breaks = 20)

#------------------------------------------------------Classification Model---------------------------------------------------------------
#outliers
options(repr.plot.width=10, repr.plot.height=7)
hist(df_clean$tenure,main="Tenure Histogram",col = "red",xlab="Tenure",ylab="Count") 
hist(df_clean$MonthlyCharges,main="Monthly Chargers Histogram",col = "green",xlab="Monthly_charges",ylab="Count")
hist(df_clean$TotalCharges,main="Total Chargers Histogram",col = "purple",xlab="Total_charges",ylab="Count")

#Split Data into train data (70%) and test data (30%)
# split data 70% training 30% validation
set.seed(123)
sample_size = floor(0.7*nrow(df_clean))

split_data <- sample(1:nrow(df_clean), size = sample_size)
training_data<- df_clean[split_data,]
testing_data<- df_clean[-split_data,]

#------------------------------------------------------Logistic regression Model---------------------------------------------------------------

logModel <- glm(training_data$Churn~., data=training_data, family=binomial(link="logit"))
summary(logModel)

library(MASS)
logModel_2 <- stepAIC(logModel,direction = "both")
summary(logModel_2)
formula(logModel_2)

#Check for multicollinearity:
library(car)
(vif_vars <- as.data.frame(vif(logModel_2)))

#Final Model
logModel_3 <- glm(training_data$Churn ~ Dependents + tenure + PhoneService + MultipleLines + 
                    InternetService + OnlineBackup + DeviceProtection + StreamingTV + 
                    StreamingMovies + Contract + PaperlessBilling + PaymentMethod + 
                    TotalCharges,data = training_data,family = "binomial") 
summary(logModel_3)

#AIC for model 1 is 4173.5.
#AIC for model 2 is 4164.5.
#AIC for model 3 is 4193.
#model 2 will be selected since it has the lowest AIC among these three models.

#Model Evaluation
lr_prob1 <- predict(logModel_2, testing_data, type="response")
lr_pred1 <- ifelse(lr_prob1 > 0.5,"Yes","No")
table(Predicted = lr_pred1, Actual = testing_data$Churn)

lr_prob2 <- predict(logModel_2, training_data, type="response")
lr_pred2 <- ifelse(lr_prob2 > 0.5,"Yes","No")
lr_tab1 <- table(Predicted = lr_pred2, Actual = training_data$Churn)
lr_tab2 <- table(Predicted = lr_pred1, Actual = testing_data$Churn)
lr_acc <- sum(diag(lr_tab2))/sum(lr_tab2)
lr_acc
# Accuracy = 0.8189573



# training data accuracy
lr_prob2 <- predict(logModel_2, training_data, type="response")
lr_pred2 <- ifelse(lr_prob2 > 0.5,"Yes","No")
confusionMatrix(table(lr_pred2, training_data$Churn))

# Ttesting data accuracy
confusionMatrix(lr_tab2)

#------------------------------------------------------Decision Tree Model---------------------------------------------------------------

library(C50)
library(caret)
decisionModel <- C5.0(training_data[,1:19], 
                      training_data$Churn)
summary(decisionModel)
plot(decisionModel)

# Training data  accuracy
preds_training <- predict(decisionModel, training_data, type="class")
confusionMatrix(preds_training, training_data$Churn)

# Apply the decision tree model to the validation data
preds_testing <- predict(decisionModel, testing_data, type="class")
# confusion matrix (Use validation data to test the tree model)
confusionMatrix(preds_testing, testing_data$Churn)


#correlationdata$p
library(pROC)

# ROC analysis
roc_lm <- roc(testing_data$Churn,lr_prob1,plot=T, legacy.axes=T, percent=T, 
              xlab="1-Specificity(False Postitive %)",
              ylab="Sensitivity(True Postitive %)")

pred_dm <- predict(decisionModel,testing_data,type = 'prob')

roc_dm <- roc(testing_data$Churn,pred_dm[,2],plot=T, legacy.axes=T, percent=T,
              xlab="1-Specificity(False Postitive %)",
              ylab="Sensitivity(True Postitive %)",
              main = "ROC analysis for Logistic vs. Decision Tree Model")
# to add to the same graph: add=TRUE
plot(roc_lm, col = "red", lty = 1, add = TRUE, print.auc=T, legacy.axes=T,
     main = "ROC analysis for Logistic Regression - Decision Tree Model")
plot(roc_dm, col = "black", ltpred = 10, add = TRUE,print.auc=T, 
     print.auc.y=40,legacy.axes=T)
legend("bottomright", c('Logistic','Decision'),lty=c(1,1),lwd=c(2,2),col=c('red','black'))




