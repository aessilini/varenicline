************************** Utilisation *****************************************



* Prescription file 
use cancer_patients_smoking_cessation, clear 

merge m:1 prodcode using nrt 
rename _merge NRT_merge

merge m:1 prodcode using varenicline 
rename _merge varenciline_merge

merge m:1 patid using cancer_patients3
keep if _merge == 3 

save CPRX 

use CPRX, clear

keep patid prodcode clinical_eventdate productname varenicline cov_cancer_eventdate dr_varenicline cov_age cov_sex Rx_eventdate dod

gen Rxcancer = clinical_eventdate - Rx_eventdate

drop if Rxcancer<0 
drop if prodcode == . 

* Treatment name
gen product = 1 if varenicline == 1
replace product = 0 if varenicline == . 

label define product  0 "NRT" 1 "Varenicline"
label value product product

********************************** Switch **************************************

* Switch ever 
/* use CPRX, clear */ 
sort patid clinical_eventdate
by patid: gen no = _n
gen switch = 1 if product != dr_varenicline 
replace switch = 0 if product == dr_varenicline
by patid: gen switch_e = sum(switch)
by patid: gen nt = _N
gen switch_ever = 1 if switch >= 1 & no == nt
tab switch_ever  
tab switch_ever dr_varenicline

* Avergae number of Rx
sum(nt) if no == nt 

* Number of prescription per year of follow up 
gen year = year(clinical_eventdate)
tab year 
sort patid year
by patid year: egen numrx = count(product)

by patid year: gen _nrx = _n 

save CPRX, replace 

keep if _nrx == numrx
drop _nrx

by patid: gen no1 = _n 

bysort year: sum(numrx), detail 

********************************************************************************
****************************** Adherence ***************************************
********************************************************************************



use cancer_patients_rx_product_name2, clear

merge m:m patid using CPRX 
keep if _merge == 3 

drop varenicline cov_age cov_sex dod no nt year numrx _nrx _merge Rxcancer 

gen Rxcancer = eventdate - Rx_eventdate
drop if Rxcancer<0 /* Rx before entry cohort */ 

gen year = year(clinical_eventdate)
tab year treatment 

save RxPN, replace 
	
	
	
******************************* First course 



******* Varenicline 
	
sort patid eventdate
by patid: gen no = _n
keep if treatment == "varenicline" & no == 1 & dr_varenicline == 1 
gen fullc = eventdate + 84 
format fullc %d
save varcourse1, replace

use RxPN, clear

/* keep if dr_varenicline == 1 */ 

keep if treatment == "varenicline"
merge m:1 patid using varcourse1
drop _merge 

sort patid eventdate

drop no
by patid: gen no = _n 

gen first = 1 if treatment == "varenicline" & no == 1
replace first = 0 if fullc >= . 
by patid: replace first = 1 if eventdate < fullc & fullc < . & treatment == "varenicline" 
by patid: replace first = 0 if eventdate < fullc & treatment == "NRT" 
by patid: replace first = 0 if eventdate >= fullc | treatment == "NRT"

tab first, missing

by patid: gen  pills = sum(qty) if first == 1 & treatment == "varenicline"
by patid: replace pills = 0 if first == 0 
save Rxvar, replace

by patid: gen nt = _N
egen cpills=max(pills), by(patid)

tab cpills if nt == no 
sum cpills if cpills != 0 & nt == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if nt == no, missing

save fullcoursevar1, replace 

use Rxvar, clear

sort patid eventdate

drop prodcode clinical_eventdate cov_cancer_eventdate Rx_eventdate switch switch_e product

keep if first == 1 

by patid: gen nvar = _n if first == 1
by patid: egen nvart = max(nvar) if first == 1

gen course_start1var = eventdate if first == 1 & nvar == 1 
gen course_end1var = eventdate if first == 1 & nvar == nvart 
by patid: replace course_start1var = course_start1var[_n-1] if course_start1var >= . & first == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end1var = course_end1var[_n+1] if course_end1var >= . & first == 1 
	}
gen expo1var = 2 if first == 1
format course_start1var course_end1var %d
drop fullc pills switch_ever no nvar nvart

save coursevar1, replace

use Rxvar, clear
merge m:m patid eventdate productname using coursevar1
drop _merge 
sort patid eventdate
drop fullc pills switch_ever no  
drop prodcode clinical_eventdate cov_cancer_eventdate Rx_eventdate switch switch_e product
save coursevar1_b, replace

******* NRT 
	
use RxPN, clear

sort patid eventdate
by patid: gen no = _n 

keep if treatment == "NRT" & no == 1 
gen fullc = eventdate + 90 
format fullc %d
drop cov_cancer_eventdate 
save nrtcourse1, replace

use RxPN, clear
keep if dr_varenicline == 0 
merge m:1 patid using nrtcourse1
drop _merge

sort patid eventdate

by patid: gen firstnrt = 1 if eventdate < fullc & treatment == "NRT"
by patid: replace firstnrt = 0 if eventdate >= fullc | treatment == "varenicline"
by patid: replace firstnrt = 0 if eventdate < fullc & treatment == "varenicline"
by patid: replace firstnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab firstnrt

by patid: gen  nrx = sum(firstnrt) if firstnrt == 1 & treatment == "NRT"
by patid: replace nrx = 0 if firstnrt == 0 | treatment == "varenicline"

save Rxnrt, replace

by patid: gen nvar = _n if first == 1
by patid: egen nvart = max(nvar) if first == 1


gen course_start1nrt = eventdate if firstnrt == 1  & nvar == 1 
by patid: replace course_start1nrt = course_start1nrt[_n-1] if course_start1nrt >= . & firstnrt == 1 
gen course_end1nrt = eventdate if first == 1 & nvar == nvart 
forvalues  i= 1(1)20{
	by patid: replace course_end1nrt = course_end1nrt[_n+1] if course_end1nrt >= . & firstnrt == 1 
	}
gen expo1nrt = 1 if firstnrt == 1 
format course_start1nrt course_end1nrt %d
drop prodcode clinical_eventdate cov_cancer_eventdate product switch switch_e switch_ever fullc nrx nvar nvart

by patid: replace firstnrt = . if expo1nrt == 1 & course_start1nrt >= . 
by patid: gen nend = _n if firstnrt == 1 
by patid: egen ntend = max(nend) if firstnrt == 1 
by patid: replace course_end1nrt = eventdate if nend == ntend & firstnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end1nrt = course_end1nrt[_n+1] if course_end1nrt >= . & firstnrt == 1 
	}
tab firstnrt

by patid: gen  nrx = sum(firstnrt) if firstnrt == 1 & treatment == "NRT"
by patid: replace nrx = 0 if firstnrt == 0 | treatment == "varenicline"

drop no nt 
by patid: gen no = _n 
by patid: gen nt = _N
by patid: egen cnrx = max(nrx)  

tab cnrx if no == nt 
sum cnrx if no == nt& cnrx != 0, detail

drop nrx

save course1_nrt, replace 


keep if no == nt 

tab cnrx
sum cnrx, detail

keep if first == 1 
encode treatment, gen(ttt) 
gen switch1 = 1 if dr_varenicline != ttt 
replace switch1 = 0 if dr_varenicline == ttt
merge m:1 productname using Rxsc
keep if _merge == 3
drop qty_fullc time_fullc _merge 

sort patid eventdate

gen nicotine = qty*nicotine_mg



use RxPN, clear
merge m:m patid eventdate productname using coursevar1_b
drop _merge 
merge m:m patid eventdate productname using course1_nrt
drop _merge
drop prodcode clinical_eventdate cov_cancer_eventdate Rx_eventdate product switch switch_e switch_ever nend 

sort patid eventdate

rename first firstvar

gen first = 1 if firstvar == 1 
replace first = 0 if firstvar == 0
replace first = 1 if firstnrt == 1 
replace first = 0 if firstnrt == 0 
replace first = 0 if firstnrt >= . & firstvar >=.  

tab first, missing

drop no

gen course_start1 = course_start1var if firstvar == 1 
replace course_start1 = course_start1nrt if firstnrt == 1 & course_start1var >= . 

gen course_end1 = course_end1var if firstvar == 1 
replace course_end1 = course_end1nrt if firstnrt == 1 & course_end1var >=. 

format course_start1 course_end1  %d

gen expo1 = expo1var if firstvar == 1 
replace expo1 = expo1nrt if firstnrt == 1

tab expo1, missing 

save course1_final, replace 

keep if first == 0 

by patid: gen no = _n 

save course2, replace 


******************************* Course 2 


*******	NRT
	
use course2, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen secondnrt = 1 if treatment == "NRT" & no == 1
replace secondnrt = 0 if fullc >= . 
by patid: replace secondnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace secondnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace secondnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab secondnrt, missing

