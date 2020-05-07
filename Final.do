*http://data.stats.gov.cn/english/easyquery.htm?cn=E0103
cd "/Users/jasenlo/Documents/Minerva/Hyderabad 19/SS154/Final" 
*import data
clear
import delimited "/Users/jasenlo/Documents/Minerva/Hyderabad 19/SS154/Final/Hainan Synth.csv"

*cleaning data
rename ïid id
drop v14-v38
*dropped Chongqing
drop if region == "Chongqing" /* id22 */
*dropped controls as these experience treatment
drop if region == "Fujian" /* id13 */
drop if region == "Guangdong" /* id19 */
drop if region == "Beijing" /* id1 */
drop if region == "Tianjin" /* id2 */
drop if region == "Hebei" /* id3 */
drop if region == "Liaoning" /* id6 */
drop if region == "Shanghai" /* id9 */
drop if region == "Jiangsu" /* id10 */
drop if region == "Zhejiang" /* id11 */
drop if region == "Shandong" /* id15 */
drop if region == "Guangxi" /* id20 */

*time-series
tsset id year

*adjusting pop from thousands to full population
replace pop = pop*1000
*adjusting units from 100 Million Yuan to Yuan
replace stateexp = stateexp*1000000000
replace staterev = staterev*1000000000
replace agriculture = agriculture*1000000000
replace investment = investment*1000000000


*interpolate
ipolate population year, gen(pop) epolate by (id)
ipolate investment year, gen(I) epolate by (id)

*per-capita
gen staterev_pc = staterev / pop
gen stateexp_pc = stateexp / pop
gen industrial_pc = industrial/pop
gen agriculture_pc = agriculture/pop
gen I_pc = I/pop

*gen pop_density
gen pop_density = pop/area

*saves dataset
save final.dta, replace
*-----------------------------------------------------------------

* Justifying Inter/Extrapolation of Population
*Only 1982 Population Model
#delimit;

synth 	I_pc I_pc(1982) stateexp_pc(1982)
		staterev_pc(1982) wages 
		industrial_pc(1982) agriculture_pc(1982)
		pop_density(1982) coastal
		,		
		trunit(21) trperiod(1988) unitnames(region)  
		mspeperiod(1980(1)1988) resultsperiod(1980(1)1995) 
	    keep(synth_bmprate.dta) replace fig;

	   	mat list e(V_matrix);
#delimit cr
*Inter/Extrapolation Population Model
#delimit;

synth 	I_pc I_pc stateexp_pc
		staterev_pc wages
		industrial_pc agriculture_pc
		pop_density coastal
		,		
		trunit(21) trperiod(1988) unitnames(region)  
		mspeperiod(1980(1)1988) resultsperiod(1980(1)1995) 
	    keep(synth_bmprate.dta) replace fig;

	   	mat list e(V_matrix);
#delimit cr

*Figure 1 - Justifying Inter/Extrapolation of Population
graph combine only1982.gph allyears.gph 

*-----------------------------------------------------------------

*summary statistics
drop id-investment
drop prices-population
drop pop-I
order I_pc stateexp_pc staterev_pc wages industrial_pc agriculture_pc pop_density coastal
outreg2 using sum,sum(log) replace tex dec(1)

*-----------------------------------------------------------------
**Figure 2 - Time series data of Hainan Investment
clear
use final.dta, replace
egen mean_I_pc = mean(I_pc) if id != 21, by(year)
twoway tsline I_pc if id == 21 || tsline mean_I_pc if id == 4
tsline meanI_pc if id == 5

*-----------------------------------------------------------------

clear
use final.dta, replace
* Figure 3 - Hainan model of investment
#delimit;

synth 	I_pc I_pc stateexp_pc 
		staterev_pc wages 
		industrial_pc agriculture_pc 
		pop_density coastal
		,		
		trunit(21) trperiod(1988) unitnames(region)  
		mspeperiod(1980(1)1988) resultsperiod(1980(1)1995) 
	    keep(synth_bmprate.dta) replace fig;

	   	mat list e(V_matrix);
