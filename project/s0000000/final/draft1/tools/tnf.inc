/****************************************************************************\
***  SAVED AS:        tnf.inc                                                *
***                                                                          *
***  GENERATED ON:    30AUG2026:15:39 by Macro %M_TNFCONV Version v4.19.01   *
***       BY USER:    cpearson1                                              *
***                                                                          *
***  TOOLS VERSION:   v4.19.01                                               *
***                                                                          *
***  EXECUTED UNDER:  LIN X64 SAS Version 9.4 at Gilead Sciences             *
***                                                                          *
***  DESCRIPTION:     Titles and Footnote file                               *
***                   for Study GS-US-000-0000                               *
***                                                                          *
***  INPUT  DATA SET: (none)                                                 *
***                                                                          *
***  OUTPUT DATA SET: (none)                                                 *
***                                                                          *
***  OUTPUT REPORT:   (none)                                                 *
***                                                                          *
***  LAST REVISED:                                                           *
***   ddmonyyyy (initials) (description of change)                           *
***                                                                          *
\****************************************************************************/

/*** ******************************************************************** ***/
/***     BEGIN GENERATED TNF CODE: 30AUG2026:15:39                        ***/
/*** ******************************************************************** ***/
/* ------------------------------------------------------------------------ */
/* default       */ %let ttl1 = NO ASSIGNED TITLE FOR JOB &titlekey;
/* ------------------------------------------------------------------------ */
/* t-disp Table 15.8.1.3.1.1: Participant Disposition, All Screened Participants */
/* t-disp */ %let ttl1 = %str(Table 15.8.1.3.1.1: Participant Disposition);
/* t-disp */ %let ttl2 = %str(All Screened Participants);
/* t-disp */ %let fnl1 = %str(Percentages for completion status were calculated based on the number of participants in the Safety Analysis Set.);
/* t-disp */ %let fnl2 = %str(Source: Listing 16.2.1.3.1);
/* ------------------------------------------------------------------------ */
/* t-s-disp Table 15.8.1.3.1.2: Participant Disposition, All Screened Participants, STARS Generated Output */
/* t-s-disp */ %let ttl1 = %str(Table 15.8.1.3.1.2: Participant Disposition);
/* t-s-disp */ %let ttl2 = %str(All Screened Participants);
/* t-s-disp */ %let ttl3 = %str(STARS Generated Output);
/* t-s-disp */ %let fnl1 = %str(Percentages for completion status were calculated based on the number of participants in the Safety Analysis Set.);
/* t-s-disp */ %let fnl2 = %str(Source: Listing 16.2.1.3.1);
/* ------------------------------------------------------------------------ */
/* t-demog Table 15.8.3.1.1: Demographics and Baseline Characteristics, ITT Analysis Set */
/* t-demog */ %let ttl1 = %str(Table 15.8.3.1.1: Demographics and Baseline Characteristics);
/* t-demog */ %let ttl2 = %str(ITT Analysis Set);
/* t-demog */ %let fnl1 = %str(Denominator for percentages was the ITT Analysis Set.);
/* t-demog */ %let fnl2 = %str(Age %(in years{or specify unit}%) was collected on date of Day 1 visit. [If age was not collected, age was derived using data of Day 1 visit if dose,);
/* t-demog */ %let fnl3 = %str(date of [randomization] [enrollment] if not dosed, or the date of informed consent if not randomized.);
/* t-demog */ %let fnl4 = %str(Body Mass Index %(BMI%) %(kg/m^2%) = [Weight %(kg%)/Height %(cm%) ^2] * 10,000.);
/* t-demog */ %let fnl5 = %str(Source: Listing 16.2.4.1);
/* ------------------------------------------------------------------------ */
/* t-s-demog Table 15.8.3.1.2: Demographics and Baseline Characteristics, ITT Analysis Set, STARS Generated Output */
/* t-s-demog */ %let ttl1 = %str(Table 15.8.3.1.2: Demographics and Baseline Characteristics);
/* t-s-demog */ %let ttl2 = %str(ITT Analysis Set);
/* t-s-demog */ %let ttl3 = %str(STARS Generated Output);
/* t-s-demog */ %let fnl1 = %str(Denominator for percentages was the ITT Analysis Set.);
/* t-s-demog */ %let fnl2 = %str(Age %(in years{or specify unit}%) was collected on date of Day 1 visit. [If age was not collected, age was derived using data of Day 1 visit if dose,);
/* t-s-demog */ %let fnl3 = %str(date of [randomization] [enrollment] if not dosed, or the date of informed consent if not randomized.);
/* t-s-demog */ %let fnl4 = %str(Body Mass Index %(BMI%) %(kg/m^2%) = [Weight %(kg%)/Height %(cm%) ^2] * 10,000.);
/* t-s-demog */ %let fnl5 = %str(Source: Listing 16.2.4.1);
/* ------------------------------------------------------------------------ */
/* t-os Table 15.9.1.x: Overall Survival (OS), ITT Analysis Set */
/* t-os */ %let ttl1 = %str(Table 15.9.1.x: Overall Survival %(OS%));
/* t-os */ %let ttl2 = %str(ITT Analysis Set);
/* t-os */ %let fnl1 = %str(NEst = Not Estimable.);
/* t-os */ %let fnl2 = %str(a   OS %(months%) = %(date of death or censoring – date of randomization + 1%)/30.4375, and the 95%% CI is derived using log-log);
/* t-os */ %let fnl3 = %str(transformation.);
/* t-os */ %let fnl4 = %str(b   Hazard ratio and 95%% CIs are calculated using the Cox proportional hazards model / statistical method.);
/* t-os */ %let fnl5 = %str(c   P value for comparing the overall survival functions from the two treatment groups is from.);
/* t-os */ %let fnl6 = %str(d   Duration of OS follow-up %(months%) = %(date of death or censoring – date of randomization + 1%)/30.4375.);
/* t-os */ %let fnl7 = %str(Source: Listing 16.2.6.x);
/* ------------------------------------------------------------------------ */
/* t-aebrief Table 15.11.2.1.1.1: Treatment-Emergent Adverse Events: Overall Summary, Safety Analysis Set */
/* t-aebrief */ %let ttl1 = %str(Table 15.11.2.1.1.1: Treatment-Emergent Adverse Events: Overall Summary);
/* t-aebrief */ %let ttl2 = %str(Safety Analysis Set);
/* t-aebrief */ %let fnl1 = %str(TE = treatment-emergent; TEAE = treatment-emergent adverse event.);
/* t-aebrief */ %let fnl2 = %str(Adverse events were coded according to MedDRA Version {XX.X}.);
/* t-aebrief */ %let fnl3 = %str(Treatment-emergent events began on or after the study drug start date up to {XX} days {or study drug-specific therapeutic reach} after the date of the);
/* t-aebrief */ %let fnl4 = %str( last dose of study drug [and prior to the day of initiation of subsequent anticancer/antiviral/etc therapy].);
/* t-aebrief */ %let fnl5 = %str(Severity grades were defined by [Gilead Grading Scale for Severity of Adverse Events and Laboratory Abnormalities][The CTCAE Version X][The DAIDS);
/* t-aebrief */ %let fnl6 = %str(Version XX]. [Participants were counted only one based on their highest grade for each summary row.]);
/* t-aebrief */ %let fnl7 = %str(Death includes any death that occurred during the study. Percentages for TEAE Dose Limiting Toxicity was calculated based on the number of);
/* ------------------------------------------------------------------------ */
/* t-s-aebrief Table 15.11.2.1.1.2: Treatment-Emergent Adverse Events: Overall Summary, Safety Analysis Set, STARS Generated Output */
/* t-s-aebrief */ %let ttl1 = %str(Table 15.11.2.1.1.2: Treatment-Emergent Adverse Events: Overall Summary);
/* t-s-aebrief */ %let ttl2 = %str(Safety Analysis Set);
/* t-s-aebrief */ %let ttl3 = %str(STARS Generated Output);
/* t-s-aebrief */ %let fnl1 = %str(TE = treatment-emergent; TEAE = treatment-emergent adverse event.);
/* t-s-aebrief */ %let fnl2 = %str(Adverse events were coded according to MedDRA Version {XX.X}.);
/* t-s-aebrief */ %let fnl3 = %str(Treatment-emergent events began on or after the study drug start date up to {XX} days {or study drug-specific therapeutic reach} after the date of the);
/* t-s-aebrief */ %let fnl4 = %str( last dose of study drug [and prior to the day of initiation of subsequent anticancer/antiviral/etc therapy].);
/* t-s-aebrief */ %let fnl5 = %str(Severity grades were defined by [Gilead Grading Scale for Severity of Adverse Events and Laboratory Abnormalities][The CTCAE Version X][The DAIDS);
/* t-s-aebrief */ %let fnl6 = %str(Version XX]. [Participants were counted only one based on their highest grade for each summary row.]);
/* t-s-aebrief */ %let fnl7 = %str(Death includes any death that occurred during the study. Percentages for TEAE Dose Limiting Toxicity was calculated based on the number of);
/* ------------------------------------------------------------------------ */
/* t-pkpc Table 15.10.1.1.x: Individual Data and Summary Statistics of Plasma Concentration (ng/mL) at Protocol-Specified Sampling Times, PK Analysis Set */
/* t-pkpc */ %let ttl1 = %str(Table 15.10.1.1.x: Individual Data and Summary Statistics of Plasma Concentration %(ng/mL%) at Protocol-Specified Sampling Times);
/* t-pkpc */ %let ttl2 = %str(PK Analysis Set);
/* t-pkpc */ %let fnl1 = %str(BLQ = below the limit of quantitation; LLOQ = lower limit of quantitation; CI = confidence interval.);
/* t-pkpc */ %let fnl2 = %str(Values BLQ were treated as 0 for predose and postdose.);
/* t-pkpc */ %let fnl3 = %str(If > 1/3 of postdose values are BLQ at a time point, then the mean, StD, and %%CV are not calculated at that time point.);
/* t-pkpc */ %let fnl4 = %str(LLQ was defined as 5.0 ng/mL for analyte GS-XXXX.);
/* t-pkpc */ %let fnl5 = %str(For each participant in PK analysis set, intensive serial PK sample collection %(samples over 24-hr postdose%) was performed at Day 1.);
/* ------------------------------------------------------------------------ */

/*** ******************************************************************** ***/
/***    END OF GENERATED TNF CODE - DO NOT MODIFY CODE ABOVE THIS LINE    ***/
/*** ******************************************************************** ***/