by patid: gen  nrtx = sum(secondnrt) if secondnrt == 1
by patid: replace nrtx = 0 if secondnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if secondnrt == 1
by patid: egen nvart = max(nvar) if secondnrt == 1

save course2nrt, replace

keep if secondnrt == 1 

gen course_start2nrt = eventdate if secondnrt == 1  & nvar == 1 
by patid: replace course_start2nrt = course_start2nrt[_n-1] if course_start2nrt >= . & secondnrt == 1 
gen course_end2nrt = eventdate if secondnrt == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end2nrt = course_end2nrt[_n+1] if course_end2nrt >= . & secondnrt == 1 
	}
gen expo2nrt = 1 if secondnrt == 1 
format course_start2nrt course_end2nrt %d

by patid: replace secondnrt = . if expo2nrt == 1 & course_start2nrt >= . 
by patid: gen nend = _n if secondnrt == 1 
by patid: egen ntend = max(nend) if secondnrt == 1 
by patid: replace course_end2nrt = eventdate if nend == ntend & secondnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end2nrt = course_end2nrt[_n+1] if course_end2nrt >= . & secondnrt == 1 
	}

tab secondnrt

drop nrtx

by patid: gen  nrtx = sum(secondnrt) if secondnrt == 1
by patid: replace nrtx = 0 if secondnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail


save course2_nrt, replace


******* Varenicline  
	
use course2nrt, clear

drop btw Rxcancer firstvar course_start1var course_end1var expo1var firstnrt nt 
drop course_start1nrt course_end1nrt expo1nrt no fullc nrtx no_nrtx nt_nrtx cnrtx  

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if secondnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen secondvar = 1 if treatment == "varenicline" & nv == 1
replace secondvar = 0 if fullc2 >= . 
by patid: replace secondvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace secondvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace secondvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab secondvar, missing 

by patid: gen  pills = sum(qty) if secondvar == 1 
by patid: replace pills = 0 if secondvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing
tab FC, missing

drop nvar nvart
by patid: gen nvar = _n if secondvar == 1
by patid: egen nvart = max(nvar) if secondvar == 1

keep if secondvar == 1

gen course_start2var = eventdate if secondvar == 1  & nvar == 1 
by patid: replace course_start2var = course_start2var[_n-1] if course_start2var >= . & secondvar == 1 
by patid: replace course_start2var = course_start2var[_n == 1] if course_start2var >= . & secondvar == 1 
gen course_end2var = eventdate if secondvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end2var = course_end2var[_n+1] if course_end2var >= . & secondvar == 1 
	}
gen expo2var = 2 if secondvar == 1 
format course_start2var course_end2var %d

save course2_var, replace

use course2, clear 
drop btw Rxcancer firstvar course_start1var course_end1var expo1var firstnrt nt 
drop cnrx course_start1nrt course_end1nrt expo1nrt first course_start1 course_end1 expo1 no
merge m:m patid eventdate productname using course2_nrt
drop _merge 
merge m:m patid eventdate productname using course2_var
drop btw Rxcancer firstvar course_start1var course_end1var expo1var firstnrt nt 
drop cnrx course_start1nrt course_end1nrt expo1nrt first course_start1 course_end1 expo1 no
drop fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen second = 1 if secondvar == 1 
replace second = 0 if secondvar >= .
replace second = 1 if secondnrt == 1 
replace second = 0 if secondnrt == 0 & secondvar >= .

tab second, missing

gen course_start2 = course_start2var if secondvar == 1 
replace course_start2 = course_start2nrt if secondnrt == 1 & course_start2var >= . 

gen course_end2 = course_end2var if secondvar == 1 
replace course_end2 = course_end2nrt if secondnrt == 1 & course_end2var >= . 

format course_start2 course_end2  %d

gen expo2 = expo2var if secondvar == 1 
replace expo2 = expo2nrt if secondnrt == 1
tab expo2, missing

save course2_final, replace

keep if second == 0 

by patid: gen no = _n 

drop secondnrt course_start2nrt course_end2nrt expo2nrt secondvar course_start2var 
drop course_end2var expo2var course_start2 course_end2 expo2

save course3, replace



******************************* Course 3 

		
******* NRT


use course3, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen thirdnrt = 1 if treatment == "NRT" & no == 1
replace thirdnrt = 0 if fullc >= . 
by patid: replace thirdnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace thirdnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace thirdnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab thirdnrt, missing

by patid: gen  nrtx = sum(thirdnrt) if thirdnrt == 1
by patid: replace nrtx = 0 if thirdnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if thirdnrt == 1
by patid: egen nvart = max(nvar) if thirdnrt == 1

save course3nrt, replace

keep if thirdnrt == 1 

gen course_start3nrt = eventdate if thirdnrt == 1  & nvar == 1 
by patid: replace course_start3nrt = course_start3nrt[_n-1] if course_start3nrt >= . & thirdnrt == 1 
gen course_end3nrt = eventdate if thirdnrt == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end3nrt = course_end3nrt[_n+1] if course_end3nrt >= . & thirdnrt == 1 
	}
gen expo3nrt = 1 if thirdnrt == 1 
format course_start3nrt course_end3nrt %d

by patid: replace thirdnrt = . if expo3nrt == 1 & course_start3nrt >= . 
by patid: gen nend = _n if thirdnrt == 1 
by patid: egen ntend = max(nend) if thirdnrt == 1 
by patid: replace course_end3nrt = eventdate if nend == ntend & thirdnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end3nrt = course_end3nrt[_n+1] if course_end3nrt >= . & thirdnrt == 1 
	}
	
tab thirdnrt

drop nrtx

by patid: gen  nrtx = sum(thirdnrt) if thirdnrt == 1
by patid: replace nrtx = 0 if thirdnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course3_nrt, replace


******* Varenicline  
	
use course3nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if thirdnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen thirdvar = 1 if treatment == "varenicline" & nv == 1
replace thirdvar = 0 if fullc2 >= . 
by patid: replace thirdvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace thirdvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace thirdvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab thirdvar, missing 

by patid: gen  pills = sum(qty) if thirdvar == 1 
by patid: replace pills = 0 if thirdvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if thirdvar == 1
by patid: egen nvart = max(nvar) if thirdvar == 1

keep if thirdvar == 1

gen course_start3var = eventdate if thirdvar == 1  & nvar == 1 
by patid: replace course_start3var = course_start3var[_n-1] if course_start3var >= . & thirdvar == 1 
by patid: replace course_start3var = course_start3var[_n == 1] if course_start3var >= . & thirdvar == 1 
gen course_end3var = eventdate if thirdvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end3var = course_end3var[_n+1] if course_end3var >= . & thirdvar == 1 
	}
gen expo3var = 2 if thirdvar == 1 
format course_start3var course_end3var %d

save course3_var, replace



use course3, clear 

merge m:m patid eventdate productname using course3_nrt
drop _merge 
merge m:m patid eventdate productname using course3_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen third = 1 if thirdvar == 1 
replace third = 0 if thirdvar >= .
replace third = 1 if thirdnrt == 1 
replace third = 0 if thirdnrt == 0 & thirdvar >= .

tab third, missing

gen course_start3 = course_start3var if thirdvar == 1 
replace course_start3 = course_start3nrt if thirdnrt == 1 & course_start3var >= . 

gen course_end3 = course_end3var if thirdvar == 1 
replace course_end3 = course_end3nrt if thirdnrt == 1 & course_end3var >= . 

format course_start3 course_end3  %d

gen expo3 = expo3var if thirdvar == 1 
replace expo3 = expo3nrt if thirdnrt == 1
tab expo3, missing

save course3_final, replace 

keep if third == 0 

by patid: gen no = _n 

drop second thirdnrt course_start3nrt course_end3nrt expo3nrt thirdvar 
drop course_start3var course_end3var expo3var course_start3 course_end3 expo3

save course4, replace 



******************************* Course 4 

******* NRT 
	
use course4, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen fourthnrt = 1 if treatment == "NRT" & no == 1
replace fourthnrt = 0 if fullc >= . 
by patid: replace fourthnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace fourthnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace fourthnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab fourthnrt, missing

by patid: gen  nrtx = sum(fourthnrt) if fourthnrt == 1
by patid: replace nrtx = 0 if fourthnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if fourthnrt == 1
by patid: egen nvart = max(nvar) if fourthnrt == 1

save course4nrt, replace

keep if fourthnrt == 1 

gen course_start4nrt = eventdate if fourthnrt == 1  & nvar == 1 
by patid: replace course_start4nrt = course_start4nrt[_n-1] if course_start4nrt >= . & fourthnrt == 1 
gen course_end4nrt = eventdate if fourthnrt == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end4nrt = course_end4nrt[_n+1] if course_end4nrt >= . & fourthnrt == 1 
	}
gen expo4nrt = 1 if fourthnrt == 1 
format course_start4nrt course_end4nrt %d

