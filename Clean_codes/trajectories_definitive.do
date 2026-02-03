**********************************************************
*** Replicating MTX clusters in new CHARMS  ***
**********************************************************
*import dataset and make numeric 
 import delimited "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\Trajectories_07.2025\fullcharmscluster.csv", varnames(1)

 destring activejoints_t1 activejoints_t2 physicianglobal_t1 physicianglobal_t2 esr_t1 esr_t2 patientparentglobal_t1 patientparentglobal_t2 timepointdate_diff, replace ignore("NA")

*** Exclude if in CID/AJC=0 at MTX start ***

*Summarise remission/CID at baseline

*AJC=0

tab activejoints_t1

*JADAS10 CID

gen jadas10_ajc=activejoints_t1
replace jadas10_ajc=10 if activejoints_t1>10 & activejoints_t1!=.

gen jadas10_esr=esr_t1
replace jadas10_esr=120 if jadas10_esr>120 & jadas10_esr!=.
replace jadas10_esr=20 if jadas10_esr<20
replace jadas10_esr=jadas10_esr-20
replace jadas10_esr=jadas10_esr/10

gen jadas10_pga = physicianglobal_t1/10
gen jadas10_pge = patientparentglobal_t1/10

destring jadas10_ajc, replace force
destring jadas10_esr, replace force

gen jadas10 = jadas10_ajc + jadas10_esr + jadas10_pga + jadas10_pge

gen jadas10_cid = 1 if jadas10<=1
replace jadas10_cid = 0 if jadas10>1 & jadas10!=.

tab jadas10_cid

*Wallace CID (2004)
	*If they are dropped for AJC=0, all Wallace CID will be dropped

***Drop anyone with low disease at baseline except 
* L072 |savable 
* L075  savable 

drop if (activejoints_t1 == 0 | jadas10_cid == 1) & !(patientid == "L072" | patientid == "L075")

*How many have no JADAS data at any time point (won't be included in model)

gen has_jadas = (activejoints_t1 < . | activejoints_t2 < .) & (esr_t1 < . | esr_t2 < .) & (physicianglobal_t1 < . | physicianglobal_t2 < .) & (patientparentglobal_t1 < . | patientparentglobal_t2 < .)


list has_jadas if patientid == "L072" | patientid == "L075"


drop if has_jadas!=1

save "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\main_dataset.dta", replace

**************************************************************
*check how many patients have been eliminated from cluster 82
* Step 1: Load your main dataset
use "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\main_dataset.dta", clear

* Step 2: Load the CSV again and save as temp
import delimited "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\Working_files\all_traj.csv", clear
rename study_id patientid
tempfile traj
save `traj'

* Step 3: Reload your main dataset
use "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\main_dataset.dta", clear

* Step 4: Use joinby to find matches
joinby patientid using `traj'

* Step 5: Check which patientid values were matched
list patientid
**108 sono inclusi 


use "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\main_dataset.dta", clear

*Keep only vars of interest and reshape

keep patientid activejoints* physicianglobal* patientparentglobal* esr* timepointdate*

reshape long activejoints_t physicianglobal_t patientparentglobal_t esr_t, i(patientid) j(fup)

*Check timepointdate is in correct format 
gen timepointdate_t1_num = date(timepointdate_t1, "YMD")
gen timepointdate_t2_num = date(timepointdate_t2, "YMD")
format timepointdate_t1_num timepointdate_t2_num %td

* Generate new fup variable based on month from MTX
gen time_months = int(timepointdate_diff / 30.24)
replace time_months=0 if timepointdate_t1_num!=. & timepointdate_t2_num==.
replace time_months=0 if fup==1

drop timepointdat* fup

*drop if no outcomes at time point
drop if activejoints==. & physicianglobal==. & patientparentglobal==. & esr==.

*reshape wide again using new follow-up var

reshape wide activejoints_t physicianglobal_t patientparentglobal_t esr_t, i(patientid) j(time_months)

***************************************************************
**check charms108 eliminated 
save "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\main_dataset.dta", replace

* Step 1: Load the main dataset
use "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\main_dataset.dta", clear

* Step 2: Save it as a temporary file
tempfile main
save `main'

* Step 3: Load the CSV file
import delimited "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\Working_files\all_traj.csv", clear
rename study_id patientid

* Step 4: Merge with the main dataset
merge 1:m patientid using `main'

* Step 5: List patients not in the main dataset
list patientid if _merge == 1

** missing: A030, A051, A159 missing info esr at both timepoints 

****************************************************************************************************************************************
use "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\main_dataset.dta", clear

*Creat fup var for traj modelling

foreach i of numlist 0/11 {

gen has_fup`i' =`i'

}

*Multiply VAS variables by 10 to get mm

foreach i of numlist 0 3 4 5 6 7 8 9 10 11 {
foreach var in physicianglobal_t patientparentglobal_t {

replace `var'`i' = `var'`i'*10

}
}

*Log1p transform variables

foreach i of numlist 0 3 4 5 6 7 8 9 10 11 {
foreach var in activejoints_t physicianglobal_t patientparentglobal_t esr_t {

gen log_`var'`i' = `var'`i'+1
replace log_`var'`i' = log(log_`var'`i')

}
}

*Add Sam Norton's trajsum package

do "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\trajsum_s_norton.do"


*generate include variable so people with no data aren't assigened cluster
foreach i of numlist 0 3 4 5 6 7 8 9 10 11{

gen include`i'=1 if activejoints_t`i'!=. & physicianglobal_t`i'!=. & patientparentglobal_t`i'!=. & esr_t`i'!=.

}

gen include_model = 1 if include0==1|include3==1|include4==1|include5==1|include6==1|include7==1|include8==1|include9==1|include10==1|include11==1

**** Trajectory models ****
global projdir "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3"

	*1 group
/*Install traj*/
net install traj, from ("C:\Users\sejjl81\ado\plus\t") replace

	
local n=3

traj if include_model==1, multgroups(1) var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 log_activejoints_t11) indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 has_fup9 has_fup10 has_fup11) model(cnorm) order(1) min(0) max(6) var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 log_physicianglobal_t11) indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 has_fup9 has_fup10 has_fup11) model2(cnorm) order2(1) min2(0) max2(6) var3(log_patientparentglobal_t0 log_patientparentglobal_t3 log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 log_patientparentglobal_t10 log_patientparentglobal_t11) indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 has_fup9 has_fup10 has_fup11) model3(cnorm) order3(1) min3(0) max3(6) var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 has_fup9 has_fup10) model4(cnorm) order4(1) min4(0) max4(6)

