#power calculation 
#this document has been discussed with and approved by Chris Wallace on 09/01/2026

#since I compared the means across groups and I used one-way anova to detect differences 
#the way to measure the strenght of my results is using Cohen's f 
##Small effect ($f = 0.10$): The clusters are very slightly different; lots of overlap.
##Medium effect ($f = 0.25$): Visible differences between some clusters.
##Large effect ($f = 0.40$): The clusters are clearly distinct.

#two questions are asked: 
#1. "What was my power?" (assuming a standard "medium" biological effect).
#2. "What could I detect?" (What is the smallest difference I could have found with 80% confidence?).
#3. "What sample sizes should I have to detect a medium effect with sufficient power?"

#expected results 

#Minimum detectable effect: ~0.30 (Medium-to-Large). 
#Meaning: Your study is strong enough to find large differences between clusters, but it might miss subtle (small) differences.

#setup the study ####
# install.packages("pwr")
library(pwr)

#Parameters
total_N <- 102
group_sizes <- c(21, 12, 17, 26, 28)
k_groups <- length(group_sizes)


# pwr.anova.test requires 'n' to be the sample size PER GROUP. however my groups are not all equal in number 
#so it has been suggested to use the Harmonic Mean
# Formula: k / sum(1/n)
n_harmonic <- k_groups / sum(1 / group_sizes)

#Post-hoc Power Calculation ####
# assuming a medium difference (f=0.25)
power_result <- pwr.anova.test(k = k_groups, 
                               n = n_harmonic, # Use the harmonic mean here
                               f = 0.25,       # Medium effect
                               sig.level = 0.05)
#power = 0.44
#Our study had limited power (approx 40%) to detect medium effect sizes due to the limited size of the smallest cluster (n=12).


#Sensitivity Analysis ####
# "What is the minimum effect size I could detect with 80% power?"
min_effect <- pwr.anova.test(k = k_groups, 
                             n = n_harmonic, 
                             power = 0.80,     # Standard power
                             sig.level = 0.05, # Standard alpha
                             f = NULL)         # Solve for this
#result: 0.36 medium to large effect !
#"Due to the unequal sample sizes (specifically the smallest group of 12), 
#this study is powered to detect large differences between the trajectories. 
#It may not have enough sensitivity (power) to detect subtle or moderate correlation trends."

#what sample size should I have in order to detect medium effects? 
min_sample_medium <- pwr.anova.test(k = k_groups,   
                                    power = 0.80,     # Standard power
                             sig.level = 0.05, # Standard alpha
                             f = 0.25)         # Solve for this

#n_harmonic should be at least 39 (vs my 18)


#I shall perform the same checks with 3 and 4 groups ####
#3 groups ####
total_N <- 102
group_sizes <- c(42, 31, 29)
k_groups <- length(group_sizes)
n_harmonic <- k_groups / sum(1 / group_sizes)

power_result <- pwr.anova.test(k = k_groups, 
                               n = n_harmonic, # Use the harmonic mean here
                               f = 0.25,       # Medium effect
                               sig.level = 0.05)
#power = 0.585665
#a bit better power to detect differences but the three levels of trajectory are not enough detailed to capture a child's complexity

#sensitivity 
min_effect <- pwr.anova.test(k = k_groups, 
                             n = n_harmonic, 
                             power = 0.80,     # Standard power
                             sig.level = 0.05, # Standard alpha
                             f = NULL)         # Solve for this
#f = 0.31 medium effect 

#harmonic mean  to detect medium effect should be 
min_sample_medium_3 <- pwr.anova.test(k = k_groups,   
                                    power = 0.80,     # Standard power
                                    sig.level = 0.05, # Standard alpha
                                    f = 0.25)         # Solve for this
#n = 52.3966 vs 33

#4 groups 
total_N <- 102
group_sizes <- c(17, 31, 26, 28)
k_groups <- length(group_sizes)
n_harmonic <- k_groups / sum(1 / group_sizes)

power_result <- pwr.anova.test(k = k_groups, 
                               n = n_harmonic, # Use the harmonic mean here
                               f = 0.25,       # Medium effect
                               sig.level = 0.05)

#power = 0.503
#sensitivity analysis 
min_effect <- pwr.anova.test(k = k_groups, 
                             n = n_harmonic, 
                             power = 0.80,     # Standard power
                             sig.level = 0.05, # Standard alpha
                             f = NULL)         # Solve for this
#f = 0.34 small effect 

min_sample_medium_4 <- pwr.anova.test(k = k_groups,   
                                      power = 0.80,     # Standard power
                                      sig.level = 0.05, # Standard alpha
                                      f = 0.25)         # Solve for this
#n = 44.59927 vs 24