by patid: replace fourthnrt = . if expo4nrt == 1 & course_start4nrt >= . 
by patid: gen nend = _n if fourthnrt == 1 
by patid: egen ntend = max(nend) if fourthnrt == 1 
by patid: replace course_end4nrt = eventdate if nend == ntend & fourthnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end4nrt = course_end4nrt[_n+1] if course_end4nrt >= . & fourthnrt == 1 
	}

tab fourthnrt

drop nrtx

by patid: gen  nrtx = sum(fourthnrt) if fourthnrt == 1
by patid: replace nrtx = 0 if fourthnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course4_nrt, replace


******* Varenicline  
	
use course4nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if fourthnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen fourthvar = 1 if treatment == "varenicline" & nv == 1
replace fourthvar = 0 if fullc2 >= . 
by patid: replace fourthvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace fourthvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace fourthvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab fourthvar, missing 

by patid: gen  pills = sum(qty) if fourthvar == 1 
by patid: replace pills = 0 if fourthvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if fourthvar == 1
by patid: egen nvart = max(nvar) if fourthvar == 1

keep if fourthvar == 1

gen course_start4var = eventdate if fourthvar == 1  & nvar == 1 
by patid: replace course_start4var = course_start4var[_n-1] if course_start4var >= . & fourthvar == 1 

gen course_end4var = eventdate if fourthvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end4var = course_end4var[_n+1] if course_end4var >= . & fourthvar == 1 
	}
gen expo4var = 2 if fourthvar == 1 
format course_start4var course_end4var %d

save course4_var, replace



use course4, clear 

merge m:m patid eventdate productname using course4_nrt
drop _merge 
merge m:m patid eventdate productname using course4_var
drop third no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen fourth = 1 if fourthvar == 1 
replace fourth = 0 if fourthvar >= .
replace fourth = 1 if fourthnrt == 1 
replace fourth = 0 if fourthnrt == 0 & fourthvar >= .

tab fourth, missing

gen course_start4 = course_start4var if fourthvar == 1 
replace course_start4 = course_start4nrt if fourthnrt == 1 & course_start4var >= .

gen course_end4 = course_end4var if fourthvar == 1 
replace course_end4 = course_end4nrt if fourthnrt == 1 & course_end4var >= . 

format course_start4 course_end4 %d

gen expo4 = expo4var if fourthvar == 1 
replace expo4 = expo4nrt if fourthnrt == 1
tab expo4, missing

save course4_final, replace 

keep if fourth == 0

by patid: gen no = _n 

drop fourthnrt course_start4nrt course_end4nrt expo4nrt fourthvar 
drop course_start4var course_end4var expo4var

save course5, replace 

******************************* Course 5 



******* NRT 
	
use course5, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen fifthnrt = 1 if treatment == "NRT" & no == 1
replace fifthnrt = 0 if fullc >= . 
by patid: replace fifthnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace fifthnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace fifthnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab fifthnrt, missing

by patid: gen  nrtx = sum(fifthnrt) if fifthnrt == 1
by patid: replace nrtx = 0 if fifthnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if fifthnrt == 1
by patid: egen nvart = max(nvar) if fifthnrt == 1

save course5nrt, replace

keep if fifthnrt == 1 

gen course_start5nrt = eventdate if fifthnrt == 1  & nvar == 1 
by patid: replace course_start5nrt = course_start5nrt[_n-1] if course_start5nrt >= . & fifthnrt == 1 
gen course_end5nrt = eventdate if fifthnrt == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end5nrt = course_end5nrt[_n+1] if course_end5nrt >= . & fifthnrt == 1 
	}
gen expo5nrt = 1 if fifthnrt == 1 
format course_start5nrt course_end5nrt %d

by patid: replace fifthnrt = . if expo5nrt == 1 & course_start5nrt >= . 
by patid: gen nend = _n if fifthnrt == 1 
by patid: egen ntend = max(nend) if fifthnrt == 1 
by patid: replace course_end5nrt = eventdate if nend == ntend & fifthnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end5nrt = course_end5nrt[_n+1] if course_end5nrt >= . & fifthnrt == 1 
	}

tab fifthnrt

drop nrtx

by patid: gen  nrtx = sum(fifthnrt) if fifthnrt == 1
by patid: replace nrtx = 0 if fifthnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course5_nrt, replace



******* Varenicline  
	
use course5nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if fifthnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen fifthvar = 1 if treatment == "varenicline" & nv == 1
replace fifthvar = 0 if fullc2 >= . 
by patid: replace fifthvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace fifthvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace fifthvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab fifthvar, missing 

by patid: gen  pills = sum(qty) if fifthvar == 1 
by patid: replace pills = 0 if fifthvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if fifthvar == 1
by patid: egen nvart = max(nvar) if fifthvar == 1

keep if fifthvar == 1

gen course_start5var = eventdate if fifthvar == 1  & nvar == 1 
by patid: replace course_start5var = course_start5var[_n-1] if course_start5var >= . & fifthvar == 1 

gen course_end5var = eventdate if fifthvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end5var = course_end5var[_n+1] if course_end5var >= . & fifthvar == 1 
	}
gen expo5var = 2 if fifthvar == 1 
format course_start5var course_end5var %d

save course5_var, replace


use course5, clear 

merge m:m patid eventdate productname using course5_nrt
drop _merge 
merge m:m patid eventdate productname using course5_var
drop fourth course_start4 course_end4 expo4 no fullc nrtx no_nrtx nt_nrtx cnrtx 
drop nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen fifth = 1 if fifthvar == 1 
replace fifth = 0 if fifthvar >= .
replace fifth = 1 if fifthnrt == 1 
replace fifth = 0 if fifthnrt == 0 & fifthvar >= .

tab fifth, missing

gen course_start5 = course_start5var if fifthvar == 1 
replace course_start5 = course_start5nrt if fifthnrt == 1 & course_start5var >= . 

gen course_end5 = course_end5var if fifthvar == 1 
replace course_end5 = course_end5nrt if fifthnrt == 1 & course_end5var >= . 

format course_start5 course_end5 %d

gen expo5 = expo5var if fifthvar == 1 
replace expo5 = expo5nrt if fifthnrt == 1
tab expo5, missing

save course5_final, replace 

keep if fifth == 0

by patid: gen no = _n 

drop fifthnrt course_start5nrt course_end5nrt expo5nrt fifthvar course_start5var 
drop course_end5var expo5var course_start5 course_end5 expo5

save course6, replace 

******************************* Course 6



******* NRT 
	
use course6, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen sixthnrt = 1 if treatment == "NRT" & no == 1
replace sixthnrt = 0 if fullc >= . 
by patid: replace sixthnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace sixthnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace sixthnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab sixthnrt, missing

by patid: gen  nrtx = sum(sixthnrt) if sixthnrt == 1
by patid: replace nrtx = 0 if sixthnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if sixthnrt == 1
by patid: egen nvart = max(nvar) if sixthnrt == 1

save course6nrt, replace

keep if sixthnrt == 1 

gen course_start6nrt = eventdate if sixthnrt == 1  & nvar == 1 
by patid: replace course_start6nrt = course_start6nrt[_n-1] if course_start6nrt >= . & sixthnrt == 1 
gen course_end6nrt = eventdate if sixthnrt == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end6nrt = course_end6nrt[_n+1] if course_end6nrt >= . & sixthnrt == 1 
	}
gen expo6nrt = 1 if sixthnrt == 1 
format course_start6nrt course_end6nrt %d

by patid: replace sixthnrt = . if expo6nrt == 1 & course_start6nrt >= . 
by patid: gen nend = _n if sixthnrt == 1 
by patid: egen ntend = max(nend) if sixthnrt == 1 
by patid: replace course_end6nrt = eventdate if nend == ntend & sixthnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end6nrt = course_end6nrt[_n+1] if course_end6nrt >= . & sixthnrt == 1 
	}

tab sixthnrt

drop nrtx

by patid: gen  nrtx = sum(sixthnrt) if sixthnrt == 1
by patid: replace nrtx = 0 if sixthnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course6_nrt, replace


******* Varenicline  
	
use course6nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if sixthnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen sixthvar = 1 if treatment == "varenicline" & nv == 1
replace sixthvar = 0 if fullc2 >= . 
by patid: replace sixthvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace sixthvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace sixthvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab sixthvar, missing 

by patid: gen  pills = sum(qty) if sixthvar == 1 
by patid: replace pills = 0 if sixthvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if sixthvar == 1
by patid: egen nvart = max(nvar) if sixthvar == 1

keep if sixthvar == 1

gen course_start6var = eventdate if sixthvar == 1  & nvar == 1 
by patid: replace course_start6var = course_start6var[_n-1] if course_start6var >= . & sixthvar == 1 

