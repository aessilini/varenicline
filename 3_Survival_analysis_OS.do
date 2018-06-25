*************************** Survival analysis **********************************


* Dates format
describe Rx_eventdate dod

* Event variable 
gen death=0 if dod==.
replace death=1 if dod<.

list patid dod death in 1/50

* Failtime
gen time=dod-Rx_eventdate
replace time=mdy(9,30,2015)-Rx_eventdate if time==.

list patid follow_up time death in 1/50 

gen exitdate=dod 
replace exitdate=mdy(9,30,2015) if exitdate==. 
format exitdate %d

list patid death dod exitdate in 1/20 


* stset
stset exitdate, failure(death) origin(Rx_eventdate) id(patid) 


*************************** Descriptive statistics *****************************


* Quantitave variable 

tabulate death dr_varenicline, chi2 expected co		
tabulate death cov_sex, chi2 expected co			
tabulate death cov_charls_ever, chi2 expected co	
tabulate death cov_alcuse_ever, chi2 expected co	 
tabulate death cov_drguse_ever, chi2 expected co	
tabulate death cov_sfharm_ever, chi2 expected co	
tabulate death cov_rament_ever, chi2 expected co	
tabulate death cov_depres_ever, chi2 expected co	
tabulate death cov_neurds_ever, chi2 expected co	
tabulate death cov_antdep_ever, chi2 expected co
tabulate death cov_antpsy_ever, chi2 expected co
tabulate death cov_hypanx_ever, chi2 expected co	
tabulate death cov_moodst_ever, chi2 expected co 	


* Quatitative variable 
tabstat cov_age cov_bmi cov_imd diagtime, by(death) stats(n mean sd min p25 med p75 max) 
tabstat cov_age cov_bmi cov_imd diagtime, by(death) stats(mean sd) 


	* Normality 
sfrancia cov_age	 
sfrancia cov_bmi 	
sfrancia cov_imd     
sfrancia cov_gpvist  
sfrancia diagtime

	* Test Mann-Whitney 
ranksum cov_age, by(death)		 
ranksum cov_bmi, by(death)		
ranksum cov_imd, by(death)		
ranksum cov_gpvist, by(death)	 
ranksum diagtime, by(death)		


* Kaplan-Meier curves 
**********************

sts graph, risktable ytitle(Cancer overall survival) xtitle(Days after prescription) scheme(s1mono) 

sts graph, by(dr_varenicline) risktable ytitle(Cancer overall survival) ytitle(, orientation(vertical) margin(large) justification(center) alignment(middle)) xtitle(Days after prescription) xtitle(, margin(medsmall)) clegend(on) scheme(s1mono)


****************************** Cox model ***************************************



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

* By diagtime
stcox diagtime  		

/* Selection of variables at p=<0.25 */ 


* PH assumption
****************

stcox cov_age cov_bmi cov_imd cov_gpvist diagtime, scaledsch(sca*) 
estat phtest, log detail 

* Age
gen logt=log(_t) 
corr sca1 logt
twoway (scatter sca1 logt) (lfit sca1 logt) 

* BMI
corr sca2 logt
twoway (scatter sca2 logt) (lfit sca2 logt) 

* IMD 
corr sca3 logt
twoway (scatter sca3 logt) (lfit sca3 logt) 

* GP visit
corr sca4 logt
twoway (scatter sca4 logt) (lfit sca4 logt) 

* Diagrime
corr sca5 logt
twoway (scatter sca5 logt) (lfit sca5 logt) 


* Collinearity 
***************

collin dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever cov_hypanx_ever diagtime

/* condiont index < 30, VIF < 2 and condition number < 30 = No collinearity */ 


* Multivariate model 
*********************

stcox dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever cov_hypanx_ever diagtime, ///
tvc(cov_age diagtime) texp(ln(_t))

* Elimination of cov_age
stcox dr_varenicline cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever cov_hypanx_ever diagtime, ///
tvc(diagtime) texp(ln(_t))

* Elimination of cov_hypanx_ever
stcox dr_varenicline cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever diagtime, ///
tvc(diagtime) texp(ln(_t))

* Multivariate model age forced 
stcox dr_varenicline  cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever diagtime, ///
tvc(diagtime cov_age) texp(ln(_t))


* Test of interaction 
**********************

* dr_varenicline cov_age
stcox dr_varenicline cov_age
estimates store a 
stcox dr_varenicline##c.cov_age
estimates store b 
lrtest a b 


******************************** Final model ***********************************


* Without interaction
stcox dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever diagtime, tvc(cov_age diagtime) texp(ln(_t))

* With interaction 
stcox cov_age cov_sex cov_gpvist dr_varenicline##c.cov_imd dr_varenicline##cov_charls_ever dr_varenicline##cov_alcuse_ever c.cov_bmi##cov_charls_ever diagtime, tvc(cov_age diagtime) texp(ln(_t)) 


* Test interaction in different model 
*************************************

* IMD
stcox dr_varenicline cov_age cov_sex cov_bmi cov_gpvist cov_charls_ever cov_alcuse_ever diagtime, tvc(cov_age diagtime) texp(ln(_t)) strata(cov_imd)
/*stcox dr_varenicline cov_bmi cov_gpvist cov_charls_ever cov_alcuse_ever, strata(cov_imd)*/

* Alcohol use
stcox dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever  diagtime if cov_alcuse_ever == 1, tvc(cov_age diagtime) texp(ln(_t)) 

stcox dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever diagtime if cov_alcuse_ever == 0, tvc(cov_age diagtime) texp(ln(_t))

* Charlson 
stcox dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_alcuse_ever diagtime if cov_charls_ever == 1, tvc(cov_age diagtime) texp(ln(_t)) 

stcox dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_alcuse_ever diagtime if cov_charls_ever == 0, tvc(cov_age diagtime) texp(ln(_t))










 