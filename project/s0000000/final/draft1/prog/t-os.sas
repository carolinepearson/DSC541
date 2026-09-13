/* start of header *********************************************************************************
Program Name:      t-os.sas
Program Author:    GitHub Copilot (copilot)
Program Purpose:   Create Table 15.9.1.x Overall Survival (OS), ITT Analysis Set

*********************************************************************************** end of header */

/*----------------------------------------------------------------------------------------------
  METADATA-TO-DATASET MAPPING (Phase 0)
  Source:  DSS TFL Shells_Tables.json Shells[TitleKey=t-os] Result rows (official source of
           truth for variables/where-clauses/display text); cross-checked against DSS TFL
           Shells.json outputs[id=Out_03] "Overall Survival (OS)", analyses An_45-An_60, and
           tools/tnf.inc titlekey=t-os (title/footnote text, including footnote markers a-d).
  Population:      ITT Analysis Set (tnf.inc ttl2 = "ITT Analysis Set") -> ADTTE.ITTFL = 'Y'
  Column variable: ADTTE.TRT01PN (1=Drug A, 2=Drug B, format TRTFMT.) - consistent with the
                   TRT01PN convention confirmed for ADSL in t-disp/t-demog.
  Rows (Label / where-clause, verbatim from DSS TFL Shells_Tables.json):
     1. Number (%) of Participants with Events (Death)               -> ADTTE.CNSR == 0
     2. Number (%) of Participants Censored                          -> ADTTE.CNSR NE 1 in the
        shell JSON; implemented here as the standard ADaM complement CNSR = 1 (CNSR NE 1 would
        also include any non-0/1 value, which is not a defensible category for a binary CNSR
        variable and is treated as a metadata-authoring artifact, not a literal instruction).
     3. Kaplan-Meier Estimate of OS (Months) (95% CI) [a]             -> PROC LIFETEST median, loglog CI
     4. Kaplan-Meier Estimate of OS Rate (%) (95% CI) (header row), with sub-rows
        "At 6 Months" / "At 12 Months" / "At 18 Months"             -> PROC LIFETEST TIMELIST
     5. Hazard Ratio of A vs B (95% CI) [b], log-rank P value [c]     -> PROC PHREG / PROC LIFETEST
     6. Duration of OS Follow-up (Months) [d] (header row), with sub-rows ">= 6 Months" /
        ">= 12 Months" / ">= 18 Months"                            -> n (%) with AVAL >= threshold
     (No separate "Number of Participants" row - not part of the shell; the column header's
     (N=xx) text, via TABDESC's numtitle=, already conveys the group size.)

  GLOBAL MACRO USAGE: calling %tmtoevnt/%m_tmtoevnt directly was not used (both always produce
  three separate output files with their own tnf.inc titlekeys that don't exist - only the bare
  "t-os" key is defined - conflicting with the single-PDF-per-titlekey requirement). Per-macro
  priority, the relevant CODE was instead pulled directly from tmtoevnt.sas's internal %cumrate
  and %hratio submacros and adapted below rather than written from scratch:
     - TIME statement convention: tmtoevnt.sas's %hratio submacro uses
       `model &dvar*&cvar(0) = &colvar` - adapted here as `aval*cnsr(1)` (ADTTE.CNSR follows the
       standard ADaM direction: 0=event, 1=censored, so CNSR itself is used directly with no
       derived indicator variable needed).
     - Hazard ratio: tmtoevnt.sas's %hratio submacro uses `class &colvar(ref=...)/param=ref;
       model .../rl; hazardratio &colvar / diff=ref;` - the `/rl` model option is what actually
       populates HRLowerCL/HRUpperCL in the ParameterEstimates ODS table (a prior revision of
       this program omitted /rl, which would have left the hazard ratio CI blank).
     - Median OS and landmark survival rate: tmtoevnt.sas's %cumrate submacro drives
       `strata &colvar;` off the PROC LIFETEST TIME statement and captures ODS Quartiles /
       ProductLimitEstimates output data sets - the same ODS tables (Quartiles,
       ProductLimitEstimates, HomTests, ParameterEstimates) are used below.
     - Rendering: %tabdesc/%tabcount build the standard COMBINE dataset (linlabel/sortord/
       statord/value1-value&_maxcol/level) for the Events/Censored/Duration count rows, exactly
       as t-disp.sas/t-aebrief.sas do; the KM median/KM rate/Hazard Ratio/log-rank rows are built
       directly in that SAME field structure and appended into COMBINE via a plain `data
       combine; set combine ...;` step (mirroring the production reference program
       G:\projects\p627\s21\ia01\version1\prog\t-os-a.sas, which does
       `set combine t odd pval;`) - %tabprep/%printset/%tabdrpt then render the whole table in
       one pass, keeping the font/page layout identical across all 5 tables. A prior revision of
       this program built a separate hand-rolled PROC REPORT dataset instead, which is why the
       KM estimate rows were not appearing in the rendered PDF.
     - Blank separator rows: appended at the END of each section (same sortord as that section's
       last row, statord='9' so it sorts last) - TABPREP
       (`if first.sortord and linlabel=' ' then delete;`) only deletes a blank-linlabel row when
       it is the FIRST record of its sortord group, so a trailing blank row survives.
     - Duration of OS follow-up: not directly produced by tmtoevnt.sas; implemented per the
       shell's explicit ">= 6/12/18 Months" categories (label wording confirmed against the
       production reference program's dur1t-dur5t formats) as a PROC SQL count of participants
       with AVAL (analysis time to event or censoring) at least that long - the minimum
       demonstrated follow-up, not a KM/reverse-KM estimate. Built as a SQL count (not TABCOUNT)
       so a row always appears, even "0 (0.0%)", when no participant reaches a given threshold.

  ASSUMPTION (confirmed 20260830 - ADSL/ADTTE were updated so AVAL is in DAYS, matching this):
  ADTTE is assumed to follow standard CDISC ADaM BDS time-to-event conventions:
     AVAL   = analysis time in DAYS from randomization/first dose to event or censoring
              (matches tnf.inc footnote a/d formula: (date - date + 1)/30.4375 = months)
     CNSR   = 0 (event/death occurred) / 1 (censored) - standard ADaM direction
     PARAMCD/PARAM = 'OS' / 'Overall Survival (OS)'
     TRT01PN, ITTFL present as copied from ADSL.
  These names were reconstructed from a raw scan of the ADTTE binary (confirmed tokens: AVAL,
  CNSR (as "CENSORED"/"EVENT" format labels), PARAM, PARAMCD, TRT01PN, ITTFL, STARTDT, ADT) and
  from CDISC ADaM IG BDS/TTE conventions. Variable existence is re-verified defensively below;
  if any assumed variable is not found the table is marked ERROR and no PDF is produced
  (Phase 1e), and the assumption is logged to tools/val_report.out for statistician review.
----------------------------------------------------------------------------------------------*/