trajsum


*newly write the code 

	*2 groups
	
local n=6


traj if include_model==1, multgroups(2) var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 log_activejoints_t11) indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 has_fup9 has_fup10 has_fup11) model(cnorm) order(1 1) min(0) max(6) var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 log_physicianglobal_t11) indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 has_fup9 has_fup10 has_fup11) model2(cnorm) order2(1 1) min2(0) max2(6) var3(log_patientparentglobal_t0 log_patientparentglobal_t3 log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 log_patientparentglobal_t10 log_patientparentglobal_t11) indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 has_fup9 has_fup10 has_fup11) model3(cnorm) order3(1 1) min3(0) max3(6) var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10 log_esr_t11) indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 has_fup9 has_fup10 has_fup11) model4(cnorm) order4(1 1) min4(0) max4(6) 


putexcel A`n' = (1) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel B`n' = (`i') using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



putexcel C`n' = (e(AIC)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N))using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")





sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



local n=`n'+1

trajsum

}


	*3 groups
	
local n=9

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(3) ///
var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 ///
log_activejoints_t11) ///
indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model(cnorm) ///
order(`i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 ///
log_physicianglobal_t11) ///
indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model2(cnorm) ///
order2(`i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10 log_patientparentglobal_t11) ///
indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model3(cnorm) ///
order3(`i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 ///
log_esr_t8 log_esr_t9 log_esr_t10 log_esr_t11) ///
indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model4(cnorm) ///
order4(`i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel B`n' = (`i') using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



putexcel C`n' = (e(AIC)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")




sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



local n=`n'+1

trajsum

}


	*4 groups
	
local n=12

foreach i in 1{

display as error `n'

traj if include_model==1, multgroups(4) ///
var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 ///
log_activejoints_t11) ///
indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model(cnorm) ///
order(`i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 ///
log_physicianglobal_t11) ///
indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model2(cnorm) ///
order2(`i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10 log_patientparentglobal_t11) ///
indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model3(cnorm) ///
order3(`i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 ///
log_esr_t8 log_esr_t9 log_esr_t10 log_esr_t11) ///
indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model4(cnorm) ///
order4(`i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel B`n' = (`i') using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



