## anes_explore.R
## Mark C. Wilson <wilson.mark.c@gmail.com>
##
## Purpose: explore ANES data to derive useful features for vote prediction
##

library("ranger")

#####################################################
##### fitting models to ANES data

# only look at those who voted D or R this time and last
# try not doing this, instead
temp <- anes_data_clean %>% 
  filter(vote == 1 | vote == 2) %>%
  filter(lastvote == 1 | lastvote == 2)  %>%
  droplevels()

set.seed(222)
# split into training and testing 
data_split <- initial_split(temp, prop = 3/4)

# create data frames for the two sets:
train_data <- training(data_split)
test_data  <- testing(data_split)

# make recipe - predict vote from lastvote and lean
train_data<-train_data %>% select(year, thermdem, thermrep,lean,lastvote,vote)
anes_rec <- 
  recipe(vote ~ ., data = train_data) %>% 
  update_role(year, new_role = "ID") %>% 
  step_dummy(all_nominal_predictors()) %>% 
  step_zv(all_predictors())

### logistic regression model
lr_mod <-
  logistic_reg(
    mode = "classification",
    engine = "glm",
    penalty = NULL,
    mixture = 1
  )

# make workflow
anes_wf <- 
  workflow() %>% 
  add_model(lr_mod) %>% 
  add_recipe(anes_rec)

# fit model on training data
anes_fit <- 
  anes_wf %>% 
  fit(data = train_data)

anes_fit %>% 
  extract_fit_parsnip() %>% 
  tidy() 

# predict and evaluate
anes_aug <- 
  augment(anes_fit, test_data)

anes_aug %>% 
  roc_curve(truth = vote, .pred_1) %>% 
  autoplot()

anes_aug %>% 
  roc_auc(truth = vote, .pred_1)

class_metrics <- metric_set(accuracy, precision, recall)
anes_aug %>% class_metrics(vote, estimate = .pred_class)

### now with random forests

rf_mod <- 
  rand_forest(trees = 1000) %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

set.seed(345)
folds <- vfold_cv(train_data, v = 10)

rf_wf <- 
  workflow() %>%
  add_model(rf_mod) %>%
  add_recipe(anes_rec) 

set.seed(456)
rf_fit_rs <- 
  rf_wf %>% 
  fit_resamples(folds)

collect_metrics(rf_fit_rs)