gen course_end6var = eventdate if sixthvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end6var = course_end6var[_n+1] if course_end6var >= . & sixthvar == 1 
	}
gen expo6var = 2 if sixthvar == 1 
format course_start6var course_end6var %d

save course6_var, replace


use course6, clear 

merge m:m patid eventdate productname using course6_nrt
drop _merge 
merge m:m patid eventdate productname using course6_var
drop fifth no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart  nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen sixth = 1 if sixthvar == 1 
replace sixth = 0 if sixthvar >= .
replace sixth = 1 if sixthnrt == 1 
replace sixth = 0 if sixthnrt == 0 & sixthvar >= .

tab sixth, missing

gen course_start6 = course_start6var if sixthvar == 1 
replace course_start6 = course_start6nrt if sixthnrt == 1 & course_start6var >= . 

gen course_end6 = course_end6var if sixthvar == 1 
replace course_end6 = course_end6nrt if sixthnrt == 1 & course_end6var >= . 

format course_start6 course_end6 %d

gen expo6 = expo6var if sixthvar == 1 
replace expo6 = expo6nrt if sixthnrt == 1
tab expo6, missing

save course6_final, replace 

keep if sixth == 0

by patid: gen no = _n 

drop sixthnrt course_start6nrt course_end6nrt expo6nrt sixthvar course_start6var 
drop course_end6var expo6var course_start6 course_end6 expo6

save course7, replace 


******************************* Course 7



******* NRT 
	
use course7, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen seventhnrt = 1 if treatment == "NRT" & no == 1
replace seventhnrt = 0 if fullc >= . 
by patid: replace seventhnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace seventhnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace seventhnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab seventhnrt, missing

by patid: gen  nrtx = sum(seventhnrt) if seventhnrt == 1
by patid: replace nrtx = 0 if seventhnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if seventhnrt == 1
by patid: egen nvart = max(nvar) if seventhnrt == 1

save course7nrt, replace

keep if seventhnrt == 1 

gen course_start7nrt = eventdate if seventhnrt == 1  & nvar == 1 
by patid: replace course_start7nrt = course_start7nrt[_n-1] if course_start7nrt >= . & seventhnrt == 1 
gen course_end7nrt = eventdate if seventhnrt == 1 & nvar == nvart 
forvalues  i= 1(1)20{ 
	by patid: replace course_end7nrt = course_end7nrt[_n+1] if course_end7nrt >= . & seventhnrt == 1 
	}
gen expo7nrt = 1 if seventhnrt == 1 
format course_start7nrt course_end7nrt %d

by patid: replace seventhnrt = . if expo7nrt == 1 & course_start7nrt >= . 
by patid: gen nend = _n if seventhnrt == 1 
by patid: egen ntend = max(nend) if seventhnrt == 1 
by patid: replace course_end7nrt = eventdate if nend == ntend & seventhnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end7nrt = course_end7nrt[_n+1] if course_end7nrt >= . & seventhnrt == 1 
	}

tab seventhnrt

drop nrtx

by patid: gen  nrtx = sum(seventhnrt) if seventhnrt == 1
by patid: replace nrtx = 0 if seventhnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course7_nrt, replace


******* Varenicline  
	
use course7nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if seventhnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen seventhvar = 1 if treatment == "varenicline" & nv == 1
replace seventhvar = 0 if fullc2 >= . 
by patid: replace seventhvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace seventhvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace seventhvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab seventhvar, missing 

by patid: gen  pills = sum(qty) if seventhvar == 1 
by patid: replace pills = 0 if seventhvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if seventhvar == 1
by patid: egen nvart = max(nvar) if seventhvar == 1

keep if seventhvar == 1

gen course_start7var = eventdate if seventhvar == 1  & nvar == 1 
by patid: replace course_start7var = course_start7var[_n-1] if course_start7var >= . & seventhvar == 1 

gen course_end7var = eventdate if seventhvar == 1 & nvar == nvart
forvalues  i= 1(1)20{  
	by patid: replace course_end7var = course_end7var[_n+1] if course_end7var >= . & seventhvar == 1 
	}
gen expo7var = 2 if seventhvar == 1 
format course_start7var course_end7var %d

save course7_var, replace


use course7, clear 

merge m:m patid eventdate productname using course7_nrt
drop _merge 
merge m:m patid eventdate productname using course7_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen seventh = 1 if seventhvar == 1 
replace seventh = 0 if seventhvar >= .
replace seventh = 1 if seventhnrt == 1 
replace seventh = 0 if seventhnrt == 0 & seventhvar >= .

tab seventh, missing

gen course_start7 = course_start7var if seventhvar == 1 
replace course_start7 = course_start7nrt if seventhnrt == 1 & course_start7var >= . 

gen course_end7 = course_end7var if seventhvar == 1 
replace course_end7 = course_end7nrt if seventhnrt == 1 & course_end7var >= . 

format course_start7 course_end7 %d

gen expo7 = expo7var if seventhvar == 1 
replace expo7 = expo7nrt if seventhnrt == 1
tab expo7, missing

save course7_final, replace 

keep if seventh == 0

by patid: gen no = _n 

drop sixth seventhnrt course_start7nrt course_end7nrt expo7nrt seventhvar 
drop course_start7var course_end7var expo7var course_start7 course_end7 expo7

save course8, replace 


******************************* Course 8



******* NRT 
	
use course8, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen eighthnrt = 1 if treatment == "NRT" & no == 1
replace eighthnrt = 0 if fullc >= . 
by patid: replace eighthnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace eighthnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace eighthnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab eighthnrt, missing

by patid: gen  nrtx = sum(eighthnrt) if eighthnrt == 1
by patid: replace nrtx = 0 if eighthnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if eighthnrt == 1
by patid: egen nvart = max(nvar) if eighthnrt == 1

save course8nrt, replace

keep if eighthnrt == 1 

gen course_start8nrt = eventdate if eighthnrt == 1  & nvar == 1 
by patid: replace course_start8nrt = course_start8nrt[_n-1] if course_start8nrt >= . & eighthnrt == 1 
gen course_end8nrt = eventdate if eighthnrt == 1 & nvar == nvart 
forvalues  i= 1(1)20{ 
	by patid: replace course_end8nrt = course_end8nrt[_n+1] if course_end8nrt >= . & eighthnrt == 1 
	}
gen expo8nrt = 1 if eighthnrt == 1 
format course_start8nrt course_end8nrt %d

by patid: replace eighthnrt = . if expo8nrt == 1 & course_start8nrt >= . 
by patid: gen nend = _n if eighthnrt == 1 
by patid: egen ntend = max(nend) if eighthnrt == 1 
by patid: replace course_end8nrt = eventdate if nend == ntend & eighthnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end8nrt = course_end8nrt[_n+1] if course_end8nrt >= . & eighthnrt == 1 
	}

tab eighthnrt

drop nrtx

by patid: gen  nrtx = sum(eighthnrt) if eighthnrt == 1
by patid: replace nrtx = 0 if eighthnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course8_nrt, replace


******* Varenicline  
	
use course8nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if eighthnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen eighthvar = 1 if treatment == "varenicline" & nv == 1
replace eighthvar = 0 if fullc2 >= . 
by patid: replace eighthvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace eighthvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace eighthvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab eighthvar, missing 

by patid: gen  pills = sum(qty) if eighthvar == 1 
by patid: replace pills = 0 if eighthvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if eighthvar == 1
by patid: egen nvart = max(nvar) if eighthvar == 1

keep if eighthvar == 1

gen course_start8var = eventdate if eighthvar == 1  & nvar == 1 
by patid: replace course_start8var = course_start8var[_n-1] if course_start8var >= . & eighthvar == 1 

gen course_end8var = eventdate if eighthvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end8var = course_end8var[_n+1] if course_end8var >= . & eighthvar == 1 
	}
gen expo8var = 2 if eighthvar == 1 
format course_start8var course_end8var %d

save course8_var, replace


use course8, clear 

merge m:m patid eventdate productname using course8_nrt
drop _merge 
merge m:m patid eventdate productname using course8_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen eighth = 1 if eighthvar == 1 
replace eighth = 0 if eighthvar >= .
replace eighth = 1 if eighthnrt == 1 
replace eighth = 0 if eighthnrt == 0 & eighthvar >= .

tab eighth, missing

gen course_start8 = course_start8var if eighth == 1 
replace course_start8 = course_start8nrt if eighth == 1 & course_start8var >= . 

gen course_end8 = course_end8var if eighthvar == 1 
replace course_end8 = course_end8nrt if eighthnrt == 1 & course_end8var >= . 

format course_start8 course_end8 %d

gen expo8 = expo8var if eighthvar == 1 
replace expo8 = expo8nrt if eighthnrt == 1
tab expo8, missing

save course8_final, replace 

keep if eighth == 0

by patid: gen no = _n 

