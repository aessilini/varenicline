**************************** Logistic regression **************************





* Create var smoking behaviour 
*******************************

gen relapsing_ever = 0 
replace relapsing_ever = 1 if out_quit_90 == 0 | out_quit_180 == 0 | out_quit_270 == 0 ///
| out_quit_365 == 0 | out_quit_730 == 0 | out_quit_1460 == 0 


* Descriptive summary 
**********************

tabulate dr_varenicline relapsing_ever	
tabulate cov_sex relapsing_ever			 
tabulate cov_charls_ever relapsing_ever	
tabulate cov_depres_ever relapsing_ever	
tabulate cov_alcuse_ever relapsing_ever	
tabulate cov_drguse_ever relapsing_ever	
tabulate cov_sfharm_ever relapsing_ever	
tabulate cov_rament_ever relapsing_ever	
tabulate cov_neurds_ever relapsing_ever	
tabulate cov_antdep_ever relapsing_ever	 
tabulate cov_antpsy_ever relapsing_ever	
tabulate cov_hypanx_ever relapsing_ever	
tabulate cov_moodst_ever relapsing_ever	  
tab relapsing_ever, sum(cov_bmi)
tab relapsing_ever, sum(cov_imd)
tab relapsing_ever, sum(cov_age)
tab relapsing_ever, sum(diagtime) 

* Univariate LR 
****************

logistic relapsing_ever dr_varenicline
regsave using reg_uni, replace 

* Multivariate LR
******************

logistic relapsing_ever dr_varenicline cov_sex cov_age cov_bmi cov_imd ///
cov_charls_ever cov_hypanx_ever cov_antdep_ever cov_neurds_ever cov_depres_ever diagtime


* Collinearity 
***************

collin dr_varenicline cov_sex cov_age cov_bmi cov_imd ///
cov_charls_ever cov_hypanx_ever cov_antdep_ever cov_neurds_ever cov_depres_ever diagtime

/* No collinearity VIF < 2 and condition number < 30 */ 

* Backward selection 
*********************

logistic relapsing_ever dr_varenicline cov_sex cov_age cov_bmi cov_imd ///
cov_charls_ever cov_hypanx_ever cov_antdep_ever cov_neurds_ever cov_depres_ever diagtime

/* Elinination of cov_depres_ever */ 
logistic relapsing_ever dr_varenicline cov_sex cov_age cov_bmi cov_imd ///
cov_charls_ever cov_hypanx_ever cov_neurds_ever diagtime

/* Elimination of cov_sex */ 
logistic relapsing_ever dr_varenicline cov_age cov_bmi cov_imd ///
cov_charls_ever cov_hypanx_ever cov_neurds_ever diagtime

/* Elimination of diagtime */ 
logistic relapsing_ever dr_varenicline cov_age cov_bmi cov_imd ///
cov_charls_ever cov_hypanx_ever cov_neurds_ever 

/* Elimination of cov_hypanx_ever */ 
logistic relapsing_ever dr_varenicline cov_age cov_bmi cov_imd ///
cov_charls_ever cov_neurds_ever 

/* Elimination of cov_age */ 
logistic relapsing_ever dr_varenicline cov_bmi cov_imd ///
cov_charls_ever cov_neurds_ever 

/* Elimination of dr_varenicline */ 
logistic relapsing_ever cov_bmi cov_imd ///
cov_charls_ever cov_neurds_ever 

/* Elimination of cov_neurds_ever */ 
logistic relapsing_ever cov_bmi cov_imd cov_charls_ever 

/* Elimination of cov_charls_ever */ 
logistic relapsing_ever cov_bmi cov_imd   

* dr_varenicline cov_sex cov_age forced into the model

logistic relapsing_ever dr_varenicline cov_sex cov_age cov_bmi cov_imd 
regsave using reg_multi, replace 

* Model specification
********************** 
	
linktest 		 
lroc 			
estat classification 	

* Goodness-of-fit 
	
estat gof, all			

* Linearity 
		
predict pr 
lowess relapsing_ever pr, addplot(function y=x, leg(off)) 


* Test of interaction 
**********************
	
* dr_varenicline cov_sex
logistic relapsing_ever dr_varenicline cov_sex 
estimates store a
logistic relapsing_ever dr_varenicline##cov_sex 
estimates store b
lrtest a b 
 

* dr_varenicline cov_age
logistic relapsing_ever dr_varenicline cov_age 
estimates store c
logistic relapsing_ever dr_varenicline##c.cov_age 
estimates store d
lrtest c d

* dr_varenicline cov_bmi
logistic relapsing_ever dr_varenicline cov_bmi 
estimates store e
logistic relapsing_ever dr_varenicline##c.cov_bmi 
estimates store f
lrtest e f

* dr_varenicline cov_imd
logistic relapsing_ever dr_varenicline cov_imd 
estimates store g
logistic relapsing_ever dr_varenicline##c.cov_imd 
estimates store h
lrtest g h

* cov_sex cov_age
logistic relapsing_ever cov_sex cov_age 
estimates store k
logistic relapsing_ever cov_sex##c.cov_age 
estimates store l
lrtest k l

* cov_sex cov_bmi
logistic relapsing_ever cov_sex cov_bmi 
estimates store m
logistic relapsing_ever cov_sex##c.cov_bmi 
estimates store n
lrtest m n

* cov_sex cov_imd
logistic relapsing_ever cov_sex cov_imd 
estimates store o
logistic relapsing_ever cov_sex##c.cov_imd 
estimates store p
lrtest o p

* cov_age cov_bmi
logistic relapsing_ever c.cov_age c.cov_bmi 
estimates store s
logistic relapsing_ever c.cov_age##c.cov_bmi 
estimates store t
lrtest s t

* cov_age cov_imd
logistic relapsing_ever c.cov_age c.cov_imd 
estimates store u
logistic relapsing_ever c.cov_age##c.cov_imd 
estimates store v
lrtest u v

* cov_bmi cov_imd
logistic relapsing_ever c.cov_bmi c.cov_imd 
estimates store y
logistic relapsing_ever c.cov_bmi##c.cov_imd 
estimates store z
lrtest y z


* Final model with interaction 
*******************************

logistic relapsing_ever dr_varenicline cov_sex cov_age cov_bmi cov_imd 

* Smoking status at 90, 180, 270, 360, 730 and 1460 days after Rx 
******************************************************************

logistic out_quit_90 dr_varenicline cov_sex cov_age cov_bmi cov_imd ///
	cov_charls_ever,
regsave dr_varenicline using "reg_out_quit",detail(all) pval ci replace

foreach i in 180 270 365 730 1460{
	logistic out_quit_`i' dr_varenicline cov_sex cov_age cov_bmi cov_imd ///
		cov_charls_ever,
	regsave dr_varenicline using "reg_out_quit",detail(all) pval ci append
	}
	
clear

use reg_out_quit, clear 

* Conversion B in OR 

gen or = exp(coef)	

* Creation of "Days after quitting" variable 

gen days=90 if var == "out_quit_90:dr_varenicline"
replace days=180 if var == "out_quit_180:dr_varenicline"
replace days=270 if var == "out_quit_270:dr_varenicline"
replace days=365 if var == "out_quit_365:dr_varenicline"
replace days=730 if var == "out_quit_730:dr_varenicline"
replace days=1460 if var == "out_quit_1460:dr_varenicline"


save reg_out_quit, replace

