options missing='' mprint mlogic=0 symbolgen=0;

%let titlekey = t-os;
%let outname  = &titlekey;
%let statvar  = %sysfunc(translate(&titlekey,'_','-'));  /* macro variable names cannot contain '-' */
%global &statvar._status;
%let &statvar._status = PASS;

%let tools = ../tools;
libname adamdata "../adamdata";
libname tools    "&tools";
libname libfmt   "&tools";
options fmtsearch = (libfmt work);

%include "&tools/init.inc";

%macro m_val_init;
   %if %sysfunc(exist(tools.val_report))=0 %then %do;
      data tools.val_report;
         length titlekey $16 dsname $16 varname $32 check $60 expected $100
                actual $100 status $10 message $200;
         format rundttm datetime20.;
         call missing(titlekey, dsname, varname, check, expected, actual, status, message, rundttm);
         delete;
      run;
   %end;
%mend m_val_init;

%macro m_val_log(titlekey=, dsname=, varname=, check=, expected=, actual=, status=, message=);
   data _val_rec;
      length titlekey $16 dsname $16 varname $32 check $60 expected $100
             actual $100 status $10 message $200;
      titlekey = "&titlekey";
      dsname   = "&dsname";
      varname  = "&varname";
      check    = "&check";
      expected = "&expected";
      actual   = "&actual";
      status   = "&status";
      message  = "&message";
      rundttm  = datetime();
      format rundttm datetime20.;
   run;
   proc append base=tools.val_report data=_val_rec force; run;
   proc datasets library=work nolist memtype=data; delete _val_rec; quit;
%mend m_val_log;

%m_val_init;

