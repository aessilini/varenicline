****************************** Adherence ***************************************



use course1_final, clear 
drop btw Rxcancer firstvar course_start1var course_end1var expo1var 
drop firstnrt course_start1nrt course_end1nrt expo1nrt nt cnrx

merge m:1 patid using full_cohort_cancer
drop qty ndd numdays numpacks packtype cancer cov_cancer_eventdate cov_cancer365 
drop medcode cov_cancer_icd staffid n_physician cov_rxyear cov_rxyear_1 
drop cov_rxyear_10 cov_rxyear_2 cov_rxyear_3 cov_rxyear_4 cov_rxyear_5
drop cov_rxyear_6 cov_rxyear_7 cov_rxyear_8 cov_rxyear_9 out_depres_90
drop out_depres_180 out_depres_270 out_depres_365 out_depres_730 out_depres_1460
drop out_hypanx_90 out_hypanx_180 out_hypanx_270 out_hypanx_365 out_hypanx_730
drop out_hypanx_1460 out_antdep_90 out_antdep_180 out_antdep_270 out_antdep_365
drop out_antdep_730 out_antdep_1460 out_neurds_90 out_neurds_180 out_neurds_270
drop out_neurds_365 out_neurds_730 out_neurds_1460 out_sfharm_90 out_sfharm_180
drop out_sfharm_270 out_sfharm_365 out_sfharm_730 out_sfharm_1460 pracid cause
drop cause1 cause2 cause3 cause4 cause5 cause6 cause7 cause8 cause9 cause10
drop cause11 cause12 cause13 cause14 cause15 readcode readterm icdterm icd
drop cancersite site head_icd cancer_head1 cancer_head2 cancer_head3 cancer_head4
drop cancer_head5 cancer_head6 cancer_head7 cancer_head8 cancer_head9 cancer_head10
drop cancer_head11 cancer_head12 cancer_head13 cancer_head14 cancer_head15 cancer_head16 _merge

merge m:m patid eventdate productname using fullcoursevar1

drop _merge cpills nt pills no fullc Rxcancer btw switch_ever switch_e switch qty
drop product cov_cancer_eventdate clinical_eventdate prodcode packtype numpacks numdays ndd 

keep if first == 1 

sort patid eventdate

by patid: gen no = _n 
by patid: gen nt = _N


*************** Relapse 


gen relapse = 0 
replace relapse = 1 if out_quit_90 == 0 | out_quit_180 == 0 | out_quit_270 == 0 ///
| out_quit_365 == 0 | out_quit_730 == 0 | out_quit_1460 ==0 

tab relapse FC if no == nt, chi2 co	

logistic relapse dr_varenicline cov_sex cov_age cov_bmi cov_imd 
logistic relapse i.group cov_sex cov_age cov_bmi cov_imd 

************** Cox 


keep if no == nt 

gen group = 1 if expo1 == 1 
replace group = 2 if expo1 == 2 & FC == 0
replace group = 3 if expo1 == 2 & FC == 1 

tab group, missing 

gen exitdate=dod 
replace exitdate=mdy(9,30,2015) if exitdate==. 
format exitdate %d

gen death = 0 if dod >= .
replace death = 1 if dod < .

* stset
stset exitdate, failure(death) origin(course_start1) id(patid) 

stcox i.group 

stcox dr_varenicline cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever diagtime, tvc(cov_age diagtime) texp(ln(_t))

stcox i.group cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever diagtime, tvc(cov_age diagtime) texp(ln(_t))
 
 
* 

use prescription0, clear 

keep patid qty eventdate productname treatment clinical_eventdate cov_cancer_eventdate dr_varenicline course start end expo course_start1

merge m:1 patid using full_cohort_cancer

drop Rx_eventdate medcode cov_cancer_icd staffid n_physician history follow_up 
drop cov_rxyear cov_rxyear_1 cov_rxyear_10 cov_rxyear_2 cov_rxyear_3 cov_rxyear_4 
drop cov_rxyear_5 cov_rxyear_6 cov_rxyear_7 cov_rxyear_8 cov_rxyear_9 out_quit_90
drop out_quit_180 out_quit_270 out_quit_365 out_quit_730 out_quit_1460 out_depres_90
drop out_depres_180 out_depres_270 out_depres_365 out_depres_730 out_depres_1460
drop out_hypanx_90 out_hypanx_180 out_hypanx_270 out_hypanx_365 out_hypanx_730
drop out_hypanx_1460 out_antdep_90 out_antdep_180 out_antdep_270 out_antdep_365
drop out_antdep_730 out_antdep_1460 out_neurds_90 out_neurds_180 out_neurds_270
drop out_neurds_365 out_neurds_730 out_neurds_1460 out_sfharm_90 out_sfharm_180
drop out_sfharm_270 out_sfharm_365 out_sfharm_730 out_sfharm_1460 pracid cause
drop cause1 cause2 cause3 cause4 cause5 cause6 cause7 cause8 cause9 cause10 cause11
drop cause12 cause13 cause14 cause15 readcode readterm icdterm _merge
drop cov_cancer365 icd cancersite site cancer_head1 cancer_head2 cancer_head3 cancer_head4
drop cancer_head5 cancer_head6 cancer_head7 cancer_head8 cancer_head9 cancer_head10
drop cancer_head11 cancer_head12 cancer_head13 cancer_head14 cancer_head15 cancer_head16

gen exitdate=dod 
replace exitdate=mdy(9,30,2015) if exitdate==. 
format exitdate %d

gen death = 0 if dod >= .
replace death = 1 if dod < .

stset exitdate, failure(death) origin(course_start1) id(patid) 

stcox expo cov_age cov_sex cov_bmi cov_imd cov_gpvist cov_charls_ever cov_alcuse_ever diagtime, tvc(cov_age diagtime) texp(ln(_t))


