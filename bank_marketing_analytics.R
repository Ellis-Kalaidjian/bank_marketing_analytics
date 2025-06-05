library(tidyr)
library(dplyr)
library(stats)
library(ggplot2)

setwd()

bank_market.df <- read.csv("./bank-additional/bank-additional-full.csv", sep = ";", stringsAsFactors = FALSE)

# DATA CLEANING AND ORGANIZATION  ---------------------------------------------------------------------
colSums(is.na(bank_market.df)) #check for NAs

#creating ordinal dummy variables for each categorical variable and remove redundant categorical counterparts 
cat_vars <- names(bank_market.df[, c(2:10,15,21)])
bank_market.df.numeric <- bank_market.df %>%
  mutate(across(all_of(cat_vars), 
                ~ as.integer(factor(., levels = unique(.))), 
                .names = "{.col}_code"))
bank_market.df.numeric <- bank_market.df.numeric[, -c(2:10,15,21)] #remove categorical variables


# EDA ---------------------------------------------------------------------
#examine summary statistics 
for (var in names(bank_market.df.numeric)) {
  cat("Summary statistics for",var,":\n")
  print(summary(bank_market.df.numeric[[var]]))
  cat("\n")
}

#create age categorization variable: young adult (17-25yrs); adult (26-44yrs); Middle-age (45-59yrs); Old age (60+yrs)
bank_market.df <- bank_market.df %>%
  mutate(age_grp = case_when(
    age <= 25 ~ "young adult",
    age >= 26 & age <= 44 ~ "adult",
    age >= 45 & age <= 59 ~ "middle-aged",
    age >= 60 ~ "old"))

#create totals tables for demographics
dem_vars <- c("age_grp","marital","job","education","housing","loan","default")
for (var in dem_vars) {
  df <- table(bank_market.df[[var]]) %>% sort(decreasing = T)
  assign(paste0(var, ".df"), df)
}

print(age.df)
print(marital.df)
print(job.df)
print(education.df)
print(housing.df)
print(loan.df)
print(default.df)

#visualize distributions of jobs and age 
age.jobs.df <- table(bank_market.df$age_grp, bank_market.df$job)
blue_shades <- colorRampPalette(c("lightblue", "blue4"))(nrow(age.jobs.df))
bp <- barplot(age.jobs.df,
              beside = TRUE,
              col = blue_shades,
              las = 2,
              font.axis = 1.2,
              cex.axis = 0.8,
              cex.names = 0.75)
legend(x = 25,
       y = 7500,
       legend = rownames(age.jobs.df),
       fill = blue_shades,
       bty = "n",
       cex = 0.8,
       x.intersp = 0.2)


# RANDOM FOREST -----------------------------------------------------------
library(randomForest)
set.seed(123)
#split data into training and test sets
train_index <- sample(seq_len(nrow(bank_market.df.numeric)), size = 0.7 * nrow(bank_market.df.numeric))
rf_train <- bank_market.df.numeric[train_index, ]
rf_test  <- bank_market.df.numeric[-train_index, ]

#fit the Random Forest model on training dataset
rf.model <- randomForest(factor(y_code) ~ ., data = rf_train, importance = TRUE)
varImpPlot(rf.model)

#after reviewing results of RF model, it appears to be struggling to predict yes responses
#This may be due to model imbalance. We can assess this by looking at distribution of Y/N
#responses in a histogram
ggplot(bank_market.df, aes(x=y)) +
  geom_bar(fill = "steelblue", color = "black") +
  labs(x="Did Respondent Buy Long-term Deposit?") +
  theme_minimal()

#it's apparent that the data are largely imbalanced on "NO" responses

# RANDOM FOREST MODEL VALIDATION: CALCULATE AUC & ADDRESS IMBALANCE ------------------------------------------
library(pROC)
#generate predicted probabilities on the test set
rf_pred_probs <- predict(rf.model, rf_test, type = "prob")[, 2]  # probs for class "2" (or "yes")

#prepare actual values from the test set
actual <- as.numeric(rf_test$y_code) - 1  # Convert to numeric 0/1 

#calculate AUC
roc_obj <- roc(actual, rf_pred_probs)
auc_val <- auc(roc_obj)
print(auc_val)
plot(roc_obj, col = "blue", main = "ROC Curve for Logistic Regression")