%m_val_log(titlekey=&titlekey, dsname=adtte, varname=aval cnsr paramcd trt01pn ittfl,
           check=Variable-mapping assumption, expected=Standard ADaM BDS/TTE naming,
           actual=Not confirmed by an existing working program, status=WARNING,
           message=ADTTE variable names (AVAL/CNSR/PARAMCD/TRT01PN/ITTFL) are assumed per
CDISC ADaM IG and binary token scan - no t-s-os production reference exists. Re-verify with the
study ADaM specification before promoting this program.);

%macro m_req_check(dsname=, varlist=);
   %local _i _v _ok;
   %if %sysfunc(exist(adamdata.&dsname))=0 %then %do;
      %m_val_log(titlekey=&titlekey, dsname=&dsname, varname=, check=Dataset existence,
                 expected=adamdata.&dsname exists, actual=NOT FOUND, status=ERROR,
                 message=Required dataset adamdata.&dsname could not be found - table skipped.);
      %let &statvar._status = ERROR;
      %goto done;
   %end;
   %let _i = 1;
   %do %while (%scan(&varlist, &_i, %str( )) ne );
      %let _v = %scan(&varlist, &_i, %str( ));
      %m_chkvar(var=&_v, inds=&dsname, libnm=adamdata, abort=N, alert=N);
      %let _ok = &m_chkvar;
      %if %eval(&_ok) = 0 %then %do;
         %m_val_log(titlekey=&titlekey, dsname=&dsname, varname=&_v, check=Variable existence,
                    expected=Variable &_v present, actual=NOT FOUND, status=ERROR,
                    message=Required variable &_v not found in adamdata.&dsname - table marked ERROR.);
         %let &statvar._status = ERROR;
      %end;
      %else %do;
         %m_val_log(titlekey=&titlekey, dsname=&dsname, varname=&_v, check=Variable existence,
                    expected=Variable &_v present, actual=FOUND, status=PASS, message= );
      %end;
      %let _i = %eval(&_i + 1);
   %end;
   %done:
%mend m_req_check;

%macro main;

%m_req_check(dsname=adtte, varlist=usubjid trt01pn ittfl paramcd aval cnsr);

%if &&&statvar._status = ERROR %then %do;
   %put %str(ER)ROR: [USER] &titlekey - one or more required ADTTE variables were not found.;
   %put %str(ER)ROR: [USER] &titlekey - PDF generation skipped. See tools/val_report.out.;
   %goto endprogram;
%end;

/*------------------------------------------------------------------------------------------*
 | Data preparation - ITT Analysis Set, OS parameter, one record per participant             |
 *------------------------------------------------------------------------------------------*/
%fetch(library = adamdata,
          data = adtte,
           out = os0,
       dataopt = where=(ittfl = 'Y' and upcase(paramcd) = 'OS'),
        sortby = usubjid);

%nobs(os0);
%m_val_log(titlekey=&titlekey, dsname=adtte, varname=paramcd, check=Population record count,
           expected=>0 ITT participants with PARAMCD=OS, actual=&nobs,
           status=%sysfunc(ifc(&nobs>0,PASS,ERROR)),
           message=ITT Analysis Set / OS parameter record count.);

%if &nobs = 0 %then %do;
   %let &statvar._status = ERROR;
   %goto endprogram;
%end;

proc sort data=os0 out=os1 nodupkey;
   by usubjid;
run;

proc format;
   value eventfmt 1 = 'Event';
   value censfmt  1 = 'Censored';
run;

data os1;
   set os1;
   /* Guard against unintended duplicate participant contributions to the survival model */
   if aval le . then do;
      put "WARN" "ING: [USER] Missing AVAL for USUBJID=" usubjid " - excluded from OS analysis.";
      delete;
   end;
   /* 1/missing (never 0) so TABCOUNT's showall=N shows only the single matching category - an
      explicit 0/1 flag would tabulate BOTH values, duplicating every row (the 90%/10% rows seen
      in the prior PDF were EVENT=0/EVENT=1 and CENS=0/CENS=1 both being displayed). */
   if cnsr = 0 then event = 1;   /* Number (%) of Participants with Events (Death) -> CNSR == 0 */
   if cnsr = 1 then cens  = 1;   /* Number (%) of Participants Censored -> CNSR == 1 (standard ADaM
                                    direction; RTF sample code uses "Censored(1)"; the shell JSON's
                                    literal "CNSR NE 1" is a metadata-authoring artifact - CNSR NE 1
                                    would also match every CNSR=0 (event) participant, giving the
                                    Events and Censored rows 100% overlapping counts) */
   label event = ' ' cens = ' ';
   format trt01pn trtfmt. event eventfmt. cens censfmt.;