putexcel C`n' = (e(AIC)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")





sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean))using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


local n=`n'+1

trajsum

}

	*5 groups
	
local n=15

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(5) ///
var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 ///
log_activejoints_t11) ///
indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model(cnorm) ///
order( `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 ///
log_physicianglobal_t11) ///
indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model2(cnorm) ///
order2( `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10 log_patientparentglobal_t11) ///
indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model3(cnorm) ///
order3( `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 ///
log_esr_t8 log_esr_t9 log_esr_t10 log_esr_t11) ///
indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model4(cnorm) ///
order4( `i' `i' `i' `i' `i') ///
min4(0) max4(6) 

putexcel A`n' = (1) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel B`n' = (`i') using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel C`n' = (e(AIC)) using using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")





sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



local n=`n'+1

trajsum

}


	*6 groups
	
local n=18

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(6) ///
var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 ///
log_activejoints_t11) ///
indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model(cnorm) ///
order(`i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 ///
log_physicianglobal_t11) ///
indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model2(cnorm) ///
order2(`i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10 log_patientparentglobal_t11) ///
indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model3(cnorm) ///
order3(`i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 ///
log_esr_t8 log_esr_t9 log_esr_t10 log_esr_t11) ///
indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i' `i') ///
min4(0) max4(6) 



putexcel A`n' = (1) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel B`n' = (`i') using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



putexcel C`n' = (e(AIC)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N))using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N))using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")





sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



local n=`n'+1

trajsum

}


	*7 groups
	
local n=21

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(7) ///
var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 ///
log_activejoints_t11) ///
indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model(cnorm) ///
order(`i' `i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 ///
log_physicianglobal_t11) ///
indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model2(cnorm) ///
order2(`i' `i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10 log_patientparentglobal_t11) ///
indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model3(cnorm) ///
order3(`i' `i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 ///
log_esr_t8 log_esr_t9 log_esr_t10 log_esr_t11) ///
indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel B`n' = (`i') using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



putexcel C`n' = (e(AIC)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==7
putexcel K`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")





sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG7 if _traj_Group==7
putexcel AE`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


local n=`n'+1

trajsum

}


	*8 groups
	
local n=24

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(8) ///
var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 ///
log_activejoints_t11) ///
indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model(cnorm) ///
order( `i' `i' `i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 ///
log_physicianglobal_t11) ///
indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model2(cnorm) ///
order2( `i' `i' `i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10 log_patientparentglobal_t11) ///
indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model3(cnorm) ///
order3( `i' `i' `i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 ///
log_esr_t8 log_esr_t9 log_esr_t10 log_esr_t11) ///
indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model4(cnorm) ///
order4( `i' `i' `i' `i' `i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel B`n' = (`i') using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



putexcel C`n' = (e(AIC)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==7
putexcel K`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==8
putexcel L`n' = (r(N))using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")




sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


sum _traj_ProbG7 if _traj_Group==7
putexcel AE`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG8 if _traj_Group==8
putexcel AF`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



local n=`n'+1

trajsum

}


	*9 groups
	
local n=27

foreach i in 1  {

display as error `n'

traj if include_model==1, multgroups(9) ///
var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 ///
log_activejoints_t11) ///
indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model(cnorm) ///
order( `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 ///
log_physicianglobal_t11) ///
indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model2(cnorm) ///
order2( `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10 log_patientparentglobal_t11) ///
indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model3(cnorm) ///
order3( `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 ///
log_esr_t8 log_esr_t9 log_esr_t10 log_esr_t11) ///
indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel B`n' = (`i') using using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



putexcel C`n' = (e(AIC)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==7
putexcel K`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==8
putexcel L`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==9
putexcel M`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")





sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG7 if _traj_Group==7
putexcel AE`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG8 if _traj_Group==8
putexcel AF`n' = (r(mean)) uusing "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG9 if _traj_Group==9
putexcel AG`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



local n=`n'+1

trajsum

}

	*10 groups
	
