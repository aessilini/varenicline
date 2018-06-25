************************** Descriptive statistics **************************



******************************** At inlusion ***********************************




describe

* Quantitave variable 
**********************

tabulate cov_sex dr_varenicline, chi2 expected co			
tabulate cov_charls_ever dr_varenicline, chi2 expected co	
tabulate cov_alcuse_ever dr_varenicline, chi2 expected co	
tabulate cov_drguse_ever dr_varenicline, chi2 expected co	
tabulate cov_sfharm_ever dr_varenicline, chi2 expected co	
tabulate cov_rament_ever dr_varenicline, chi2 expected co	
tabulate cov_depres_ever dr_varenicline, chi2 expected co	
tabulate cov_neurds_ever dr_varenicline, chi2 expected co	
tabulate cov_antdep_ever dr_varenicline, chi2 expected co	
tabulate cov_antpsy_ever dr_varenicline, chi2 expected co	
tabulate cov_hypanx_ever dr_varenicline, chi2 expected co	
tabulate cov_moodst_ever dr_varenicline, chi2 expected co 	
table dr_varenicline, contents(median cov_rxyear)

* Quatitative variable
***********************

sum cov_age, detail
sum cov_bmi, detail
sum cov_imd, detail
sum cov_gpvist, detail 
sum history, detail
sum follow_up, detail 
sum timey, detail 	

tabstat cov_age cov_bmi cov_imd cov_gpvist history follow_up diagtime, ///
by(dr_varenicline) stats(n mean sd min p25 med p75 max) 
tabstat cov_age cov_bmi cov_imd cov_gpvist history follow_up diagtime, ///
by(dr_varenicline) stats(mean sd) 


* Normality 
histogram cov_age, normal by(dr_varenicline)	
histogram cov_bmi, normal by(dr_varenicline) 	
histogram cov_imd, normal by(dr_varenicline)    
histogram cov_gpvist, normal by(dr_varenicline)
histogram history, normal by(dr_varenicline)    
histogram follow_up, normal by(dr_varenicline)

sfrancia cov_age	 
sfrancia cov_bmi 	
sfrancia cov_imd     
sfrancia cov_gpvist   
sfrancia history     
sfrancia follow_up   

* Test Mann-Whitney 
ranksum cov_age, by(dr_varenicline)		
ranksum cov_bmi, by(dr_varenicline)		
ranksum cov_imd, by(dr_varenicline)		
ranksum cov_gpvist, by(dr_varenicline) 
ranksum history, by(dr_varenicline)		 
ranksum follow_up, by(dr_varenicline)	
ranksum diagtime, by(dr_varenicline)	



****************************** Out_var & history *******************************


* Time between diagnosis and Rx
gen diagtime=Rx_eventdate-cov_cancer_eventdate

sum Rx_eventdate, format 
sum cov_cancer_eventdate, format

sum diagtime, detail
tabstat diagtime, by(dr_varenicline) stats(n mean sd min med max) 
ranksum diagtime, by(dr_varenicline)	

* Out_depress
gen out_depress_ever = 0 
replace out_depress_ever = 1 if out_depres_90 == 1 | out_depres_180 == 1 | out_depres_270 == 1 ///
| out_depres_365 == 1 | out_depres_730 == 1 | out_depres_1460 == 1 

tab out_depress_ever
tab out_depress_ever dr_varenicline, chi2 expected co	
 
* Out_hypanx
gen out_hypanx_ever = 0 
replace out_hypanx_ever = 1 if out_hypanx_90 == 1 | out_hypanx_180 == 1 | out_hypanx_270 == 1 ///
| out_hypanx_365 == 1 | out_hypanx_730 == 1 | out_hypanx_1460 == 1

tab out_hypanx_ever dr_varenicline, chi2 expected co	

 
* Out_antidepress
gen out_antdep_ever = 0 
replace out_antdep_ever = 1 if out_antdep_90 == 1 | out_antdep_180 == 1 | out_antdep_270 == 1 ///
| out_antdep_365 == 1 | out_antdep_730 == 1 | out_antdep_1460 == 1 

tab out_antdep_ever dr_varenicline, chi2 expected co	


* Out_neurds
gen out_neurds_ever = 0 
replace out_neurds_ever = 1 if out_neurds_90 == 1 | out_neurds_180 == 1 | out_neurds_270 == 1 ///
| out_neurds_365 == 1 | out_neurds_730 == 1 | out_neurds_1460 == 1 

tab out_neurds_ever dr_varenicline, chi2 expected co	 

* Out_sfharm 
gen out_sfharm_ever = 0 
replace out_sfharm_ever = 1 if out_sfharm_90 == 1 | out_sfharm_180 == 1 | out_sfharm_270 == 1 ///
| out_sfharm_365 == 1 | out_sfharm_730 == 1 | out_sfharm_1460 == 1 











