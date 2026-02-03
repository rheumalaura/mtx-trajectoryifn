#Figure 1 - for Concise report ###

#setup the data ####

#load packages 
require(haven)
require(ggplot2)
require(dplyr)
require(tidyr)
require(patchwork)
require(tibble)
library(readxl)
library(tidyverse)

setwd("C:\\Users\\sejjl81\\OneDrive - University College London\\Documents\\MTXtrajectory\\LS_MTX_IFN_Manuscript\\Codes")
included <- readRDS("C:\\Users\\sejjl81\\OneDrive - University College London\\Documents\\MTXtrajectory\\LS_MTX_IFN_Manuscript\\Codes\\Datasets\\LS_mtxifntraj_included.rds")

#make trajectory groups factors ####
included$x3_traj_Group <- factor(included$x3_traj_Group)
included$x4_traj_Group <- factor(included$x4_traj_Group)
included$x5_traj_Group <- factor(included$x5_traj_Group)

##################################################################################
#3 groups trajectory plots ####

# Define labels
labels_3g <- c(
  "2" = "FR",
  "1" = "SR",
  "3" = "NR"
)

# Convert x3_traj_Group to a factor with labels
included$x3_traj_Group <- factor(included$x3_traj_Group, 
                                 levels = names(labels_3g), 
                                 labels = labels_3g)


#plot with dots 
g3_51 <- ggplot(included, aes(x = x3_traj_Group, y = pbmc51ifnscores)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_point(position = position_jitter(width = 0.15), 
             size = 1.5, alpha = 0.7, color = "black") +
  labs(
    x = "", 
    y = "51 IGS"
  ) +
  theme_classic(base_size = 16, base_family = "Arial") +
  theme(
    text = element_text(family = "Arial"),
    axis.text.x = element_text(size = 14, family = "Arial"),
    axis.text.y = element_text(size = 14, family = "Arial"),
    plot.title = element_text(family = "Arial")
  ) + ylim(4, 9)

#plot with dots 
g3_5 <- ggplot(included, aes(x = x3_traj_Group, y = ra5scores)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_point(position = position_jitter(width = 0.15), 
             size = 1.5, alpha = 0.7, color = "black") +
  labs(
    x = "", 
    y = "5 IGS"
  ) +
  theme_classic(base_size = 16, base_family = "Arial") +
  theme(
    text = element_text(family = "Arial"),
    axis.text.x = element_text(size = 14, family = "Arial"),
    axis.text.y = element_text(size = 14, family = "Arial"),
    plot.title = element_text(family = "Arial")
  ) + ylim(4, 9)

##################################################################################
#4 groups trajectory plots ####

# Define labels
labels_4g <- c(
  "2" = "FR",
  "3" = "SR", 
  "4" = "NR", 
  "1" = "HphyV"
)

# Convert x4_traj_Group to a factor with labels
included$x4_traj_Group <- factor(included$x4_traj_Group, 
                                 levels = names(labels_4g), 
                                 labels = labels_4g)


#plot with dots 
g4_51 <- ggplot(included, aes(x = x4_traj_Group, y = pbmc51ifnscores)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_point(position = position_jitter(width = 0.15), 
             size = 1.5, alpha = 0.7, color = "black") +
  labs(
    x = "", 
    y = "51 IGS"
  ) +
  theme_classic(base_size = 16, base_family = "Arial") +
  theme(
    text = element_text(family = "Arial"),
    axis.text.x = element_text(size = 14, family = "Arial"),
    axis.text.y = element_text(size = 14, family = "Arial"),
    plot.title = element_text(family = "Arial")
  ) + ylim(4, 9)

#plot with dots 
g4_5 <- ggplot(included, aes(x = x4_traj_Group, y = ra5scores)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_point(position = position_jitter(width = 0.15), 
             size = 1.5, alpha = 0.7, color = "black") +
  labs(
    x = "", 
    y = "5 IGS"
  ) +
  theme_classic(base_size = 16, base_family = "Arial") +
  theme(
    text = element_text(family = "Arial"),
    axis.text.x = element_text(size = 14, family = "Arial"),
    axis.text.y = element_text(size = 14, family = "Arial"),
    plot.title = element_text(family = "Arial")
  ) + ylim(4, 9)

##################################################################################
# 5 response groups ####
labels_5g <- c(  
  "2" = "FR",
   "4" = "SR",
  "5" = "NR",
  "1" = "HphyV",
  "3" = "HpatV"
  
)

# Convert x5_traj_Group to a factor with labels
included$x5_traj_Group <- factor(included$x5_traj_Group, 
                                 levels = names(labels_5g), 
                                 labels = labels_5g)

#plot with dots 
g5_51 <- ggplot(included, aes(x = x5_traj_Group, y = pbmc51ifnscores)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_point(position = position_jitter(width = 0.15), 
             size = 1.5, alpha = 0.7, color = "black") +
  labs(
    x = "", 
    y = "51 IGS"
  ) +
  theme_classic(base_size = 16, base_family = "Arial") +
  theme(
    text = element_text(family = "Arial"),
    axis.text.x = element_text(size = 14, family = "Arial"),
    axis.text.y = element_text(size = 14, family = "Arial"),
    plot.title = element_text(family = "Arial")
  ) + ylim(4, 9)

#plot with dots 
g5_5 <- ggplot(included, aes(x = x5_traj_Group, y = ra5scores)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_point(position = position_jitter(width = 0.15), 
             size = 1.5, alpha = 0.7, color = "black") +
  labs(
    x = "", 
    y = "5 IGS"
  ) +
  theme_classic(base_size = 16, base_family = "Arial") +
  theme(
    text = element_text(family = "Arial"),
    axis.text.x = element_text(size = 14, family = "Arial"),
    axis.text.y = element_text(size = 14, family = "Arial"),
    plot.title = element_text(family = "Arial")
  ) + ylim(4, 9)

#################################################################################
#merge the 6 plots in a single figure ####

ifnscoresvsgroups345 <- (g3_51 + g3_5) / (g4_51 + g4_5) / (g5_51 + g5_5)
ggsave("Figure1_concisereport.png", dpi = 600, height = 16, width = 10)

