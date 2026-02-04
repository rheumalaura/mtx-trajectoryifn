#correction of SMD and missingness 
#load packages 
require(haven)
require(ggplot2)
require(dplyr)
require(tidyr)
require(patchwork)
require(tibble)
library(readxl)
library(tidyverse)
library(tableone)
library(smd)
library(ggrepel)

setwd("C:\\Users\\sejjl81\\OneDrive - University College London\\Documents\\MTXtrajectory\\LS_MTX_IFN_Manuscript\\Codes")
included <- readRDS("C:\\Users\\sejjl81\\OneDrive - University College London\\Documents\\MTXtrajectory\\LS_MTX_IFN_Manuscript\\Codes\\Datasets\\LS_mtxifntraj_included.rds")

#make table 1 object ####
included$x3_traj_Group <- factor(included$x3_traj_Group)
included$x4_traj_Group <- factor(included$x4_traj_Group)
included$x5_traj_Group <- factor(included$x5_traj_Group)

#variables for Table 1 
interest_vars <- c("sex", "white_ethnicity", "x3_traj_Group", "x4_traj_Group", "x5_traj_Group", 
                   "timepointdate_diff", "disease_dur_mtx_start", "mtx_dose", "age_t1", 
                   "esr_t1", "crp_t1", "patientparentglobal_t1", "limitedjoints_t1", "activejoints_t1", "physicianglobal_t1", 
                   "esr_t2", "crp_t2", "patientparentglobal_t2", "limitedjoints_t2", "activejoints_t2", "physicianglobal_t2")
interest_cat <- c("sex", "white_ethnicity", "x3_traj_Group", "x4_traj_Group", "x5_traj_Group")

tab1 <- CreateTableOne(vars = interest_vars, 
                       strata = "ifnscore_yes", 
                       data = included, 
                       factorVars = interest_cat, # Tells R these are categorical
                       test = FALSE, 
                       addOverall = TRUE) 
print(tab1, smd = TRUE, showAllLevels = TRUE, missing = TRUE, addOverall = TRUE)
#missing here are in the 

#export the table1 object ####
tab1_mat <- print(tab1, 
                  smd = TRUE, 
                  showAllLevels = TRUE, 
                  quote = FALSE, 
                  noSpaces = TRUE, 
                  printToggle = FALSE, 
                  missing = TRUE, 
                  addOverall = TRUE)
tab1_export <- as.data.frame(tab1_mat)

#export dataframe from Table1 ####
smd_matrix <- ExtractSmd(tab1)
smd_data <- as.data.frame(smd_matrix)
smd_data$Variable <- rownames(smd_data)
colnames(smd_data) <- c("SMD", "Variable")

#here values are confirmed!!!

#check manually ####
included.small <- included %>% 
  select(patientid, sex, white_ethnicity, x3_traj_Group, x4_traj_Group, x5_traj_Group, ifnscore_yes,
         timepointdate_diff, disease_dur_mtx_start, mtx_dose, age_t1, 
         esr_t1, crp_t1, patientparentglobal_t1, limitedjoints_t1, activejoints_t1, physicianglobal_t1, 
         esr_t2, crp_t2, patientparentglobal_t2, limitedjoints_t2, activejoints_t2, physicianglobal_t2)
ifn_no <- included.small %>% 
  filter(ifnscore_yes == 0)
ifn_yes <- included.small %>% 
  filter(ifnscore_yes == 1)

ifnyes_sex <- ifn_yes$sex
ifnno_sex <- ifn_no$sex
#proportion
p1 <- mean(ifnyes_sex, na.rm = TRUE) 
p2 <- mean(ifnno_sex, na.rm = TRUE)

#variance 
v1 <- p1 * (1 - p1)
v2 <- p2 * (1 - p2)

#pooled sd
pooled_sd <- sqrt((v1 + v2) / 2)

