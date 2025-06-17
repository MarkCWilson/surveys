## anes_clean.R
## Mark C. Wilson <wilson.mark.c@gmail.com>
##
## Purpose: import and clean ANES and related data, add and remove variables
##

#####################################################
##### Load libraries and helper functions

library(tidyverse)
library(tidymodels)

#####################################################
##### Import data
setwd("/Users/mwilson/Documents/GitHub/anes_predict")
inc_data_orig <- as_tibble(read.table('data/Unemployment2023.csv', header=TRUE,sep=",",strip.white=TRUE, quote="\""))
edu_data_orig <- as_tibble(read.table('data/Education2023.csv', header=TRUE,sep=",",strip.white=TRUE, quote="\""))
anes_data_orig <- as_tibble(read.table('data/anes_timeseries_cdf_csv_20220916/anes_timeseries_cdf_csv_20220916.csv', header=TRUE,sep=",",strip.white=TRUE, quote="\""))

#####################################################
##### Explore data

dim(inc_data_orig)
dim(edu_data_orig)
dim(anes_data_orig)

inc_g <- inc_data_orig %>% glimpse()
edu_g <- edu_data_orig %>% glimpse()
#anes_g <- anes_data_orig %>% glimpse() # too big - check the codebook

#####################################################
##### Tidy data format

anes_data_clean <- anes_data_orig

# messes things up otherwise, not sure why

inc_data_clean <- inc_data_orig %>% 
  rename(fips = FIPS_Code, unit = Area_Name) %>% 
  pivot_wider(names_from = Attribute, values_from = Value) 

edu_data_clean <- edu_data_orig %>% 
  rename(fips = FIPS.Code, unit = Area.name)  %>%
  pivot_wider(names_from = Attribute, values_from = Value) 

inc_data_clean <- inc_data_clean %>% 
  pivot_longer(cols = !(fips), names_to = c(".value", "year"),
               names_pattern = "^(.*)_([0-9]{4})$", 
               values_to = "count")

# did this first because of trouble with pivot_longer
edu_data_clean <- edu_data_clean %>%
  select(-matches("Code") & !State:unit  & -matches("Percent"))

edu_data_clean <- edu_data_clean %>% 
  pivot_longer(cols = !(fips), names_to = c(".value", "year"), 
               names_sep = ", ", values_to = "count") 

#####################################################
##### Restrict to relevant data - major choices needed

inc_data_clean <- inc_data_clean %>% 
  select(c(fips, year, Civilian_labor_force, Unemployed))

anes_data_clean <- anes_data_clean %>%
  select(year = VCF0004, edu = VCF0140a, sex = VCF0104, race = VCF0105b, 
         urb = VCF0111, occ = VCF0115, emp = VCF0118, mar = VCF0147, thermdem = VCF0218, 
         thermrep = VCF0224, intvote = VCF0734, pastfin = VCF0880, predfin = VCF0881, 
         lastvote = VCF9027, statepred = VCF9028, state = VCF0901a,
         natpred = VCF0700, vote = VCF0704, ontrack = VCF9222) #%>%

#####################################################
##### Fix remaining data format problems, improve variable names

inc_data_clean <- inc_data_clean %>% 
  mutate(year = as.integer(year))

edu_data_clean$year[edu_data_clean$year == "2008-12"] = 2012
edu_data_clean$year[edu_data_clean$year == "2019-23"] = 2020

edu_data_clean <- edu_data_clean %>%
  mutate(year = as.integer(year)) 

edu_data_clean <- edu_data_clean %>%
  replace(is.na(.), 0)

#####################################################
##### Add useful derived variables

inc_data_clean <- inc_data_clean %>% 
  mutate(unemprate = Unemployed/Civilian_labor_force)

colnames(edu_data_clean) <- c("fips", "year", "e1","e2","e3","e4", "E1","E2","E3","E4")
edu_data_clean <- edu_data_clean %>%
  mutate(Bac = e1+E1, Ass = e2+E2, High = e3+E3, Low = e4+E4) %>%
  select(c("fips", "year", Bac, Ass, High, Low))

anes_data_clean <- anes_data_clean %>% 
  mutate(inc = 
           case_when(year == 1992 ~2, year == 1996 ~1, year == 2000 ~1,
                     year == 2004 ~2, year == 2008 ~2, year == 2012 ~1,
                     year == 2016 ~1, year == 2020 ~2), 
         lean = ifelse(ontrack==1,inc, 3-inc)) %>%
  mutate(inc = as.factor(inc), urb = as.factor(urb), occ = as.factor(occ), 
         emp = as.factor(emp), sex = as.factor(sex), race=as.factor(race), 
         pastfin = as.factor(pastfin), predfin = as.factor(predfin),
         lastvote = as.factor(lastvote), statepred = as.factor(statepred), 
         state = as.factor(state),
         natpred = as.factor(natpred), vote = as.factor(vote), intvote = as.factor(intvote),
         ontrack = as.factor(ontrack), edu = as.factor(edu), lean = as.factor(lean)) %>%
  filter(!if_any(everything(), is.na))

