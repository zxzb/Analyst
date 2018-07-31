*市场模型法
use "C:\Users\se7en\Desktop\Thesis2\do&data\sync.dta", clear
merge m:1 analyst using AnaGroup.dta, keepus(timing) keep(match) nogen
gen date=date(InfoPubDt,"YMD")
format date %tdCCYY-NN-DD
keep Stkcd CurRating InfoPubDt date Indcd1-RatChange analyst-laststar Dturn-id SENT dr2-date
//bys timing: summarize CurRating laststar AbTURN

expand 120
bys id: gen dif=_n-90
replace date=date+dif
merge m:1 Stkcd date using "C:\Users\se7en\Desktop\Thesis2\do&data\return.dta" , keep(match) nogen
sort id date
bys id: gen diff=_n
bys id: gen target=diff if dif>-1
bys id: egen td=min(target)
replace dif=diff-td
drop if dif<-50 | dif>11
bys id: egen a=min(dif)
drop if a>-50
sort Stkcd id date

*定义窗口(前两个月)
by Stkcd: gen est_window=1 if dif<-10
replace est_window=0 if est_window==.

gen prdrt=.
egen id1=group(id)
replace id=id1
drop id1
codebook id
forvalues i=1(1)7416{
  qui reg stkrt mktrt if (id==`i' & est_window==1)
  qui predict p if id==`i'
  qui replace prdrt = p if (id==`i' & est_window==0)
  qui drop p
  }

save "C:\Users\se7en\Desktop\Thesis2\do&data\car_final.dta" , replace

use "C:\Users\se7en\Desktop\Thesis2\do&data\car_final.dta" , clear
drop if dif<-10
gen abrt_pre10to6  = stkrt - prdrt if (dif<-5 & dif>-11)
gen abrt_pre5to1   = stkrt - prdrt if (dif<0  & dif>-6)
gen abrt_post0     = stkrt - prdrt if  dif==0
gen abrt_post1     = stkrt - prdrt if  dif==1
gen abrt_post2to6  = stkrt - prdrt if (dif<7  & dif>1)
gen abrt_post7to11 = stkrt - prdrt if (dif<12 & dif>6)

*整体的CAR
sort id date
by id: egen CAR_1 = sum(abrt_pre10to6)
by id: egen CAR_2 = sum(abrt_pre5to1)
by id: egen CAR_3 = sum(abrt_post0)
by id: egen CAR_4 = sum(abrt_post1)
by id: egen CAR_5 = sum(abrt_post2to6)
by id: egen CAR_6 = sum(abrt_post7to11)
label var CAR_1 "CAR_pre10to6"
label var CAR_2 "CAR_pre5to1"
label var CAR_3 "CAR_post0"
label var CAR_4 "CAR_post1"
label var CAR_5 "CAR_post2to6"
label var CAR_6 "CAR_post7to11"

duplicates drop id, force

reg CAR_1 if (timing==1 & info2==1), robust
outreg using "C:\Users\se7en\Desktop\Thesis2\car2.doc", bdec(4) varlabels ///
         starlevels(5 1) sigsymbols(*,**) ctitles("CAR","Timing-HInfo") replace
forvalues i=2(1)6{
  reg CAR_`i' if (timing==1 & info2==1), robust
  outreg using "C:\Users\se7en\Desktop\Thesis2\car2.doc", bdec(4) varlabels ///
         starlevels(5 1) sigsymbols(*,**) ctitles("","Timing-HInfo") merge replace
  }
forvalues i=1(1)6{
  reg CAR_`i' if (timing==1 & info2==0), robust
  outreg using "C:\Users\se7en\Desktop\Thesis2\car2.doc", bdec(4) varlabels ///
         starlevels(5 1) sigsymbols(*,**) ctitles("","Timing-LInfo") merge replace
  }
forvalues i=1(1)6{
  reg CAR_`i' if (timing==0 & info2==1), robust
  outreg using "C:\Users\se7en\Desktop\Thesis2\car2.doc", bdec(4) varlabels ///
         starlevels(5 1) sigsymbols(*,**) ctitles("","NonTiming-HInfo") merge replace
  }
forvalues i=1(1)6{
  reg CAR_`i' if (timing==0 & info2==0), robust
  outreg using "C:\Users\se7en\Desktop\Thesis2\car2.doc", bdec(4) varlabels ///
         starlevels(5 1) sigsymbols(*,**) ctitles("","NonTiming-LInfo") merge replace
  }