drop seventh eighthnrt course_start8nrt course_end8nrt expo8nrt eighthvar 
drop course_start8var course_end8var expo8var course_start8 course_end8 expo8

save course9, replace 

******************************* Course 9



******* NRT 
	
use course9, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen ninthnrt = 1 if treatment == "NRT" & no == 1
replace ninthnrt = 0 if fullc >= . 
by patid: replace ninthnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace ninthnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace ninthnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab ninthnrt, missing

by patid: gen  nrtx = sum(ninthnrt) if ninthnrt == 1
by patid: replace nrtx = 0 if ninthnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if ninthnrt == 1
by patid: egen nvart = max(nvar) if ninthnrt == 1

save course9nrt, replace

keep if ninthnrt == 1 

gen course_start9nrt = eventdate if ninthnrt == 1  & nvar == 1 
by patid: replace course_start9nrt = course_start9nrt[_n-1] if course_start9nrt >= . & ninthnrt == 1 
gen course_end9nrt = eventdate if ninthnrt == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end9nrt = course_end9nrt[_n+1] if course_end9nrt >= . & ninthnrt == 1 
	}
gen expo9nrt = 1 if ninthnrt == 1 
format course_start9nrt course_end9nrt %d

by patid: replace ninthnrt = . if expo9nrt == 1 & course_start9nrt >= . 
by patid: gen nend = _n if ninthnrt == 1 
by patid: egen ntend = max(nend) if ninthnrt == 1 
by patid: replace course_end9nrt = eventdate if nend == ntend & ninthnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end9nrt = course_end9nrt[_n+1] if course_end9nrt >= . & ninthnrt == 1 
	}

tab ninthnrt

drop nrtx

by patid: gen  nrtx = sum(ninthnrt) if ninthnrt == 1
by patid: replace nrtx = 0 if ninthnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course9_nrt, replace


******* Varenicline  
	
use course9nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if ninthnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen ninthvar = 1 if treatment == "varenicline" & nv == 1
replace ninthvar = 0 if fullc2 >= . 
by patid: replace ninthvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace ninthvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace ninthvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab ninthvar, missing 

by patid: gen  pills = sum(qty) if ninthvar == 1 
by patid: replace pills = 0 if ninthvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if ninthvar == 1
by patid: egen nvart = max(nvar) if ninthvar == 1

keep if ninthvar == 1

gen course_start9var = eventdate if ninthvar == 1  & nvar == 1 
by patid: replace course_start9var = course_start9var[_n-1] if course_start9var >= . & ninthvar == 1 

gen course_end9var = eventdate if ninthvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end9var = course_end9var[_n+1] if course_end9var >= . & ninthvar == 1 
	}
gen expo9var = 2 if ninthvar == 1 
format course_start9var course_end9var %d

save course9_var, replace


use course9, clear 

merge m:m patid eventdate productname using course9_nrt
drop _merge 
merge m:m patid eventdate productname using course9_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen ninth = 1 if ninthvar == 1 
replace ninth = 0 if ninthvar >= .
replace ninth = 1 if ninthnrt == 1 
replace ninth = 0 if ninthnrt == 0 & ninthvar >= .

tab ninth, missing

gen course_start9 = course_start9var if ninth == 1 
replace course_start9 = course_start9nrt if ninth == 1 & course_start9var >= . 

gen course_end9 = course_end9var if ninthvar == 1 
replace course_end9 = course_end9nrt if ninthnrt == 1 & course_end9var >= .

format course_start9 course_end9 %d

gen expo9 = expo9var if ninthvar == 1 
replace expo9 = expo9nrt if ninthnrt == 1
tab expo9, missing

save course9_final, replace 

keep if ninth == 0

by patid: gen no = _n 

drop eighth ninthnrt course_start9nrt course_end9nrt expo9nrt ninthvar 
drop course_start9var course_end9var expo9var course_start9 course_end9 expo9

save course10, replace 


******************************* Course 10



******* NRT 
	
use course10, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen tenthnrt = 1 if treatment == "NRT" & no == 1
replace tenthnrt = 0 if fullc >= . 
by patid: replace tenthnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace tenthnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace tenthnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab tenthnrt, missing

by patid: gen  nrtx = sum(tenthnrt) if tenthnrt == 1
by patid: replace nrtx = 0 if tenthnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if tenthnrt == 1
by patid: egen nvart = max(nvar) if tenthnrt == 1

save course10nrt, replace

keep if tenthnrt == 1 

gen course_start10nrt = eventdate if tenthnrt == 1  & nvar == 1 
by patid: replace course_start10nrt = course_start10nrt[_n-1] if course_start10nrt >= . & tenthnrt == 1 
gen course_end10nrt = eventdate if tenthnrt == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end10nrt = course_end10nrt[_n+1] if course_end10nrt >= . & tenthnrt == 1 
	}
gen expo10nrt = 1 if tenthnrt == 1 
format course_start10nrt course_end10nrt %d

by patid: replace tenthnrt = . if expo10nrt == 1 & course_start10nrt >= . 
by patid: gen nend = _n if tenthnrt == 1 
by patid: egen ntend = max(nend) if tenthnrt == 1 
by patid: replace course_end10nrt = eventdate if nend == ntend & tenthnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end10nrt = course_end10nrt[_n+1] if course_end10nrt >= . & tenthnrt == 1 
	}

tab tenthnrt

drop nrtx

by patid: gen  nrtx = sum(tenthnrt) if tenthnrt == 1
by patid: replace nrtx = 0 if tenthnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course10_nrt, replace


******* Varenicline  
	
use course10nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if tenthnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen tenthvar = 1 if treatment == "varenicline" & nv == 1
replace tenthvar = 0 if fullc2 >= . 
by patid: replace tenthvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace tenthvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace tenthvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab tenthvar, missing 

by patid: gen  pills = sum(qty) if tenthvar == 1 
by patid: replace pills = 0 if tenthvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if tenthvar == 1
by patid: egen nvart = max(nvar) if tenthvar == 1

keep if tenthvar == 1

gen course_start10var = eventdate if tenthvar == 1  & nvar == 1 
by patid: replace course_start10var = course_start10var[_n-1] if course_start10var >= . & tenthvar == 1 

gen course_end10var = eventdate if tenthvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end10var = course_end10var[_n+1] if course_end10var >= . & tenthvar == 1 
	}
gen expo10var = 2 if tenthvar == 1 
format course_start10var course_end10var %d

save course10_var, replace


use course10, clear 

merge m:m patid eventdate productname using course10_nrt
drop _merge 
merge m:m patid eventdate productname using course10_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen tenth = 1 if tenthvar == 1 
replace tenth = 0 if tenthvar >= .
replace tenth = 1 if tenthnrt == 1 
replace tenth = 0 if tenthnrt == 0 & tenthvar >= .

tab tenth, missing

gen course_start10 = course_start10var if tenth == 1 
replace course_start10 = course_start10nrt if tenth == 1 & course_start10var >= . 

gen course_end10 = course_end10var if tenthvar == 1 
replace course_end10 = course_end10nrt if tenthnrt == 1 & course_end10var >= . 

format course_start10 course_end10 %d

gen expo10 = expo10var if tenthvar == 1 
replace expo10 = expo10nrt if tenthnrt == 1
tab expo10, missing

save course10_final, replace 

keep if tenth == 0

by patid: gen no = _n 

drop tenthnrt course_start10nrt course_end10nrt expo10nrt tenthvar course_start10var 
drop course_end10var expo10var course_start10 course_end10 expo10

save course11, replace 



******************************* Course 11



******* NRT 
	
use course11, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen elthnrt = 1 if treatment == "NRT" & no == 1
replace elthnrt = 0 if fullc >= . 
by patid: replace elthnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace elthnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace elthnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab elthnrt, missing

by patid: gen  nrtx = sum(elthnrt) if elthnrt == 1
by patid: replace nrtx = 0 if elthnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if elthnrt == 1
by patid: egen nvart = max(nvar) if elthnrt == 1

save course11nrt, replace

keep if elthnrt == 1 

gen course_start11nrt = eventdate if elthnrt == 1  & nvar == 1 
by patid: replace course_start11nrt = course_start11nrt[_n-1] if course_start11nrt >= . & elthnrt == 1 
gen course_end11nrt = eventdate if elthnrt == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end11nrt = course_end11nrt[_n+1] if course_end11nrt >= . & elthnrt == 1 
	}
gen expo11nrt = 1 if elthnrt == 1 
format course_start11nrt course_end11nrt %d

by patid: replace elthnrt = . if expo11nrt == 1 & course_start11nrt >= . 
by patid: gen nend = _n if elthnrt == 1 
by patid: egen ntend = max(nend) if elthnrt == 1 
by patid: replace course_end11nrt = eventdate if nend == ntend & elthnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end11nrt = course_end11nrt[_n+1] if course_end11nrt >= . & elthnrt == 1 
	}
	
