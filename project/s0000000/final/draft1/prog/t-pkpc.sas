/* start of header *********************************************************************************
Program Name:      t-pkpc.sas
Program Author:    GitHub Copilot (copilot)
Program Purpose:   Create Table 15.10.1.1.x Individual Data and Summary Statistics of Plasma
                    Concentration (ng/mL) at Protocol-Specified Sampling Times, PK Analysis Set

*********************************************************************************** end of header */

/*----------------------------------------------------------------------------------------------
  METADATA-TO-DATASET MAPPING (Phase 0)
  Source:  DSS TFL Shells_Tables.json Shells[TitleKey=t-pkpc] Result rows (official source of
           truth); cross-checked against DSS TFL Shells.json outputs[id=Out_05] "Individual
           Data and Summary Statistics of Plasma Concentration...", analyses An_89-An_94, and
           tools/tnf.inc titlekey=t-pkpc. The shell JSON where-clause for the BLQ rows is
           verbatim "ADPC.AVALC == BLQ", confirming the AVALC/BLQ handling used below. The CI
           row label was corrected in the shell JSON/RTF to "95% CI (Lower)"/"95% CI (Upper)",
           which now matches the global macro %pkconc's built-in confidence interval exactly.
  Population:      PK Analysis Set (tnf.inc ttl2 = "PK Analysis Set") -> ADPC.PKFL = 'Y'
                    (fallback: merge ADSL.PKFL if ADPC carries no PKFL of its own - see below).
  Column variable: ADPC.TRT01PN (1=Drug A, 2=Drug B, format TRTFMT.).
  Table layout:    Rows = nominal post-dose sampling timepoint (Day 1, 0-24h, per tnf.inc
                   footnote 5 "samples over 24-hr postdose"); columns = summary statistics
                   (n, Mean, SD, %CV, Median, Min, Max, 95% CI), repeated per treatment group.

  GLOBAL MACRO USAGE: with the shell now specifying a 95% CI, this table is rendered via the
  bpgl global macro %m_pkconc_new (per-macro priority; switched from the older %pkconc per
  20260830 request), which produces the summary statistics, geometric-mean 95% CI (GMEAN/
  GCILOW/GCIUPP, T-distribution, matches "dist=T"), BLQ-aware n/Mean/SD/Median/Min/Max
  derivation, the shell's ">1/3 BLQ" and "% BLQ" rows (LNF/LNP - NOT available in the older
  %pkconc macro, which only produces a plain "# BLQ" count), and the final PDF (via its own
  internal %printset/%pageset calls against tools/tnf.inc, titlekey=t-pkpc) - no custom PROC
  REPORT/ODS PDF code is used for this table. %m_pkconc_new's input contract is column-name-
  parameterized (ptvar=, trt=, hour=, conc=, analvar=, pkvar=), so ADPC's own column names
  (USUBJID, TRT01PN, AVALC, PARAM) are passed directly with no rename step; a numeric
  PK-population flag (required by pkvar=, which the macro expects as a 0/1 numeric WHERE-filter
  variable) is derived, since ADPC/ADSL carry PKFL as a character Y/N flag, and ATPTN is copied
  to a variable literally named HOUR (m_pkconc_new.sas hardcodes the literal column name "hour"
  in one of its internal PROC SQL joins, not the &hour macro variable, so passing hour=atptn
  alone crashes with "Column hour could not be found").
  NOTE: %m_pkconc_new's own BLQ suppression thresholds now match tnf.inc footnote 3 exactly
  (">1/3 BLQ" flagged directly, not approximated) - the prior disclosed trade-off from the
  older %pkconc macro no longer applies.
  ADPC variable names (AVAL, AVALC='BLQ', ATPTN, TRT01PN, PKFL, PARAM/PARAMCD) are reconstructed
  from a raw scan of the ADPC binary and from CDISC ADaM IG PK BDS conventions; existence is
  re-verified defensively below and the table is marked ERROR (no PDF produced) if a required
  variable cannot be resolved.
----------------------------------------------------------------------------------------------*/

options missing='' mprint mlogic symbolgen;

%let titlekey = t-pkpc;
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

%m_val_log(titlekey=&titlekey, dsname=adpc, varname=aval avalc atptn trt01pn pkfl paramcd,
           check=Variable-mapping assumption, expected=Standard ADaM PK BDS naming,
           actual=Not confirmed by an existing working program, status=WARNING,
           message=ADPC variable names and the row/column table layout are assumed per CDISC
ADaM IG PK BDS conventions and a raw token scan of the ADPC dataset - no t-s-pkpc production
reference exists. Re-verify with the study ADaM specification before promoting this program.);