run;

proc sql noprint;
   select min(aval), max(aval) into :_aval_min trimmed, :_aval_max trimmed from os1;
quit;
/* Informational only - if Max AVAL is below a landmark threshold (182.625/365.25/547.875 days
   for 6/12/18 months), PROC LIFETEST cannot estimate the survival rate or duration-of-follow-up
   count at that landmark - NEst/0 in the table reflects genuinely short follow-up in the data,
   not a program error. Plain %put used here (not %m_val_log) - a free-text macro-call argument
   containing its own embedded "word=" pattern can desync the macro call parser. */
%put NOTE: [USER] &titlekey - AVAL (days) ranges from &_aval_min to &_aval_max across os1.;

proc sql noprint;
   select count(distinct usubjid) into :n_all trimmed from os1;
   select count(distinct usubjid) into :n_a   trimmed from os1 where trt01pn = 1;
   select count(distinct usubjid) into :n_b   trimmed from os1 where trt01pn = 2;
quit;

%m_val_log(titlekey=&titlekey, dsname=adtte, varname=trt01pn, check=Treatment group counts,
           expected=2 treatment groups (Drug A, Drug B), actual=N(A)=&n_a N(B)=&n_b,
           status=%sysfunc(ifc(%eval(&n_a>0 and &n_b>0),PASS,ERROR)),
           message=Confirms both treatment arms are represented before modeling.);

/*------------------------------------------------------------------------------------------*
 | Kaplan-Meier estimates: median OS (log-log 95% CI), landmark survival rates at 6, 12 and   |
 | 18 months, and the log-rank p value comparing the two treatment groups.                    |
 *------------------------------------------------------------------------------------------*/
ods select none;
ods output Quartiles = _km_quartiles (where=(Percent=50))
           HomTests   = _km_logrank   (where=(Test='Log-Rank'));

/* OUTSURV=/REDUCEOUT (not ODS OUTPUT ProductLimitEstimates with TIMELIST/ATRISK) is the pattern
   the production reference program G:\projects\p627\s21\ia01\version1\prog\t-os-a.sas and the
   RTF's own OS/PFS programming notes use - REDUCEOUT reduces OUTSURV to one row per requested
   TIMELIST point while still carrying SURVIVAL/SDF_LCL/SDF_UCL on those rows. */
proc lifetest data=os1 method=km outsurv=_outsurv timelist=182.625 365.25 547.875 reduceout
              conftype=loglog;
   time aval*cnsr(1);
   strata trt01pn;
run;

ods select all;
ods output close;

/* Median OS (months) with log-log 95% CI, per treatment group */
data _km_median;
   length trtn 8;
   set _km_quartiles;
   trtn    = trt01pn;
   med_mo  = estimate / 30.4375;
   lcl_mo  = LowerLimit / 30.4375;
   ucl_mo  = UpperLimit / 30.4375;
run;

/* Survival rate (%) at 6, 12, and 18 months, per treatment group - _outsurv (REDUCEOUT) already
   carries SURVIVAL/SDF_LCL/SDF_UCL on the one row per requested TIMELIST point. */
data _km_rate;
   length trtn 8 timelbl $12;
   set _outsurv (where=(timelist ne .));
   trtn = trt01pn;
   if      round(timelist,0.01) = 182.63 then do; timelbl = 'At 6 Months';  ord = 1; end;
   else if round(timelist,0.01) = 365.25 then do; timelbl = 'At 12 Months'; ord = 2; end;
   else if round(timelist,0.01) = 547.88 then do; timelbl = 'At 18 Months'; ord = 3; end;
   rate    = survival*100;
   rate_l  = sdf_lcl*100;
   rate_u  = sdf_ucl*100;
run;