tab elthnrt

drop nrtx

by patid: gen  nrtx = sum(elthnrt) if elthnrt == 1
by patid: replace nrtx = 0 if elthnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course11_nrt, replace


******* Varenicline  
	
use course11nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if elthnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen elthvar = 1 if treatment == "varenicline" & nv == 1
replace elthvar = 0 if fullc2 >= . 
by patid: replace elthvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace elthvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace elthvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab elthvar, missing 

by patid: gen  pills = sum(qty) if elthvar == 1 
by patid: replace pills = 0 if elthvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if elthvar == 1
by patid: egen nvart = max(nvar) if elthvar == 1

keep if elthvar == 1

gen course_start11var = eventdate if elthvar == 1  & nvar == 1 
by patid: replace course_start11var = course_start11var[_n-1] if course_start11var >= . & elthvar == 1 

gen course_end11var = eventdate if elthvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end11var = course_end11var[_n+1] if course_end11var >= . & elthvar == 1 
	} 
	
gen expo11var = 2 if elthvar == 1 
format course_start11var course_end11var %d

save course11_var, replace


use course11, clear 

merge m:m patid eventdate productname using course11_nrt
drop _merge 
merge m:m patid eventdate productname using course11_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen eleventh = 1 if elthvar == 1 
replace eleventh = 0 if elthvar >= .
replace eleventh = 1 if elthnrt == 1 
replace eleventh = 0 if elthnrt == 0 & elthvar >= .

tab eleventh, missing

gen course_start11 = course_start11var if eleventh == 1 
replace course_start11 = course_start11nrt if eleventh == 1 & course_start11var >= . 

gen course_end11 = course_end11var if elthvar == 1 
replace course_end11 = course_end11nrt if elthnrt == 1 & course_end11var >= . 

format course_start11 course_end11 %d

gen expo11 = expo11var if elthvar == 1 
replace expo11 = expo11nrt if elthnrt == 1
tab expo11, missing

save course11_final, replace 

keep if eleventh == 0

by patid: gen no = _n 

drop ninth tenth elthnrt course_start11nrt course_end11nrt expo11nrt elthvar 
drop course_start11var course_end11var expo11var course_start11 course_end11 expo11

save course12, replace 



******************************* Course 12



******* NRT 
	
use course12, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen twelfthnrt = 1 if treatment == "NRT" & no == 1
replace twelfthnrt = 0 if fullc >= . 
by patid: replace twelfthnrt = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace twelfthnrt = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace twelfthnrt = 0 if eventdate >= fullc | treatment == "varenciline"

tab twelfthnrt, missing

by patid: gen  nrtx = sum(twelfthnrt) if twelfthnrt == 1
by patid: replace nrtx = 0 if twelfthnrt == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if twelfthnrt == 1
by patid: egen nvart = max(nvar) if twelfthnrt == 1

save course12nrt, replace

keep if twelfthnrt == 1 

gen course_start12nrt = eventdate if twelfthnrt == 1  & nvar == 1 
by patid: replace course_start12nrt = course_start12nrt[_n-1] if course_start12nrt >= . & twelfthnrt == 1 
gen course_end12nrt = eventdate if twelfthnrt == 1 & nvar == nvart
forvalues  i= 1(1)20{  
	by patid: replace course_end12nrt = course_end12nrt[_n+1] if course_end12nrt >= . & twelfthnrt == 1 
	}
gen expo12nrt = 1 if twelfthnrt == 1 
format course_start12nrt course_end12nrt %d

by patid: replace twelfthnrt = . if expo12nrt == 1 & course_start12nrt >= . 
by patid: gen nend = _n if twelfthnrt == 1 
by patid: egen ntend = max(nend) if twelfthnrt == 1 
by patid: replace course_end12nrt = eventdate if nend == ntend & twelfthnrt == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end12nrt = course_end12nrt[_n+1] if course_end12nrt >= . & twelfthnrt == 1 
	}

tab twelfthnrt

drop nrtx

by patid: gen  nrtx = sum(twelfthnrt) if twelfthnrt == 1
by patid: replace nrtx = 0 if twelfthnrt == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course12_nrt, replace


******* Varenicline  
	
use course12nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if twelfthnrt == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen twelfthvar = 1 if treatment == "varenicline" & nv == 1
replace twelfthvar = 0 if fullc2 >= . 
by patid: replace twelfthvar = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace twelfthvar = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace twelfthvar = 0 if eventdate >= fullc2 | treatment == "NRT"

tab twelfthvar, missing 

by patid: gen  pills = sum(qty) if twelfthvar == 1 
by patid: replace pills = 0 if twelfthvar == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if twelfthvar == 1
by patid: egen nvart = max(nvar) if twelfthvar == 1

keep if twelfthvar == 1

gen course_start12var = eventdate if twelfthvar == 1  & nvar == 1 
by patid: replace course_start12var = course_start12var[_n-1] if course_start12var >= . & twelfthvar == 1 

gen course_end12var = eventdate if twelfthvar == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end12var = course_end12var[_n+1] if course_end12var >= . & twelfthvar == 1 
	}
gen expo12var = 2 if twelfthvar == 1 
format course_start12var course_end12var %d

save course12_var, replace


use course12, clear 

merge m:m patid eventdate productname using course12_nrt
drop _merge 
merge m:m patid eventdate productname using course12_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen twelfth = 1 if twelfthvar == 1 
replace twelfth = 0 if twelfthvar >= .
replace twelfth = 1 if twelfthnrt == 1 
replace twelfth = 0 if twelfthnrt == 0 & twelfthvar >= .

tab twelfth, missing

gen course_start12 = course_start12var if twelfth == 1 
replace course_start12 = course_start12nrt if twelfth == 1 & course_start12var >= . 

gen course_end12 = course_end12var if twelfthvar == 1 
replace course_end12 = course_end12nrt if twelfthnrt == 1 & course_end12var >= . 

format course_start12 course_end12 %d

gen expo12 = expo12var if twelfthvar == 1 
replace expo12 = expo12nrt if twelfthnrt == 1
tab expo12, missing

save course12_final, replace 

keep if twelfth == 0

by patid: gen no = _n 

drop eleventh twelfthnrt course_start12nrt course_end12nrt expo12nrt twelfthvar 
drop course_start12var course_end12var expo12var course_start12 course_end12 expo12

save course13, replace 

******************************* Course 13



******* NRT 
	
use course13, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen nrt_13th = 1 if treatment == "NRT" & no == 1
replace nrt_13th = 0 if fullc >= . 
by patid: replace nrt_13th = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace nrt_13th = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace nrt_13th = 0 if eventdate >= fullc | treatment == "varenciline"

tab nrt_13th, missing

by patid: gen  nrtx = sum(nrt_13th) if nrt_13th == 1
by patid: replace nrtx = 0 if nrt_13th == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if nrt_13th == 1
by patid: egen nvart = max(nvar) if nrt_13th == 1

save course13nrt, replace

keep if nrt_13th == 1 

gen course_start13nrt = eventdate if nrt_13th == 1  & nvar == 1 
by patid: replace course_start13nrt = course_start13nrt[_n-1] if course_start13nrt >= . & nrt_13th == 1 
gen course_end13nrt = eventdate if nrt_13th == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end13nrt = course_end13nrt[_n+1] if course_end13nrt >= . & nrt_13th == 1 
	}
gen expo13nrt = 1 if nrt_13th == 1 
format course_start13nrt course_end13nrt %d

by patid: replace nrt_13th = . if expo13nrt == 1 & course_start13nrt >= . 
by patid: gen nend = _n if nrt_13th == 1 
by patid: egen ntend = max(nend) if nrt_13th == 1 
by patid: replace course_end13nrt = eventdate if nend == ntend & nrt_13th == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end13nrt = course_end13nrt[_n+1] if course_end13nrt >= . & nrt_13th == 1 
	}

tab nrt_13th

drop nrtx

by patid: gen  nrtx = sum(nrt_13th) if nrt_13th == 1
by patid: replace nrtx = 0 if nrt_13th == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course13_nrt, replace


******* Varenicline  
	
use course13nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if nrt_13th == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen var_13th = 1 if treatment == "varenicline" & nv == 1
replace var_13th = 0 if fullc2 >= . 
by patid: replace var_13th = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace var_13th = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace var_13th = 0 if eventdate >= fullc2 | treatment == "NRT"

tab var_13th, missing 

by patid: gen  pills = sum(qty) if var_13th == 1 
by patid: replace pills = 0 if var_13th == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if var_13th == 1
by patid: egen nvart = max(nvar) if var_13th == 1

keep if var_13th == 1

gen course_start13var = eventdate if var_13th == 1  & nvar == 1 
by patid: replace course_start13var = course_start13var[_n-1] if course_start13var >= . & var_13th == 1 