%macro m_req_check(dsname=, varlist=, dslib=adamdata);
   %local _i _v _ok;
   %if %sysfunc(exist(&dslib..&dsname))=0 %then %do;
      %m_val_log(titlekey=&titlekey, dsname=&dsname, varname=, check=Dataset existence,
                 expected=&dslib..&dsname exists, actual=NOT FOUND, status=ERROR,
                 message=Required dataset &dslib..&dsname could not be found - table skipped.);
      %let &statvar._status = ERROR;
      %goto done;
   %end;
   %let _i = 1;
   %do %while (%scan(&varlist, &_i, %str( )) ne );
      %let _v = %scan(&varlist, &_i, %str( ));
      %m_chkvar(var=&_v, inds=&dsname, libnm=&dslib, abort=N, alert=N);
      %let _ok = &m_chkvar;
      %if %eval(&_ok) = 0 %then %do;
         %m_val_log(titlekey=&titlekey, dsname=&dsname, varname=&_v, check=Variable existence,
                    expected=Variable &_v present, actual=NOT FOUND, status=ERROR,
                    message=Required variable &_v not found in &dslib..&dsname - table marked ERROR.);
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

%m_req_check(dsname=adpc, varlist=usubjid subjid siteid trt01pn paramcd param aval avalc atptn);

/* PKFL may live on ADPC itself or only on ADSL - check both before failing the table */
%m_chkvar(var=pkfl, inds=adpc, libnm=adamdata, abort=N, alert=N);
%let _pkfl_on_adpc = &m_chkvar;
%if %eval(&_pkfl_on_adpc) = 0 %then %do;
   %m_chkvar(var=pkfl, inds=adsl, libnm=adamdata, abort=N, alert=N);
   %let _pkfl_on_adsl = &m_chkvar;
   %if %eval(&_pkfl_on_adsl) = 0 %then %do;
      %m_val_log(titlekey=&titlekey, dsname=adpc adsl, varname=pkfl, check=Variable existence,
                 expected=PKFL present on ADPC or ADSL, actual=NOT FOUND on either, status=ERROR,
                 message=Cannot identify the PK Analysis Set population - table marked ERROR.);
      %let &statvar._status = ERROR;
   %end;
   %else %do;
      %m_val_log(titlekey=&titlekey, dsname=adsl, varname=pkfl, check=Variable existence,
                 expected=PKFL present, actual=FOUND on ADSL (not ADPC), status=PASS,
                 message=PK Analysis Set flag sourced from ADSL via USUBJID merge.);
   %end;
%end;

%if &&&statvar._status = ERROR %then %do;
   %put %str(ER)ROR: [USER] &titlekey - one or more required ADPC/ADSL variables were not found.;
   %put %str(ER)ROR: [USER] &titlekey - PDF generation skipped. See tools/val_report.out.;
   %goto endprogram;
%end;

/*------------------------------------------------------------------------------------------*
 | Data preparation                                                                          |
 *------------------------------------------------------------------------------------------*/
%fetch(library = adamdata,
          data = adpc,
           out = pc0,
       dataopt = where=(upcase(paramcd) not in ('') ),
        sortby = usubjid);

%if %eval(&_pkfl_on_adpc) = 0 %then %do;
   /* Merge the PK Analysis Set flag from ADSL when ADPC does not already carry it */
   %fetch(library = adamdata, data = adsl, out = pkflag0, keep = usubjid pkfl, sortby = usubjid);
   proc sort data=pc0; by usubjid; run;
   data pc0;
      merge pc0(in=inpc) pkflag0(in=inadsl);
      by usubjid;
      if inpc; /* keep PC records only - ADSL merely supplies the flag, guards many-to-many */
   run;
%end;

data pc1;
   set pc0;
   where upcase(pkfl) = 'Y';
   /* %pkconc's PKVAR= parameter requires a numeric 0/1 WHERE-filter variable - ADPC/ADSL only
      carry PKFL as character Y/N, so derive the numeric flag it expects. Every record here has
      already been subset to the PK Analysis Set above, so the flag is always 1. */
   pkflag = 1;
   /* %m_pkconc_new hardcodes the LITERAL column name "hour" (not the &hour macro variable) in
      an internal PROC SQL join (stats&excl <- aclm on a.hour=b.hour) - passing hour=atptn alone
      leaves that join referencing a nonexistent "hour" column and crashes ("Column hour could
      not be found"), so the caller's hour variable must literally be named HOUR. */
   hour = atptn;
   /* Dummy day placeholder - PCDY has multiple distinct values across the PK population, which
      is not what DAY= is for here (single Day-1 serial PK sampling); a constant dummy avoids
      that without relying on %m_pkconc_new's own blank-day auto-creation (see day= below). */
   pkday = 1;
   /* %m_pkconc_new's internal m_pk_header callback (used to suppress a repeated "Participant ID"
      header on summary-stat pages) detects listing rows via prxmatch("/\d+-\d+/",...) against
      the displayed PTVAR value - plain SUBJID (e.g. "002") has no dash and never matches, so the
      header was blanked on every page, including real listing pages. SITEID-SUBJID is a standard
      site-subject display id, is short, and satisfies that pattern. */
   ptid = strip(siteid) || '-' || strip(subjid);
run;