/*------------------------------------------------------------------------------------------*
 | Cox proportional hazards model - Hazard Ratio of Drug A vs Drug B (95% CI). MODEL .../rl    |
 | and the HAZARDRATIO statement are pulled directly from tmtoevnt.sas's own %hratio submacro  |
 | pattern - without /rl, PROC PHREG's ParameterEstimates table does not populate              |
 | HRLowerCL/HRUpperCL at all, which the previous revision of this program was missing.        |
 *------------------------------------------------------------------------------------------*/
ods select none;
ods output ParameterEstimates = _phreg_hr;

proc phreg data=os1;
   format trt01pn; /* CLASS ref= matches the FORMATTED value if a format is active - clear it so
                      ref='2' matches the raw TRT01PN value (Drug B) rather than display text */
   class trt01pn (ref='2') / param=ref;
   model aval*cnsr(1) = trt01pn / rl ties=exact; /* ties=exact matches the production reference
                                                     program's Cox model specification */
   hazardratio trt01pn / diff=ref;
run;

ods select all;
ods output close;

data _hr;
   set _phreg_hr;
   hr    = HazardRatio;
   hr_l  = HRLowerCL;
   hr_u  = HRUpperCL;
run;

%nobs(_hr);
%if &nobs = 0 %then %do;
   %m_val_log(titlekey=&titlekey, dsname=adtte, varname=trt01pn, check=Cox model convergence,
              expected=1 parameter estimate row, actual=0, status=ERROR,
              message=PROC PHREG produced no hazard ratio estimate - check for separation/too few events.);
   %let &statvar._status = ERROR;
%end;

%m_val_log(titlekey=&titlekey, dsname=adtte, varname=aval cnsr, check=Analysis completeness,
           expected=Model estimates for both KM and Cox PH, actual=see log, status=&&&statvar._status,
           message=Overall Survival KM/Cox analysis executed for ITT Analysis Set.);

%if &&&statvar._status = ERROR %then %goto endprogram;

/*------------------------------------------------------------------------------------------*
 | Report generation - uses the SAME global bpgl SP macro pipeline as t-disp/t-aebrief        |
 | (tabdesc/tabcount build COMBINE -> the custom KM/HR rows below are appended into COMBINE   |
 | in its own linlabel/sortord/statord/value1-value&_maxcol/level structure, exactly as the   |
 | production t-os-a.sas reference program does -> tabprep/printset/tabdrpt render the PDF),  |
 | instead of a hand-rolled PROC REPORT, so KM estimates render correctly and the font/page    |
 | layout matches the other tables. ocprint=N - no overall (Total) column on this table.       |
 *------------------------------------------------------------------------------------------*/
%tabdesc(data     = os1,
         ptvar    = usubjid,
         colvar   = trt01pn,
         ocprint  = N,
         col2     = 50,
         statlen  = 3,
         numtitle = Number of &study_subject_text.s);

%tabcount(sortord = 1, var = event, stat = N PCT, showall = Y, ptclabel=%str());
%tabcount(sortord = 2, var = cens,  stat = N PCT, showall = Y, ptclabel=%str());

/* Real row-label text for the tabcount rows (blanked labels above avoid a spurious header line
   above the n (%) value - same technique used in t-disp.sas/t-aebrief.sas), flush left (level=0
   overrides TABPREP's level*3 indent, which TABCOUNT otherwise sets to 1 for these single-
   variable rows). */
data combine;
   set combine;
   length _newlbl $80;
   select (sortord);
      when (1) _newlbl = 'Number (%) of Participants with Events (Death)';
      when (2) _newlbl = 'Number (%) of Participants Censored';
      otherwise _newlbl = ' ';
   end;
   if _newlbl ne ' ' then do;
      linlabel = left(_newlbl);
      level = 0;
   end;
   drop _newlbl;
run;

/* Regular leading blanks get collapsed by the PDF renderer (why plain PUT-width right-justify
   did not visually align digits) - byte(160) (non-breaking space) survives rendering, so pad
   with NBSP to right-justify stacked values within a section (ones digit/decimal aligned). */
%macro nbsppad(var, width);
   &var = cat(substr(_nbsp10,1,max(0,&width-length(&var))),&var);
%mend nbsppad;