#SMOTE Oversampling
library(themis)
library(recipes)

#look at counts of No's and Yes's to determine over and under criteria for smote
#based on a 60/40 split
table(bank_market.df$y)

#Let T = total number of observations after SMOTE
#Then:yes = 0.4 × T and no = 0.6 × T = 36,548
# So: T = 36,548 / 0.6 = 60,913
# Desired yes = 0.4 × 60,913 = 24,365
# Currently have 4,640 "yes", so you need synthetic samples: 24,365 − 4,640 = 19,725
# #Now calculate the over_ratio. In step_smote(), the over_ratio is defined as:
# over_ratio = desired_total_minority / original_minority.
# Hence, over_ratio = 24,365 / 4,640 ≈ 5.25

# Build recipe for training the data
smote_recipe <- recipe(y_code ~ ., data = rf_train) %>%
  step_smote(y_code, over_ratio = 5.25)
# Prep and apply
smote_prepped <- prep(smote_recipe)
rf_train.smote <- juice(smote_prepped)
# pass rf_train.smote through RF 
set.seed(123)
rf.model.smote <- randomForest(factor(y_code) ~ ., data = rf_train.smote, importance = TRUE)

#evaluate on the original test set
rf_pred_probs <- predict(rf.model.smote, newdata = rf_test, type = "prob")
predicted_class <- predict(rf.model.smote, newdata = rf_test)

# Confusion matrix
table(Predicted = predicted_class, Actual = rf_test$y_code)

# ROC-AUC
roc_obj <- roc(rf_test$y_code, rf_pred_probs[, "2"])
auc(roc_obj)

# LOGISTIC REGRESSION -----------------------------------------------------
#standardize values for later comparison of coefficients
df.standardized <- scale(bank_market.df.numeric[, -which(names(bank_market.df.numeric) == "y_code")])
df.standardized <- as.data.frame(df.standardized)
df.standardized$y_code <- bank_market.df.numeric$y_code

#split data into training and test sets
train_index_log <- sample(seq_len(nrow(df.standardized)), size = 0.7 * nrow(bank_market.df.numeric))
log_train <- df.standardized[train_index_log, ]
log_test  <- df.standardized[-train_index_log, ]

#Fit the logistic regression model on the training dataset
model.logit <- glm(factor(y_code) ~ ., data = log_train, family = binomial)
summary(model.logit)

#output as table
library(broom)
library(knitr)
tidy_table <- tidy(model.logit)
write.csv(tidy_table, "logit_output.csv", row.names = FALSE)

#calculate McFadden's Pseudo R-Squared
ll.null <- model.logit$null.deviance/-2 #calculate log-likelihood of null model
ll.proposed <-model.logit$deviance/-2 # calculate log-likelihood of model.logit
(ll.null - ll.proposed) / ll.null #calculate McFadden's Pseudo R-Squared
1 - pchisq(2*(ll.proposed - ll.null), df=(length(model.logit$coefficients)-1)) # calculate p-value of R-Squared

#visualize results
#create data frame that contains probabilities of accepting/rejecting campaign along with actual accpetance status
predicted.data <- data.frame(
  probability.of.accept=model.logit$fitted.values,
  y=bank_market.df.numeric$y_code)
#sort data frame from low probabilities to high probabilities
predicted.data <- predicted.data[
  order(predicted.data$probability.of.accept, decreasing = F),]
#add column to data frame that has the rank of each sample, from low prob to high prob
predicted.data$rank <- 1:nrow(predicted.data)
#use ggplot and cowplot
library(cowplot)
ggplot(data=predicted.data, aes(x=rank, y=probability.of.accept)) +
  geom_point(aes(color=y), alpha=1, shape=4, stroke=2)+
  xlab("Index") +
  ylab("Predicted probability of accepting campaign")


# LOGISTIC REGRESSION MODEL VALIDATION: CALCULATE AUC ------------------------------------
log_pred_probs <- predict(model.logit, newdata = log_test, type = "response")
actual <- as.numeric(log_test$y_code) - 1  # Converts factor levels to 0/1
roc_obj <- roc(actual, log_pred_probs)
auc_value <- auc(roc_obj)
print(auc_value)

#plot
plot(roc_obj, col = "blue", main = "ROC Curve for Logistic Regression")