#delimit cr

* Plot the gap in predicted error
use synth_bmprate.dta, clear
keep _Y_treated _Y_synthetic _time
drop if _time==.
rename _time year
rename _Y_treated  treat
rename _Y_synthetic counterfact
gen gap21=treat-counterfact
sort year 
twoway (line gap21 year,lp(solid)lw(vthin)lcolor(black)), yline(0, lpattern(shortdash) lcolor(black)) xline(1988, lpattern(shortdash) lcolor(black)) xtitle("",si(medsmall)) xlabel(#10) ytitle("Gap in Per-Capita Investment prediction error", size(medsmall)) legend(off)
save synth_bmprate_21.dta, replace

*-----------------------------------------------------------------
* Placebo test
clear
use final.dta, replace

#delimit;
set more off;

local regionlist  4 5 7 8 12 14 16 17 18 21 23 24 25 26 27 28 29 30 31 32;

foreach i of local regionlist {;

synth 	I_pc I_pc stateexp_pc 
		staterev_pc wages 
		industrial_pc agriculture_pc 
		pop_density coastal
		,			
		trunit(`i') trperiod(1988) unitnames(region)  
		mspeperiod(1980(1)1988) resultsperiod(1980(1)1995)
			keep(synth_bmprate_`i'.dta) replace;
			matrix region`i' = e(RMSPE); /* check the V matrix*/
			};


 foreach i of local regionlist {;
 matrix rownames region`i'=`i';
 matlist region`i', names(rows);
 };

#delimit cr

 
local regionlist  4 5 7 8 12 14 16 17 18 21 23 24 25 26 27 28 29 30 31 32;

 foreach i of local regionlist {
 	use synth_bmprate_`i' ,clear
 	keep _Y_treated _Y_synthetic _time
 	drop if _time==.
	rename _time year
 	rename _Y_treated  treat`i'
 	rename _Y_synthetic counterfact`i'
 	gen gap`i'=treat`i'-counterfact`i'
 	sort year 
 	save synth_gap_bmprate`i'.dta, replace
}

use synth_gap_bmprate21.dta, clear
sort year
save placebo_bmprate21.dta, replace

local regionlist  4 5 7 8 12 14 16 17 18 21 23 24 25 26 27 28 29 30 31 32;

foreach i of local regionlist {
		merge year using synth_gap_bmprate`i'
		drop _merge
		sort year
	save placebo_bmprate.dta, replace
}

* All the placeboes on the same picture
use placebo_bmprate.dta, replace

* Picture of the full sample, including outlier RSMPE
#delimit;	

twoway 
(line gap4 year ,lp(solid)lw(vthin))||
(line gap5 year ,lp(solid)lw(vthin)) ||
(line gap7 year ,lp(solid)lw(vthin)) ||
(line gap8 year ,lp(solid)lw(vthin)) ||
(line gap12 year ,lp(solid)lw(vthin)) ||
(line gap14 year ,lp(solid)lw(vthin))||
(line gap16 year ,lp(solid)lw(vthin)) ||
(line gap17 year ,lp(solid)lw(vthin)) ||
(line gap18 year ,lp(solid)lw(vthin)) ||
(line gap23 year ,lp(solid)lw(vthin))||
(line gap24 year ,lp(solid)lw(vthin))||
(line gap25 year ,lp(solid)lw(vthin)) ||
(line gap26 year ,lp(solid)lw(vthin)) ||
(line gap27 year ,lp(solid)lw(vthin)) ||
(line gap28 year ,lp(solid)lw(vthin)) ||
(line gap29 year ,lp(solid)lw(vthin)) ||
(line gap30 year ,lp(solid)lw(vthin)) ||
(line gap31 year ,lp(solid)lw(vthin)) ||
(line gap21 year ,lp(solid)lw(thick)lcolor(black)), /*treatment unit, Hainan*/
yline(0, lpattern(shortdash) lcolor(black)) xline(1988, lpattern(shortdash) lcolor(black))
xtitle("",si(small)) xlabel(#10) ytitle("Gap in investment prediction error", size(small))
	legend(off);

#delimit cr

*-----------------------------------------------------------------

* Estimate the pre- and post-RMSPE and calculate the ratio of the 
* post-pre RMSPE
set more off

local regionlist  4 5 7 8 12 14 16 17 18 21 23 24 25 26 27 28 29 30 31 32;

foreach i of local regionlist {
use synth_gap_bmprate`i', clear
gen gap3=gap`i'*gap`i'
egen postmean=mean(gap3) if year>1988
egen premean=mean(gap3) if year<=1988
gen rmspe=sqrt(premean) if year<=1988
replace rmspe=sqrt(postmean) if year>1988
gen ratio=rmspe/rmspe[_n-1] if year==1989
gen rmspe_post=sqrt(postmean) if year>1988
gen rmspe_pre=rmspe[_n-1] if year==1989
mkmat rmspe_pre rmspe_post ratio if year==1989, matrix (region`i')
}

* show post/pre-expansion RMSPE ratio for all states, generate histogram
local regionlist  4 5 7 8 12 14 16 17 18 21 23 24 25 26 27 28 29 30 31 32;

foreach i of local regionlist {
matrix rownames region`i'=`i'
matlist region`i', names(rows)
}

#delimit ;
mat region=region4\region5\region7\region8\
region12\region14\region16\region17\region18\
region21\region23\region24\region25\region26\
region27\region28\region29\region30\region31;
#delimit cr

mat2txt, matrix(region) saving(rmspe_bmprate.txt) replace
insheet using rmspe_bmprate.txt, clear
ren v1 region
drop v5
gsort -ratio
gen rank=_n
gen p=rank/19
export excel using rmspe_bmprate, firstrow(variables) replace
import excel rmspe_bmprate.xls, sheet("Sheet1") firstrow clear
*Figure 6 - Histogram of RMSPE ratios
histogram ratio, bin(20) frequency fcolor(gs13) lcolor(black) ylabel(0(2)6) xtitle(Post/pre RMSPE ratio)
list rank p if region==21

*list regions with more than 2 times rmspe_pre of treatment
list region rmspe_pre if rmspe_pre > 2*298.8237

*-----------------------------------------------------------------
* Picture of the full sample, exluding outlier RSMPE
clear
use placebo_bmprate.dta, replace

#delimit;	

twoway 
(line gap4 year ,lp(solid)lw(vthin))||
(line gap7 year ,lp(solid)lw(vthin)) ||
(line gap8 year ,lp(solid)lw(vthin)) ||
(line gap12 year ,lp(solid)lw(vthin)) ||
(line gap14 year ,lp(solid)lw(vthin))||
(line gap16 year ,lp(solid)lw(vthin)) ||
(line gap17 year ,lp(solid)lw(vthin)) ||
(line gap18 year ,lp(solid)lw(vthin)) ||
(line gap23 year ,lp(solid)lw(vthin))||
(line gap24 year ,lp(solid)lw(vthin))||
(line gap25 year ,lp(solid)lw(vthin)) ||
(line gap27 year ,lp(solid)lw(vthin)) ||
(line gap28 year ,lp(solid)lw(vthin)) ||
(line gap21 year ,lp(solid)lw(thick)lcolor(black)), /*treatment unit, Hainan*/
yline(0, lpattern(shortdash) lcolor(black)) xline(1988, lpattern(shortdash) lcolor(black))
xtitle("",si(small)) xlabel(#10) ytitle("Gap in investment prediction error", size(small))
	legend(off);

#delimit cr

*-----------------------------------------------------------------
*Figure 5, combined placebos
graph combine placebo1.gph placebo2.gph
