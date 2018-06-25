*************************** Propensity score ***********************************



* Step 1: ps estimation
************************

logit dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever ///
 cov_alcuse_ever cov_drguse_ever cov_sfharm_ever cov_rament_ever cov_depres_ever ///
 cov_neurds_ever cov_antdep_ever cov_hypanx_ever cov_antpsy_ever cov_moodst_ever diagtime

predict pscore, pr

* Step 2: matching algorithm
*****************************

psmatch2 dr_varenicline, pscore(pscore) outcome(death) common noreplacement caliper(0.1) /* nearest neighbor matching */ 

* Step 3: common support
*************************

psgraph 

* Step 4: matching quality 
***************************

pstest cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever ///
 cov_alcuse_ever cov_drguse_ever cov_sfharm_ever cov_rament_ever cov_depres_ever ///
 cov_neurds_ever cov_antdep_ever cov_hypanx_ever cov_antpsy_ever cov_moodst_ever diagtime, /*both*/ sum

/* ttest after matching non_significant + %bias after matching < 5% */ 

drop if _weight != 1



* Application
**************

logistic dr_varenicline cov_age
logistic dr_varenicline cov_age pscore

logistic dr_varenicline cov_sex
logistic dr_varenicline cov_sex pscore

logistic dr_varenicline cov_bmi
logistic dr_varenicline cov_bmi pscore

logistic dr_varenicline cov_imd
logistic dr_varenicline cov_imd pscore

logistic dr_varenicline cov_gpvist
logistic dr_varenicline cov_gpvist pscore

logistic dr_varenicline cov_charls_ever
logistic dr_varenicline cov_charls_ever pscore

logistic dr_varenicline cov_alcuse_ever
logistic dr_varenicline cov_alcuse_ever pscore

logistic dr_varenicline cov_drguse_ever
logistic dr_varenicline cov_drguse_ever pscore

logistic dr_varenicline cov_sfharm_ever
logistic dr_varenicline cov_sfharm_ever pscore

logistic dr_varenicline cov_rament_ever
logistic dr_varenicline cov_rament_ever pscore

logistic dr_varenicline cov_depres_ever
logistic dr_varenicline cov_depres_ever pscore

logistic dr_varenicline cov_neurds_ever
logistic dr_varenicline cov_neurds_ever pscore

logistic dr_varenicline cov_antdep_ever
logistic dr_varenicline cov_antdep_ever pscore

logistic dr_varenicline cov_antpsy_ever
logistic dr_varenicline cov_antpsy_ever pscore

logistic dr_varenicline cov_hypanx_ever
logistic dr_varenicline cov_hypanx_ever pscore

logistic dr_varenicline cov_moodst_ever
logistic dr_varenicline cov_moodst_ever pscore

logistic dr_varenicline diagtime
logistic dr_varenicline diagtime pscore


/* Save the dataset with only matched observations */ 


************************* Logistic regression **********************************



logistic smokebeh dr_varenicline pscore 



* Smoking status at 90, 180, 270, 360, 730 and 1460 days after Rx 
******************************************************************

logistic out_quit_90 dr_varenicline cov_sex cov_age cov_bmi cov_imd ///
	cov_charls_ever,
regsave dr_varenicline using "reg_out_quit_PS",detail(all) pval ci replace

foreach i in 180 270 365 730 1460{
	logistic out_quit_`i' dr_varenicline cov_sex cov_age cov_bmi cov_imd ///
		cov_charls_ever,
	regsave dr_varenicline using "reg_out_quit_PS",detail(all) pval ci append
	}
	
clear

use reg_out_quit_PS, clear 

* Conversion B in OR 

gen or = exp(coef)	

* Creation of "Days after quitting" variable 

gen days=90 if var == "out_quit_90:dr_varenicline"
replace days=180 if var == "out_quit_180:dr_varenicline"
replace days=270 if var == "out_quit_270:dr_varenicline"
replace days=365 if var == "out_quit_365:dr_varenicline"
replace days=730 if var == "out_quit_730:dr_varenicline"
replace days=1460 if var == "out_quit_1460:dr_varenicline"


save reg_out_quit_PS, replace


************************ Survival Analysis *************************************


gen exitdate=dod 
replace exitdate=mdy(9,30,2015) if exitdate==. 
format exitdate %d

stset exitdate, failure(death) origin(Rx_eventdate) id(patid)

* PH assumption
stcox pscore, scaledsch(sca*) 
estat phtest, log detail 

gen logt=log(_t) 
corr sca1 logt
twoway (scatter sca1 logt) (lfit sca1 logt) 

* Model 
stcox dr_varenicline pscore































































