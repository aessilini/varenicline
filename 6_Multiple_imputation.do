
************************* Multiple imputation **********************************


drop cancer cov_cancer365 medcode-cov_rxyear_9 out_depres_90-icdterm

gen exitdate=dod 
replace exitdate=mdy(9,30,2015) if exitdate >= . 
format exitdate %d

gen relapse = 0 
replace relapse = 1 if out_quit_90 == 0 | out_quit_180 == 0 | out_quit_270 == 0 ///
| out_quit_365 == 0 | out_quit_730 == 0 | out_quit_1460 ==0 


* Missing data 
***************

gen death = 1 if dod != . 
replace death = 0 if dod == .

* Multiple imputation 
**********************

mdesc cancer cov_age cov_sex cov_bmi cov_imd cov_charls_ever cov_alcuse_ever ///
cov_drguse_ever cov_sfharm_ever cov_rament_ever cov_rxyear cov_depres_ever ///
cov_neurds_ever cov_antdep_ever cov_antpsy_ever cov_hypanx_ever cov_moodst_ever


mi set mlong 

/* 3 variables created: 
		- _mi_miss: observations in the original dataset with missing values
		- _mi_m: imputation number. 0 for the original dataset
		- _mi_id: indicator for the observations in the original dataset and 
		          repeated across imputed dataset to mark the imputed observations */ 

mi misstable summarize cov_imd cov_bmi

mi misstable patterns cov_bmi cov_imd

foreach var of varlist missbmi - missimd{		 
display "`var'"									
ttest cov_drguse_ever, by(`var')				
}

* imputation phase 

mi register imputed cov_imd cov_bmi

mi register regular patid cov_age cov_sex cov_gpvist-death

mi impute mvn cov_imd cov_bmi = death cov_age cov_sex cov_charls_ever cov_alcuse_ever ///
 cov_drguse_ever cov_sfharm_ever cov_rament_ever cov_depres_ever cov_neurds_ever ///
 cov_antdep_ever cov_antpsy_ever cov_hypanx_ever cov_moodst_ever diagtime, add(10) rseed(1234) 
 
 
 
* analysis/pooling phase 

mi estimate, or: logistic relapse dr_varenicline cov_sex cov_age cov_bmi cov_imd 
regsave dr_varenicline using "reg_MI",detail(all) pval ci replace

mi stset exitdate, failure(death) origin(Rx_eventdate) id(patid) 

mi estimate, hr: stcox dr_varenicline  cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever diagtime, ///
tvc(diagtime cov_age) texp(ln(_t))