/* Custom KM/Cox rows, built directly in COMBINE's own field structure (linlabel/sortord/
   statord/value1-value3/level) so they union cleanly into COMBINE via a plain SET statement -
   mirrors the production t-os-a.sas reference program's "data combine; set combine t odd
   pval;" pattern. A blank separator row is appended at the END of each section (same sortord
   as the section's last row, high statord='9' so it sorts last) - TABPREP deletes a blank-
   linlabel row only when it is the FIRST record of its sortord group, so a trailing blank
   survives while a standalone blank sortord group would not. */
data _med_row;
   length linlabel $250 statord $40 value1-value3 $40 _m _l _u $10;
   merge _km_median(where=(trtn=1) rename=(med_mo=medA lcl_mo=lclA ucl_mo=uclA))
         _km_median(where=(trtn=2) rename=(med_mo=medB lcl_mo=lclB ucl_mo=uclB));
   sortord  = 3;
   level    = 0;
   statord  = '1';
   linlabel = 'Kaplan-Meier Estimate of OS (Months) (95% CI) [a]';
   /* TABDRPT does not preserve leading-space padding as visual alignment, so left-justify   -
      strip() the numbers and cat() the literal delimiters (cats() would also strip the ' (') */
   if medA > . then _m = strip(put(medA,6.1)); else _m = 'NEst';
   if lclA > . then _l = strip(put(lclA,6.1)); else _l = 'NEst';
   if uclA > . then _u = strip(put(uclA,6.1)); else _u = 'NEst';
   value1   = cat(trim(_m),' (',trim(_l),', ',trim(_u),')');
   if medB > . then _m = strip(put(medB,6.1)); else _m = 'NEst';
   if lclB > . then _l = strip(put(lclB,6.1)); else _l = 'NEst';
   if uclB > . then _u = strip(put(uclB,6.1)); else _u = 'NEst';
   value2   = cat(trim(_m),' (',trim(_l),', ',trim(_u),')');
   value3   = ' ';
   output;
   statord  = '9';
   linlabel = ' ';
   value1 = ' '; value2 = ' '; value3 = ' ';
   output;
   keep linlabel sortord statord value1-value3 level;
run;

proc sql;
   create table _rate_final as
      select a.timelbl, a.ord, a.rate as rateA, a.rate_l as rate_lA, a.rate_u as rate_uA,
             b.rate as rateB, b.rate_l as rate_lB, b.rate_u as rate_uB
      from _km_rate(where=(trtn=1)) as a
      inner join _km_rate(where=(trtn=2)) as b
         on a.timelbl = b.timelbl
      order by a.ord;
quit;

data _rate_rows;
   length linlabel $250 statord $40 value1-value3 $40 _m _l _u $20 _nbsp10 $10;
   set _rate_final end=eof;
   sortord = 4;
   level   = 1; /* 3-space indent under the "Kaplan-Meier Estimate of OS Rate..." header row */
   value3  = ' ';
   statord = put(_n_,1.);
   linlabel = timelbl;
   _nbsp10 = byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160);
   if rateA > . then _m = strip(put(rateA,5.1)); else _m = 'NEst'; %nbsppad(_m,5);
   if rate_lA > . then _l = strip(put(rate_lA,5.1)); else _l = 'NEst'; %nbsppad(_l,5);
   if rate_uA > . then _u = strip(put(rate_uA,5.1)); else _u = 'NEst'; %nbsppad(_u,5);
   value1 = cat(trim(_m),' (',trim(_l),', ',trim(_u),')');
   if rateB > . then _m = strip(put(rateB,5.1)); else _m = 'NEst'; %nbsppad(_m,5);
   if rate_lB > . then _l = strip(put(rate_lB,5.1)); else _l = 'NEst'; %nbsppad(_l,5);
   if rate_uB > . then _u = strip(put(rate_uB,5.1)); else _u = 'NEst'; %nbsppad(_u,5);
   value2 = cat(trim(_m),' (',trim(_l),', ',trim(_u),')');
   output;
   if eof then do;
      statord = '9';
      linlabel = ' ';
      value1 = ' '; value2 = ' '; value3 = ' ';
      output;
   end;
   keep linlabel sortord statord value1-value3 level;
run;

data _rate_hdr;
   length linlabel $250 statord $40 value1-value3 $40;
   linlabel = 'Kaplan-Meier Estimate of OS Rate (%) (95% CI)';
   sortord = 4; level = 0; statord = '0';
   value1 = ' '; value2 = ' '; value3 = ' ';
run;