local n=30

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(10) ///
var(log_activejoints_t0 log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10 ///
log_activejoints_t11) ///
indep(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model(cnorm) ///
order(`i' `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10 ///
log_physicianglobal_t11) ///
indep2(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model2(cnorm) ///
order2(`i' `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10 log_patientparentglobal_t11) ///
indep3(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model3(cnorm) ///
order3(`i' `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t3 log_esr_t4 log_esr_t5 log_esr_t6 log_esr_t7 ///
log_esr_t8 log_esr_t9 log_esr_t10 log_esr_t11) ///
indep4(has_fup0 has_fup3 has_fup4 has_fup5 has_fup6 has_fup7 has_fup8 ///
has_fup9 has_fup10 has_fup11) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


putexcel B`n' = (`i') using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



putexcel C`n' = (e(AIC)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==7
putexcel K`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==8
putexcel L`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==9
putexcel M`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



tab _traj_Group if _traj_Group==10
putexcel N`n' = (r(N)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")





sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")


sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean))using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG7 if _traj_Group==7
putexcel AE`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG8 if _traj_Group==8
putexcel AF`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG9 if _traj_Group==9
putexcel AG`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



sum _traj_ProbG10 if _traj_Group==10
putexcel AH`n' = (r(mean)) using "C:\Users\sejjl81\OneDrive - University College London\Documents\MTXtrajectory\SSW_3\traj_1.xlsx", modify sheet ("ls_run1")



local n=`n'+1

trajsum

}


************************************************
*** TRAJECTORIES: WITH ACTUAL MTX START DATE ***
************************************************

use "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CHARMS MTX validation.dta", clear

*Keep only vars of interest and reshape

keep patientid activejoints* physicianglobal* patientparentglobal* esr* ///
timepointdate*

reshape long activejoints_t physicianglobal_t patientparentglobal_t esr_t, ///
i(patientid) j(fup)

*merge actual MTX start date in 

merge m:m patientid using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CHARMS MTX actual start dates.dta"

*Keep if start date available

keep if _m==3
drop _m

drop if start_date==mdy(01,01,1901)
drop if start_date==mdy(01,02,1900)

*Count any T1 data where MTX start is before COV collection
	*These data don't need to be dropped - they just can't be counted as t1 they are follow-up

gen time_to_mtx = start_date - timepointdate_t1

*drop if time_to_mtx<0 & fup==1
*drop time_to_mtx

* Generate new fup variable based on month from MTX start
gen time_months=timepointdate_t1-start_date if fup==1
replace time_months = timepointdate_t2-start_date if fup==2
replace time_months=int(time_months/30.24)
replace time_months=0 if time_months<0 & time_months>=-3
drop if time_months<-3

*Drop any T2 data where COVs taken more than 14mo after MTX
drop if time_months>14

*Drop uneccesary vars for trajectories
drop timepointdat* fup start_date

*drop if no outcomes at time point
drop if activejoints==. & physicianglobal==. & patientparentglobal==. & esr==.

*reshape wide again using new follow-up var

reshape wide activejoints_t physicianglobal_t patientparentglobal_t esr_t, ///
i(patientid) j(time_months)

*Creat fup var for traj modelling

foreach i of numlist 0/10 {

gen has_fup`i' =`i'

}

*Multiply VAS variables by 10 to get mm

foreach i of numlist 0/10 {
foreach var in physicianglobal_t patientparentglobal_t {

replace `var'`i' = `var'`i'*10

}
}

*Log1p transform variables

foreach i of numlist 0/10 {
foreach var in activejoints_t physicianglobal_t patientparentglobal_t esr_t {

gen log_`var'`i' = `var'`i'+1
replace log_`var'`i' = log(log_`var'`i')

}
}

*Add Sam Norton's trajsum package

do "L:\arc\Projects\CAPS\Analyses\Stevie CLUSTER\Do files\trajsum_s_norton.do"


*generate include variable so people with no data aren't assigened cluster
foreach i of numlist 0/10{

gen include`i'=1 if activejoints_t`i'!=. & physicianglobal_t`i'!=. & ///
patientparentglobal_t`i'!=. & esr_t`i'!=.

}

gen include_model = 1 if include0==1|include3==1|include4==1|include5==1| ///
include6==1|include7==1|include8==1|include9==1|include10==1

**** Trajectory models ****

		*(NB I've removed ESR1 as no data across any person at this fup)
	*1 group
	
local n=3

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(1) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1 
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1 
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}


	*2 groups
	
local n=6

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(2) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}


	*3 groups
	
local n=9

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(3) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}


	*4 groups
	
local n=12

foreach i in 1{

display as error `n'

traj if include_model==1, multgroups(4) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i' `i' `i' `i') ///
min4(0) max4(6) 

putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}

	*5 groups
	
local n=15

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(5) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}


	*6 groups
	
local n=18

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(6) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i' `i') ///
min4(0) max4(6)  


putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}


	*7 groups
	
local n=21

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(7) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i' `i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i' `i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i' `i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==7
putexcel K`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG7 if _traj_Group==7
putexcel AE`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}


	*8 groups
	