%nobs(pc1);
%m_val_log(titlekey=&titlekey, dsname=adpc, varname=pkfl, check=Population record count,
           expected=>0 PK Analysis Set concentration records, actual=&nobs,
           status=%sysfunc(ifc(&nobs>0,PASS,ERROR)), message=PK Analysis Set record count.);

%if &nobs = 0 %then %do;
   %let &statvar._status = ERROR;
   %goto endprogram;
%end;

/* %pkconc's own default hour-header logic (no hrfmt= given) shows "Pre-dose" for hour=0 and the
   bare number (no unit) for every other timepoint - build a format, from the ATPTN values
   actually present, that appends "h" to every non-zero timepoint while leaving Pre-dose as-is. */
proc sql noprint;
   create table _hrfmt_cntl as
      select distinct hour as start,
             ifc(hour = 0, 'Pre-dose', cats(put(hour, best.), 'h')) as label length=20,
             'hrfmt' as fmtname length=8,
             'N' as type length=1
      from pc1;
quit;

proc format cntlin=_hrfmt_cntl;
run;

/* %pkconc subsets internally on WHERE UPCASE(&analvar)="&analyte" - determine the single
   analyte value present in the data dynamically rather than hard-coding the tnf.inc footnote's
   placeholder text ("GS-XXXX"). */
proc sql noprint;
   select count(distinct param) into :_nanalyte trimmed from pc1;
   select distinct param into :analyte1-:analyte99 from pc1;
quit;

%if &_nanalyte ne 1 %then %do;
   %m_val_log(titlekey=&titlekey, dsname=adpc, varname=param, check=Single-analyte assumption,
              expected=Exactly 1 distinct PARAM value, actual=&_nanalyte,
              status=%sysfunc(ifc(&_nanalyte>0,WARNING,ERROR)),
              message=%str(%%)pkconc requires one ANALYTE value per call - using the first distinct
PARAM value found (&analyte1). Re-verify if more than one analyte is expected in this table.);
%end;

%if &_nanalyte = 0 %then %do;
   %let &statvar._status = ERROR;
   %goto endprogram;
%end;

/*------------------------------------------------------------------------------------------*
 | Render exactly one PDF: t-pkpc.pdf, via the global macro %m_pkconc_new.                    |
 | ptvar/trt/hour/conc/analvar reference ADPC's own column names directly (no renaming);      |
 | CONCN is left blank so %m_pkconc_new derives it from CONC itself, applying its own BLQ->0   |
 | logic (tnf.inc footnote 2) automatically. GMEAN/GCILOW/GCIUPP request the geometric-mean    |
 | 95% CI (T-distribution) that the shell JSON's "95% CI (Lower)/(Upper)" rows call for.       |
 *------------------------------------------------------------------------------------------*/
%m_pkconc_new(data      = pc1,
        ptvar     = ptid, /* SITEID-SUBJID - see the pc1 data step comment for why bare SUBJID
                             breaks the macro's own "Participant ID" header-repeat suppression */
        col1hdr   = %str(Participant ID),
        col1wdh   = 16, /* default is 30 - far wider than a short site-subject id needs */
        pkvar     = pkflag,
        titlekey  = &titlekey,
        outname   = &outname,
        analyte   = &analyte1,
        analvar   = param,
        trt       = trt01pn,
        trtfmt    = trtfmt,
        day       = pkday, /* constant dummy day - leaving day= blank relies on %m_pkconc_new's
                             own dummy-day auto-creation, which does not patch every internal
                             dataset and crashes with "Variable DAY not found"; PCDY was tried
                             instead but has multiple distinct values across the PK population,
                             which is not what DAY= is for with single Day-1 serial PK sampling */
        hour      = hour, /* must literally be named HOUR - see the pc1 data step comment */
        hrfmt     = hrfmt, /* appends "h" to each non-zero timepoint header (e.g. "1h", "2h"),
                               keeping "Pre-dose" as-is - see the CNTLIN-built format above */
        conc      = avalc,
        concn     = , /* must be explicitly blanked - the macro's own default is "concn", not
                          blank, so omitting this entirely does NOT trigger auto-derivation */
        dp        = 2,
        dist      = T,
		alpha_a   =0.05,      /** For arithmetic mean: 0.05 for 95% confidence interval and 0.1 for 90% confidence interval **/
 		alpha_g   =0.05,      /** For geometric mean: 0.05 for 95% confidence interval and 0.1 for 90% confidence interval **/
		clm       = Y,             /** Want to show lower and upper confidence interval limits for arithmetic mean? **/
        gn        = Y,
        gmean     = Y,
        gcv		  = Y,           /** Want Geom CV presented on output or not (default=N) - O **/        gcilow    = Y,
        gciupp    = Y,
        spanhdr   = Sampling Time (h),
        trttitl   = Treatment,
        wantintext= N,
        vdata     = vdata); /* the study's vdata libref, auto-assigned by the gsub job wrapper -
                               matches the working reference program's usage (t-pkconc-gs1614.sas
                               passes vdata=vdata); leaving this blank is not what any confirmed
                               working %m_pkconc_new caller does */

%endprogram:


%mend main;

%main;