data _hrpval_rows;
   length linlabel $250 statord $40 value1-value3 $40;
   merge _hr _km_logrank;
   sortord = 5; level = 0; value2 = ' '; value3 = ' ';
   statord  = '1';
   linlabel = 'Hazard Ratio of A vs B (95% CI) [b]';
   value1   = cat(strip(put(hr,6.2)),' (',strip(put(hr_l,6.2)),', ',strip(put(hr_u,6.2)),')');
   output;
   statord  = '2';
   linlabel = 'Log-Rank P Value [c]';
   value1   = strip(put(ProbChiSq, pvalue6.4));
   output;
   statord  = '9';
   linlabel = ' ';
   value1 = ' ';
   output;
   keep linlabel sortord statord value1-value3 level;
run;

data _fu_hdr;
   length linlabel $250 statord $40 value1-value3 $40;
   linlabel = 'Duration of OS Follow-up (Months) [d]';
   sortord = 6; level = 0; statord = '0'; /* same sortord as the subrows below - TABDRPT skips a
                                             line whenever sortord changes, so a different sortord
                                             here would insert an unwanted blank line before the
                                             first subrow (matches the KM Rate header pattern) */
   value1 = ' '; value2 = ' '; value3 = ' ';
run;

/* Landmark follow-up counts, built as a PROC SQL count (not TABCOUNT) so a row is ALWAYS
   emitted per category - even "0 (0.0%)" - regardless of whether any participant actually
   reaches that threshold (TABCOUNT's showall=Y did not reliably emit a row when a flag variable
   was missing for every single observation, which is why these rows previously vanished). */
proc sql;
   create table _fu_final as
      select '>= 6 Months'  as timelbl length=20, 182.625 as thresh, 1 as ord
      from os1(obs=1)
      union
      select '>= 12 Months' as timelbl length=20, 365.25  as thresh, 2 as ord
      from os1(obs=1)
      union
      select '>= 18 Months' as timelbl length=20, 547.875 as thresh, 3 as ord
      from os1(obs=1);
quit;

proc sql;
   create table _fu_counts as
      select f.timelbl, f.thresh, f.ord,
             (select count(*) from os1 where trt01pn=1 and aval>=f.thresh) as cnt_a,
             (select count(*) from os1 where trt01pn=2 and aval>=f.thresh) as cnt_b
      from _fu_final as f
      order by f.ord;
quit;

data _fu_rows;
   length linlabel $250 statord $40 value1-value3 $40 _cnt _pct $20 _nbsp10 $10;
   set _fu_counts end=eof;
   sortord  = 6;
   level    = 1; /* 3-space indent under the "Duration of OS Follow-up..." header row */
   statord  = put(ord,1.);
   linlabel = timelbl;
   _nbsp10 = byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160)||byte(160);
   _cnt = strip(put(cnt_a,3.)); %nbsppad(_cnt,3);
   _pct = strip(put(100*cnt_a/&n_a,5.1)); %nbsppad(_pct,5);
   value1   = cat(trim(_cnt),' (',trim(_pct),'%)');
   _cnt = strip(put(cnt_b,3.)); %nbsppad(_cnt,3);
   _pct = strip(put(100*cnt_b/&n_b,5.1)); %nbsppad(_pct,5);
   value2   = cat(trim(_cnt),' (',trim(_pct),'%)');
   value3   = ' ';
   keep linlabel sortord statord value1-value3 level;
run;

data combine;
   set combine _med_row _rate_hdr _rate_rows _hrpval_rows _fu_hdr _fu_rows;
run;

%tabprep(titlekey = &titlekey,
         outname  = &outname,
         tsource  = &tools/tnf.inc,
         vdata    = vdata);

%printset(titlekey = &titlekey,
          outname  = &outname,
          tsource  = &tools/tnf.inc,
          orient   = landscape);

%tabdrpt(titlekey = &titlekey,
         outname  = &outname,
         cwidth   = );

%m_val_log(titlekey=&titlekey, dsname=adtte, varname=, check=PDF generation,
           expected=&outname..pdf created, actual=see log, status=&&&statvar._status,
           message=Overall Survival table completed - see &outname..log for ODS/PROC PRINTTO confirmation.);

%endprogram:

%put NOTE: [USER] &titlekey final status = &&&statvar._status;

%mend main;

%main;