gen course_end13var = eventdate if var_13th == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end13var = course_end13var[_n+1] if course_end13var >= . & var_13th == 1 
	}
gen expo13var = 2 if var_13th == 1 
format course_start13var course_end13var %d

save course13_var, replace


use course13, clear 

merge m:m patid eventdate productname using course13_nrt
drop _merge 
merge m:m patid eventdate productname using course13_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen thirteenth = 1 if var_13th == 1 
replace thirteenth = 0 if var_13th >= .
replace thirteenth = 1 if nrt_13th == 1 
replace thirteenth = 0 if nrt_13th == 0 & var_13th >= .

tab thirteenth, missing

gen course_start13 = course_start13var if thirteenth == 1 
replace course_start13 = course_start13nrt if thirteenth == 1 & course_start13var >= . 

gen course_end13 = course_end13var if var_13th == 1 
replace course_end13 = course_end13nrt if nrt_13th == 1 & course_end13var >= . 

format course_start13 course_end13 %d

gen expo13 = expo13var if var_13th == 1 
replace expo13 = expo13nrt if nrt_13th == 1
tab expo13, missing

save course13_final, replace 

keep if thirteenth == 0

by patid: gen no = _n 

drop twelfth nrt_13th course_start13nrt course_end13nrt expo13nrt var_13th 
drop course_start13var course_end13var expo13var course_end13 expo13

save course14, replace 


******************************* Course 14



******* NRT 
	
use course14, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen nrt_14th = 1 if treatment == "NRT" & no == 1
replace nrt_14th = 0 if fullc >= . 
by patid: replace nrt_14th = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace nrt_14th = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace nrt_14th = 0 if eventdate >= fullc | treatment == "varenciline"

tab nrt_14th, missing

by patid: gen  nrtx = sum(nrt_14th) if nrt_14th == 1
by patid: replace nrtx = 0 if nrt_14th == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if nrt_14th == 1
by patid: egen nvart = max(nvar) if nrt_14th == 1

save course14nrt, replace

keep if nrt_14th == 1 

gen course_start14nrt = eventdate if nrt_14th == 1  & nvar == 1 
by patid: replace course_start14nrt = course_start14nrt[_n-1] if course_start14nrt >= . & nrt_14th == 1 
gen course_end14nrt = eventdate if nrt_14th == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end14nrt = course_end14nrt[_n+1] if course_end14nrt >= . & nrt_14th == 1 
	}
gen expo14nrt = 1 if nrt_14th == 1 
format course_start14nrt course_end14nrt %d

by patid: replace nrt_14th = . if expo14nrt == 1 & course_start14nrt >= . 
by patid: gen nend = _n if nrt_14th == 1 
by patid: egen ntend = max(nend) if nrt_14th == 1 
by patid: replace course_end14nrt = eventdate if nend == ntend & nrt_14th == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end14nrt = course_end14nrt[_n+1] if course_end14nrt >= . & nrt_14th == 1 
	}

tab nrt_14th

drop nrtx

by patid: gen  nrtx = sum(nrt_14th) if nrt_14th == 1
by patid: replace nrtx = 0 if nrt_14th == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail


save course14_nrt, replace


******* Varenicline  
	
use course14nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if nrt_14th == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen var_14th = 1 if treatment == "varenicline" & nv == 1
replace var_14th = 0 if fullc2 >= . 
by patid: replace var_14th = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace var_14th = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace var_14th = 0 if eventdate >= fullc2 | treatment == "NRT"

tab var_14th, missing 

by patid: gen  pills = sum(qty) if var_14th == 1 
by patid: replace pills = 0 if var_14th == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if var_14th == 1
by patid: egen nvart = max(nvar) if var_14th == 1

keep if var_14th == 1

gen course_start14var = eventdate if var_14th == 1  & nvar == 1 
by patid: replace course_start14var = course_start14var[_n-1] if course_start14var >= . & var_14th == 1 

gen course_end14var = eventdate if var_14th == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end14var = course_end14var[_n+1] if course_end14var >= . & var_14th == 1 
	}
gen expo14var = 2 if var_14th == 1 
format course_start14var course_end14var %d

save course14_var, replace


use course14, clear 

merge m:m patid eventdate productname using course14_nrt
drop _merge 
merge m:m patid eventdate productname using course14_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen fourteenth = 1 if var_14th == 1 
replace fourteenth = 0 if var_14th >= .
replace fourteenth = 1 if nrt_14th == 1 
replace fourteenth = 0 if nrt_14th == 0 & var_14th >= .

tab fourteenth, missing

gen course_start14 = course_start14var if fourteenth == 1 
replace course_start14 = course_start14nrt if fourteenth == 1 & course_start14var >= . 

gen course_end14 = course_end14var if var_14th == 1 
replace course_end14 = course_end14nrt if nrt_14th == 1 & course_end14var >= . 

format course_start14 course_end14 %d

gen expo14 = expo14var if var_14th == 1 
replace expo14 = expo14nrt if nrt_14th == 1
tab expo14, missing

save course14_final, replace 

keep if fourteenth == 0

by patid: gen no = _n 

drop thirteenth course_start13 nrt_14th course_start14nrt course_end14nrt 
drop expo14nrt var_14th course_start14var course_end14var expo14var course_start14 course_end14 expo14

save course15, replace 



******************************* Course 15



******* NRT 
	
use course15, clear

gen fullc = eventdate + 90 if treatment == "NRT" & no == 1
format fullc %d
by patid: replace fullc = fullc[_n-1] if fullc >= . 

gen nrt_15th = 1 if treatment == "NRT" & no == 1
replace nrt_15th = 0 if fullc >= . 
by patid: replace nrt_15th = 1 if eventdate < fullc & fullc < . & treatment == "NRT" 
by patid: replace nrt_15th = 0 if eventdate < fullc & treatment == "varenicline" 
by patid: replace nrt_15th = 0 if eventdate >= fullc | treatment == "varenciline"

tab nrt_15th, missing

by patid: gen  nrtx = sum(nrt_15th) if nrt_15th == 1
by patid: replace nrtx = 0 if nrt_15th == 0 

tab nrtx, missing

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

by patid: gen nvar = _n if nrt_15th == 1
by patid: egen nvart = max(nvar) if nrt_15th == 1

save course15nrt, replace

keep if nrt_15th == 1 

gen course_start15nrt = eventdate if nrt_15th == 1  & nvar == 1 
by patid: replace course_start15nrt = course_start15nrt[_n-1] if course_start15nrt >= . & nrt_15th == 1 
gen course_end15nrt = eventdate if nrt_15th == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end15nrt = course_end15nrt[_n+1] if course_end15nrt >= . & nrt_15th == 1 
	}
gen expo15nrt = 1 if nrt_15th == 1 
format course_start15nrt course_end15nrt %d

by patid: replace nrt_15th = . if expo15nrt == 1 & course_start15nrt >= . 
by patid: gen nend = _n if nrt_15th == 1 
by patid: egen ntend = max(nend) if nrt_15th == 1 
by patid: replace course_end15nrt = eventdate if nend == ntend & nrt_15th == 1 
forvalues  i= 1(1)20{
	by patid: replace course_end15nrt = course_end15nrt[_n+1] if course_end15nrt >= . & nrt_15th == 1 
	}

tab nrt_15th

drop nrtx

by patid: gen  nrtx = sum(nrt_15th) if nrt_15th == 1
by patid: replace nrtx = 0 if nrt_15th == 0 

tab nrtx, missing

drop no_nrtx nt_nrtx cnrtx

by patid: gen no_nrtx = _n 
by patid: gen nt_nrtx = _N
by patid: egen cnrtx = max(nrtx) 

tab cnrtx if no_nrtx == nt_nrtx 
sum cnrtx if no_nrtx == nt_nrtx & cnrtx != 0, detail

save course15_nrt, replace


******* Varenicline  
	
use course15nrt, clear

drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart

sort patid eventdate

by patid: gen no = _n 
by patid: gen nv = _n if nrt_15th == 0 

gen fullc2 = eventdate + 84 if treatment == "varenicline" & nv == 1 
format fullc2 %d
by patid: replace fullc2 = fullc2[_n-1] if fullc2 >= .

gen var_15th = 1 if treatment == "varenicline" & nv == 1
replace var_15th = 0 if fullc2 >= . 
by patid: replace var_15th = 1 if eventdate < fullc2 & fullc2 < . & treatment == "varenicline" 
by patid: replace var_15th = 0 if eventdate < fullc2 & treatment == "NRT" 
by patid: replace var_15th = 0 if eventdate >= fullc2 | treatment == "NRT"

tab var_15th, missing 

by patid: gen  pills = sum(qty) if var_15th == 1 
by patid: replace pills = 0 if var_15th == 0 