#SMD 
smd_cat_manual <- abs(p1 - p2) / pooled_sd

#supplementary plot missingness and variables ####

missing_table <- data.frame(
)

percentage <- function(part, whole) {
  if (whole == 0) {
    return(NA)
  }
  return((part / whole) * 100)
}


#create loop
for (var in interest_vars) {
  Count_NA <- sum(is.na(included.small[[var]]))
  subset <- included.small[included.small$ifnscore_yes == 1, ]
  Count_NA_subset <- sum(is.na(subset[[var]]))
  bigset <- included.small[included.small$ifnscore_yes == 0, ]
  Count_NA_bigset <- sum(is.na(bigset[[var]]))
  
  missing_table <- rbind(missing_table, data.frame(
    Variable = var,
    Count_NA = Count_NA,
    Percentage_NA = round(percentage(Count_NA, nrow(included.small)), 2), 
    Count_NA_subset = Count_NA_subset,
    Percentage_NA_subset = round(percentage(Count_NA_subset, nrow(subset)), 2),
    Count_NA_bigset = Count_NA_bigset, 
    Percentage_NA_bigset = round(percentage(Count_NA_bigset, nrow(bigset)), 2),
    stringsAsFactors = FALSE
  ))
}

#attach to the smd_data 
smdmiss <- left_join(smd_data, missing_table, by = "Variable")
smdmiss.small <- smdmiss %>% 
  filter(!Variable %in% c("x3_traj_Group", "x4_traj_Group", "x5_traj_Group"))


#plot 
ggplot(smdmiss.small, aes(x = Percentage_NA, y = SMD)) + 
  geom_point(aes(color = SMD > 0.2), alpha = 0.6, size = 2)  +
  scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red")) +
  theme_classic(base_size = 16, base_family = "Arial") +
  theme(
    text = element_text(family = "Arial"),
    axis.text.x = element_text(size = 12, family = "Arial"),
    axis.text.y = element_text(size = 12, family = "Arial"),
    plot.title = element_text(family = "Arial")
  ) +
  labs(
    x = "Missing (%)",
    y = "SMD"
  )


ifnscoresubset <- ggplot(smdmiss.small, aes(x = Percentage_NA_subset, y = SMD)) + 
  geom_point(aes(color = SMD > 0.2), alpha = 0.6, size = 2) + 
  scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red")) +
  theme_classic(base_size = 16, base_family = "Arial") +
  theme(
    text = element_text(family = "Arial"),
    axis.text.x = element_text(size = 12, family = "Arial"),
    axis.text.y = element_text(size = 12, family = "Arial"),
    plot.title = element_text(family = "Arial")
  ) +
  labs(
    x = "Missing (%)",
    y = "SMD"
  ) + geom_text_repel(
    data = subset(smdmiss.small, SMD > 0.2), 
    aes(label = Variable),            
    size = 4,
    family = "Arial",                
    box.padding = 0.5                 
  )

noifn_bigset <- ggplot(smdmiss.small, aes(x = Percentage_NA_bigset, y = SMD)) + 
  geom_point(aes(color = SMD > 0.2), alpha = 0.6, size = 2) + 
  scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red")) +
  theme_classic(base_size = 16, base_family = "Arial") +
  theme(
    text = element_text(family = "Arial"),
    axis.text.x = element_text(size = 12, family = "Arial"),
    axis.text.y = element_text(size = 12, family = "Arial"),
    plot.title = element_text(family = "Arial")
  ) +
  labs(
    x = "Missing (%)",
    y = "SMD"
  ) + geom_text_repel(
    data = subset(smdmiss.small, SMD > 0.2), 
    aes(label = Variable),            
    size = 4,
    family = "Arial",                
    box.padding = 0.5                 
  )

smdandmissing <- ifnscoresubset + noifn_bigset
ggsave("Supplementary_Fig2.png", smdandmissing, dpi = 600, width = 12, height = 8)