local n=24

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(8) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i' `i' `i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i' `i' `i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i' `i' `i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==7
putexcel K`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==8
putexcel L`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG7 if _traj_Group==7
putexcel AE`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG8 if _traj_Group==8
putexcel AF`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}


	*9 groups
	
local n=27

foreach i in 1  {

display as error `n'

traj if include_model==1, multgroups(9) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==7
putexcel K`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==8
putexcel L`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==9
putexcel M`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG7 if _traj_Group==7
putexcel AE`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG8 if _traj_Group==8
putexcel AF`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG9 if _traj_Group==9
putexcel AG`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}

	*10 groups
	
local n=30

foreach i in 1 {

display as error `n'

traj if include_model==1, multgroups(10) ///
var(log_activejoints_t0 log_activejoints_t1 log_activejoints_t2 ///
log_activejoints_t3 log_activejoints_t4 ///
log_activejoints_t5 log_activejoints_t6 log_activejoints_t7 ///
log_activejoints_t8 log_activejoints_t9 log_activejoints_t10) ///
indep(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model(cnorm) ///
order(`i' `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min(0) max(6) ///
var2(log_physicianglobal_t0 log_physicianglobal_t1 log_physicianglobal_t2 ///
log_physicianglobal_t3 log_physicianglobal_t4 ///
log_physicianglobal_t5 log_physicianglobal_t6 log_physicianglobal_t7 ///
log_physicianglobal_t8 log_physicianglobal_t9 log_physicianglobal_t10) ///
indep2(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model2(cnorm) ///
order2(`i' `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min2(0) max2(6) ///
var3(log_patientparentglobal_t0 log_patientparentglobal_t1 ///
log_patientparentglobal_t2 log_patientparentglobal_t3 ///
log_patientparentglobal_t4 log_patientparentglobal_t5 log_patientparentglobal_t6 ///
log_patientparentglobal_t7 log_patientparentglobal_t8 log_patientparentglobal_t9 ///
log_patientparentglobal_t10) ///
indep3(has_fup0 has_fup1 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model3(cnorm) ///
order3(`i' `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min3(0) max3(6) ///
var4(log_esr_t0 log_esr_t2 log_esr_t3 log_esr_t4 log_esr_t5 ///
log_esr_t6 log_esr_t7 log_esr_t8 log_esr_t9 log_esr_t10) ///
indep4(has_fup0 has_fup2 has_fup3 has_fup4 has_fup5 has_fup6 ///
has_fup7 has_fup8 has_fup9 has_fup10) ///
model4(cnorm) ///
order4(`i' `i' `i' `i' `i' `i' `i' `i' `i' `i') ///
min4(0) max4(6) 


putexcel A`n' = (1) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")
putexcel B`n' = (`i') using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

putexcel C`n' = (e(AIC)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==1
putexcel E`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==2
putexcel F`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==3
putexcel G`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==4
putexcel H`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==5
putexcel I`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==6
putexcel J`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==7
putexcel K`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==8
putexcel L`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==9
putexcel M`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

tab _traj_Group if _traj_Group==10
putexcel N`n' = (r(N)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")



sum _traj_ProbG1 if _traj_Group==1
putexcel Y`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG2 if _traj_Group==2
putexcel Z`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG3 if _traj_Group==3
putexcel AA`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG4 if _traj_Group==4
putexcel AB`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG5 if _traj_Group==5
putexcel AC`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG6 if _traj_Group==6
putexcel AD`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG7 if _traj_Group==7
putexcel AE`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG8 if _traj_Group==8
putexcel AF`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG9 if _traj_Group==9
putexcel AG`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

sum _traj_ProbG10 if _traj_Group==10
putexcel AH`n' = (r(mean)) using "R:\Stephanie Shoop-Worrall\ANA012 - Trajectories MTX ETN\Data\MTX response\CLUSTER validation\CAPS MTX validation.xlsx", modify sheet ("CHARMS MTX dates")

local n=`n'+1

trajsum

}