by patid: gen ntvar = _N
egen cpills=max(pills), by(patid)

tab cpills if ntvar == no 
sum cpills if cpills != 0 & ntvar == no, detail

gen FC = 0 if cpills < 132 & cpills != 0 
replace FC = 1 if cpills >= 132 & cpills < .
replace FC = . if cpills == 0 

tab FC if ntvar == no, missing

by patid: gen nvar = _n if var_15th == 1
by patid: egen nvart = max(nvar) if var_15th == 1

keep if var_15th == 1

gen course_start15var = eventdate if var_15th == 1  & nvar == 1 
by patid: replace course_start15var = course_start15var[_n-1] if course_start15var >= . & var_15th == 1 

gen course_end15var = eventdate if var_15th == 1 & nvar == nvart  
forvalues  i= 1(1)20{
	by patid: replace course_end15var = course_end15var[_n+1] if course_end15var >= . & var_15th == 1 
	}
gen expo15var = 2 if var_15th == 1 
format course_start15var course_end15var %d

save course15_var, replace


use course15, clear 

merge m:m patid eventdate productname using course15_nrt
drop _merge 
merge m:m patid eventdate productname using course15_var
drop no fullc nrtx no_nrtx nt_nrtx cnrtx nvar nvart nv fullc2 pills ntvar cpills FC _merge nend ntend

sort patid eventdate

gen fifteenth = 1 if var_15th == 1 
replace fifteenth = 0 if var_15th >= .
replace fifteenth = 1 if nrt_15th == 1 
replace fifteenth = 0 if nrt_15th == 0 & var_15th >= .

tab fifteenth, missing

gen course_start15 = course_start15var if fifteenth == 1 
replace course_start15 = course_start15nrt if fifteenth == 1 & course_start15var >= . 

gen course_end15 = course_end15var if var_15th == 1 
replace course_end15 = course_end15nrt if nrt_15th == 1 & course_end15var >= . 

format course_start15 course_end15 %d

gen expo15 = expo15var if var_15th == 1 
replace expo15 = expo15nrt if nrt_15th == 1
tab expo15, missing

drop fourteenth nrt_15th course_start15nrt course_end15nrt expo15nrt var_15th 
drop course_start15var course_end15var expo15var

save course15_final, replace 

keep if fifteenth == 0

by patid: gen no = _n 

save course16, replace 



********************************************************************************

use RxPN, clear

* Course 1
merge m:m patid eventdate productname using course1_final
drop product switch switch_e switch_ever btw Rxcancer firstvar 
drop course_start1var course_end1var expo1var firstnrt nt cnrx course_start1nrt 
drop course_end1nrt expo1nrt _merge

* Course 2 
merge m:m patid eventdate productname using course2_final
drop secondnrt course_start2nrt course_end2nrt expo2nrt secondvar 
drop course_start2var course_end2var expo2var _merge

* Course 3 
merge m:m patid eventdate productname using course3_final
drop thirdnrt course_start3nrt course_end3nrt expo3nrt thirdvar 
drop course_start3var course_end3var expo3var _merge

* Course 4 
merge m:m patid eventdate productname using course4_final
drop fourthnrt course_start4nrt course_end4nrt expo4nrt fourthvar course_start4var course_end4var expo4var _merge

* Course 5
merge m:m patid eventdate productname using course5_final
drop fifthnrt course_start5nrt course_end5nrt expo5nrt fifthvar course_start5var course_end5var expo5var _merge

* Course 6
merge m:m patid eventdate productname using course6_final
drop sixthnrt course_start6nrt course_end6nrt expo6nrt sixthvar course_start6var course_end6var expo6var _merge

* Course 7 
merge m:m patid eventdate productname using course7_final
drop seventhnrt course_start7nrt course_end7nrt expo7nrt seventhvar course_start7var course_end7var expo7var _merge

* Course 8
merge m:m patid eventdate productname using course8_final
drop eighthnrt course_start8nrt course_end8nrt expo8nrt eighthvar course_start8var course_end8var expo8var _merge

* Course 9
merge m:m patid eventdate productname using course9_final
drop ninthnrt course_start9nrt course_end9nrt expo9nrt ninthvar course_start9var course_end9var expo9var _merge

* Course 10
merge m:m patid eventdate productname using course10_final
drop tenthnrt course_start10nrt course_end10nrt expo10nrt tenthvar course_start10var course_end10var expo10var _merge

* Course 11
merge m:m patid eventdate productname using course11_final
drop elthnrt course_start11nrt course_end11nrt expo11nrt elthvar course_start11var course_end11var expo11var _merge

* Course 12
merge m:m patid eventdate productname using course12_final
drop twelfthnrt course_start12nrt course_end12nrt expo12nrt twelfthvar course_start12var course_end12var expo12var _merge

* Course 13
merge m:m patid eventdate productname using course13_final
drop nrt_13th course_start13nrt course_end13nrt expo13nrt var_13th course_start13var course_end13var expo13var _merge

* Course 14
merge m:m patid eventdate productname using course14_final
drop nrt_14th course_start14nrt course_end14nrt expo14nrt var_14th course_start14var course_end14var expo14var _merge

* Course 15
merge m:m patid eventdate productname using course15_final
drop _merge





tab first 
tab second
tab third
tab fourth 
tab fifth 
tab sixth 
tab seventh 
tab eighth
tab ninth
tab tenth
tab eleventh
tab twelfth
tab thirteenth
tab fourteenth
tab fifteenth



* Variable Course 
gen  course = 1 if first == 1
replace  course = 2 if second == 1
replace  course = 3 if third == 1
replace  course = 4 if fourth == 1
replace  course = 5 if fifth == 1
replace  course = 6 if sixth == 1
replace  course = 7 if seventh == 1
replace  course = 8 if eighth == 1
replace  course = 9 if ninth == 1
replace  course = 10 if tenth == 1
replace  course = 11 if eleventh == 1
replace  course = 12 if twelfth == 1
replace  course = 13 if thirteenth == 1
replace  course = 14 if fourteenth == 1
replace  course = 15 if fifteenth == 1


tab course, missing

* Start 
gen start = course_start1 if first == 1 
replace start = course_start2 if second == 1 
replace start = course_start3 if third == 1 
replace start = course_start4 if fourth == 1 
replace start = course_start5 if fifth == 1 
replace start = course_start6 if sixth == 1 
replace start = course_start7 if seventh == 1 
replace start = course_start8 if eighth == 1 
replace start = course_start9 if ninth == 1 
replace start = course_start10 if tenth == 1 
replace start = course_start11 if eleventh == 1 
replace start = course_start12 if twelfth == 1 
replace start = course_start13 if thirteenth == 1 
replace start = course_start14 if fourteenth == 1 
replace start = course_start15 if fifteenth == 1 


list patid course treatment eventdate start if start >= . 

* End 
gen end = course_end1 if first == 1 
replace end = course_end2 if second == 1 
replace end = course_end3 if third == 1 
replace end = course_end4 if fourth == 1 
replace end = course_end5 if fifth == 1 
replace end = course_end6 if sixth == 1 
replace end = course_end7 if seventh == 1 
replace end = course_end8 if eighth == 1 
replace end = course_end9 if ninth == 1 
replace end = course_end10 if tenth == 1 
replace end = course_end11 if eleventh == 1 
replace end = course_end12 if twelfth == 1 
replace end = course_end13 if thirteenth == 1 
replace end = course_end14 if fourteenth == 1 
replace end = course_end15 if fifteenth == 1 


list patid course treatment eventdate end if end >= . 

format start end %d

* Exposition 
gen expo = expo1 if first == 1 
replace expo = expo2 if second == 1 
replace expo = expo3 if third == 1 
replace expo = expo4 if fourth == 1 
replace expo = expo5 if fifth == 1 
replace expo = expo6 if sixth == 1 
replace expo = expo7 if seventh == 1 
replace expo = expo8 if eighth == 1 
replace expo = expo9 if ninth == 1 
replace expo = expo10 if tenth == 1 
replace expo = expo11 if eleventh == 1 
replace expo = expo12 if twelfth == 1 
replace expo = expo13 if thirteenth == 1 
replace expo = expo14 if fourteenth == 1 
replace expo = expo15 if fifteenth == 1 


tab expo, missing 

tab treatment expo, missing 

list patid eventdate course treatment expo if expo == 1 & treatment == "varenicline"

list patid eventdate course treatment expo if expo == 2 & treatment == "NRT"

save prescription0

keep patid qty eventdate productname treatment clinical_eventdate cov_cancer_eventdate dr_varenicline course start end expo 

save prescription, replace 

* Reshape table 
drop qty clinical_eventdate
order patid dr_varenicline cov_cancer_eventdate course expo  start end treatment eventdate productname
bysort patid: gen no = _n
reshape wide course expo start end eventdate productname treatment, i(patid) j(no) 


















