*************************** Sensitivity Analysis *******************************




gen exitdate=dod 
replace exitdate=mdy(9,30,2015) if exitdate==. 
format exitdate %d


* stset
stset exitdate, failure(death) origin(cov_cancer_eventdate) id(patid) 


* Univariate model 
*******************

* By Rx 
sts graph, by(dr_varenicline)
stcox dr_varenicline	

* By age 
stcox cov_age			

* By sex
stcox cov_sex		

* By BMI
stcox cov_bmi		

* By IMD
stcox cov_imd		

* By GP 
stcox cov_gpvist	

* By Charlson 
stcox cov_charls_ever	

* By alcuse
stcox cov_alcuse_ever	

* By druguse 
stcox cov_drguse_ever	

* By selfharm
stcox cov_sfharm_ever	 

* By rarement
stcox cov_rament_ever	

* By depress
stcox cov_depres_ever	

* By neurds
stcox cov_neurds_ever 

* By antidep
stcox cov_antdep_ever	

* By antipsy
stcox cov_antpsy_ever 

* By hypanx
stcox cov_hypanx_ever	

* By moodst  
stcox cov_moodst_ever	

/* Selection of 10 variables at p=<0.25 */


* PH assumption
****************

stcox cov_age cov_bmi cov_imd cov_gpvist, scaledsch(sca*) 
estat phtest, log detail 

* Age
gen logt=log(_t) 
corr sca1 logt

* BMI
corr sca2 logt
twoway (scatter sca2 logt) (lfit sca2 logt) 

* IMD 
corr sca3 logt
twoway (scatter sca3 logt) (lfit sca3 logt) 

* GP visit
corr sca4 logt
twoway (scatter sca4 logt) (lfit sca4 logt) 



* Collinearity 
***************

collin dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever cov_hypanx_ever 
/* condiont index < 30, VIF < 2 and condition number < 30 = No collinearity */ 



* Multivariate model 
*********************

stcox dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever cov_hypanx_ever, ///
tvc(cov_age) texp(ln(_t))

* Backward elimination
***********************

* Elimination of cov_hypanx_ever
stcox dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever, ///
tvc(cov_age) texp(ln(_t))

* Elimination of cov_sex
stcox dr_varenicline cov_age cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever, ///
tvc(cov_age) texp(ln(_t))

* Elimination of cov_gpvist
stcox dr_varenicline cov_age cov_bmi cov_imd cov_charls_ever cov_alcuse_ever, ///
tvc(cov_age) texp(ln(_t))

* Elimination of cov_gpvist
stcox dr_varenicline  cov_bmi cov_imd cov_charls_ever cov_alcuse_ever

* Multivariate model age and sex forced 
stcox dr_varenicline  cov_age cov_sex cov_bmi cov_imd cov_charls_ever cov_alcuse_ever, ///
tvc(diagtime cov_age) texp(ln(_t))






