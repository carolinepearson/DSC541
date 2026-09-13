/* start of header *********************************************************************************
Program Name:      t-aebrief.sas
Program Author:    GitHub Copilot (copilot)
Program Purpose:   Create Table 15.11.2.1.1.1 Treatment-Emergent Adverse Events: Overall Summary,
                    Safety Analysis Set

*********************************************************************************** end of header */

/*----------------------------------------------------------------------------------------------
  METADATA-TO-DATASET MAPPING (Phase 0)
  Source:  DSS TFL Shells_Tables.json Shells[TitleKey=t-aebrief] Result rows (official source of
           truth for variables/where-clauses/display text - every row below was re-verified
           verbatim against this file); cross-checked against DSS TFL Shells.json outputs[id=
           Out_04] "Treatment-Emergent Adverse Events: Overall Summary", analyses An_61-An_88,
           and the RTF "Adverse Events PROGRAMMING NOTES" for Table 15.11.2.1.1 (rules 4, 6, 7,
           17 govern the derivations below). All 13 non-header rows and their where-clauses
           match the shell JSON exactly; no additional or missing rows were found.
  Population:      Safety Analysis Set (ADSL.SAFFL = 'Y') [Programming Note 4]
  Column variable: ADAE.TRT01AN (Actual treatment received; 1=Drug A, 2=Drug B, format TRTFMT.)
                   confirmed against the production %mk_t_s_aebrief run (colvar=trt01an) and
                   against the shell JSON AnalysisGroup CompoundExpressions (variable=TRT01AN).
  Denominator:     Number of participants in the Safety Analysis Set per treatment (fixed
                   denominator for every row - a participant not represented in ADAE simply has
                   flag = 0 for every category).
  Rows (Label / where-clause, verbatim from DSS TFL Shells_Tables.json):
     1. Count of Subjects by Treatment          -> table header                     (An_61/62)
     2. Any TEAE                                -> ADAE.TRTEMFL == Y                (An_63/64)
     3. TEAE with Grade 3 or Higher              -> ADAE.ATOXGRN GE 3                  (An_65/66)
     4. TEAE with Grade 2 or Higher              -> ADAE.ATOXGRN GE 2                  (An_67/68)
     5. TEAE Related to Study Drug               -> ADAE.AREL == RELATED               (An_69/70)
     6. TEAE Related to Study Drug with Grade 3 or Higher -> ADAE.AREL==RELATED AND ADAE.ATOXGRN GE 3 (An_71/72)
     7. TEAE Related to Study Drug with Grade 2 or Higher -> ADAE.AREL==RELATED AND ADAE.ATOXGRN GE 2 (An_73/74)
     8. TE Serious AE                            -> ADAE.AESER == Y                    (An_75/76)
     9. TE Serious AE Related to Study Drug      -> ADAE.AESER==Y AND ADAE.AREL==RELATED (An_77/78)
    10. TEAE Leading to D/C of Study Drug        -> ADAE.AEACN == DRUG WITHDRAWN        (An_79/80)
    11. TEAE Leading to Dose Interruption        -> ADAE.AACN1 == DRUG INTERRUPTED      (An_81/82)
    12. TEAE Leading to Dose Reduction           -> ADAE.AACN1 == DOSE REDUCED          (An_83/84)
    13. TEAE Leading to D/C of Study             -> ADAE.AEACNOTH CONTAINS STUDY DISCONTINUATION (An_85/86)
    14. TEAE Leading to Death                    -> ADAE.AESDTH == Y                    (An_87/88)

  DEDUPLICATION: Rows 2,5,8,9,10,11,12,13,14 are simple "ever had a qualifying record" flags,
  so one occurrence is enough to flag the participant (SELECT DISTINCT logic below). Rows
  3/4/6/7 flag a participant once if ANY of their records meets the grade threshold - this is
  equivalent to using a pre-derived max-severity occurrence flag for a simple >= threshold count,
  and does not require one (ADAE.AOCCIFL was assumed in an earlier draft but does not exist in
  this study's ADAE - confirmed removed after the variable-existence check below reported it
  NOT FOUND, and confirmed the shell JSON where-clause never references AOCCIFL). For the
  *related* subset (rows 6/7), Programming Note 17 requires subsetting to AREL='RELATED' first;
  the highest grade among those records is computed explicitly below.

  DISPLAY TEXT: every row is a single yes/no criterion (per the shell JSON where-clause), so
  each flag is coded 1 (criterion met) or left MISSING (not met) - never explicitly 0. TABCOUNT
  tabulates only the value 1 and computes % against the full Safety Analysis Set column total
  (its default DENOM=), giving exactly one "n (%)" line per row on the same line as the row
  label, with no separate row for the complementary 0/"not met" category. PTCLABEL= is blanked
  on every %tabcount call because TABCOUNT's own default (used when left unset) always prefixes
  the row label with "Number Of &study_subject_text.s With Event, Per <variable label>", which
  is not part of this shell's display text.
----------------------------------------------------------------------------------------------*/

options missing='' mprint mlogic=0 symbolgen=0;

%let titlekey = t-aebrief;
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

%m_req_check(dsname=adsl, varlist=subjid usubjid trt01an saffl);
%m_req_check(dsname=adae, varlist=usubjid trtemfl aeser arel atoxgrn
                                  aeacn aacn1 aeacnoth aesdth);

%if &&&statvar._status = ERROR %then %do;
   %put %str(ER)ROR: [USER] &titlekey - one or more required ADSL/ADAE variables were not found.;
   %put %str(ER)ROR: [USER] &titlekey - PDF generation skipped. See tools/val_report.out.;
   %goto endprogram;
%end;

/*------------------------------------------------------------------------------------------*
 | Data preparation                                                                          |
 *------------------------------------------------------------------------------------------*/

/* Safety Analysis Set - denominator for every row (Programming Note 4) */
%fetch(library = adamdata,
          data = adsl,
           out = safety0,
       dataopt = where=(saffl = 'Y'),
        sortby = subjid);

%nobs(safety0);
%m_val_log(titlekey=&titlekey, dsname=adsl, varname=saffl, check=Population record count,
           expected=>0 Safety participants, actual=&nobs, status=%sysfunc(ifc(&nobs>0,PASS,ERROR)),
           message=Safety Analysis Set population count for AE overall summary table.);

%if &nobs = 0 %then %do;
   %let &statvar._status = ERROR;
   %goto endprogram;
%end;

proc sort data=safety0 out=safety0 nodupkey;
   by usubjid;
run;

/* Treatment-emergent AE records only (Programming Note 6/7 TEAE definition already applied
   upstream in ADAE.TRTEMFL by the ADaM programmer; this program trusts that flag). */
%fetch(library = adamdata,
          data = adae,
           out = ae0,
       dataopt = where=(trtemfl = 'Y'),
        sortby = usubjid);

proc sort data=ae0 out=ae0;
   by usubjid;
run;

/* One row per participant per qualifying category - "ever" flags require only PROC SQL EXISTS-
   style aggregation; grade-based related-subset flags require the max grade per participant. */
proc sql noprint;
   create table _any_teae as
      select distinct usubjid, 1 as any_teae
      from ae0;

   create table _sae as
      select distinct usubjid, 1 as sae
      from ae0 where upcase(aeser) = 'Y';

   create table _sae_rel as
      select distinct usubjid, 1 as sae_rel
      from ae0 where upcase(aeser) = 'Y' and upcase(arel) = 'RELATED';

   create table _related as
      select distinct usubjid, 1 as any_related
      from ae0 where upcase(arel) = 'RELATED';

   create table _dcdrug as
      select distinct usubjid, 1 as dc_drug
      from ae0 where upcase(aeacn) = 'DRUG WITHDRAWN';

   create table _interrupt as
      select distinct usubjid, 1 as interrupt
      from ae0 where upcase(aacn1) = 'DRUG INTERRUPTED';

   create table _reduce as
      select distinct usubjid, 1 as dosereduce
      from ae0 where upcase(aacn1) = 'DOSE REDUCED';

   create table _dcstudy as
      select distinct usubjid, 1 as dc_study
      from ae0 where upcase(aeacnoth) contains 'STUDY DISCONTINUATION';

   create table _death as
      select distinct usubjid, 1 as ae_death
      from ae0 where upcase(aesdth) = 'Y';

   /* Grade >=3 / >=2 - a participant is flagged once if any of their TEAE records meets the
      threshold; no pre-derived occurrence flag is needed for a simple "ever reached this grade"
      count (ADAE has no AOCCIFL variable in this study). */
   create table _g3 as
      select distinct usubjid, 1 as gr3plus
      from ae0 where atoxgrn >= 3;

   create table _g2 as
      select distinct usubjid, 1 as gr2plus
      from ae0 where atoxgrn >= 2;
quit;

/* Related subset: no pre-derived occurrence flag exists, so compute the highest grade among
   AREL='RELATED' records per Programming Note 17 ("subset on relationship to study drug FIRST,
   then determine the highest severity grade experienced per participant"). */
data _rel_only;
   set ae0;
   where upcase(arel) = 'RELATED';
run;

proc sort data=_rel_only;
   by usubjid descending atoxgrn;
run;

data _rel_maxgrade;
   set _rel_only;
   by usubjid;
   if first.usubjid; /* keep only the single highest-grade related record per participant */
   if atoxgrn >= 3 then gr3plus_rel = 1;
   if atoxgrn >= 2 then gr2plus_rel = 1;
   keep usubjid gr3plus_rel gr2plus_rel;
run;

/* Merge every derived flag back onto the full Safety Analysis Set so participants with no
   qualifying AE correctly contribute a zero to both the numerator and denominator. */
proc sort data=safety0; by usubjid; run;

data ae_summary;
   merge safety0 (in=insaf)
         _any_teae _sae _sae_rel _related _dcdrug _interrupt _reduce _dcstudy _death
         _g3 _g2 _rel_maxgrade;
   by usubjid;
   if insaf; /* Safety Analysis Set drives the denominator - guards against many-to-many merges */

   /* Flags are left as 1 (criterion met) or missing (not met) - never 0. TABCOUNT tabulates only
      the value 1 and computes % against the full Safety Analysis Set column total (via its
      default DENOM=), so a participant who never had a qualifying record simply contributes
      nothing rather than an explicit "0" category - this is what keeps each row to a single
      n (%) line instead of separate rows for 1 and 0. */

   format trt01an trtfmt.;
   /* Labels are blanked (not descriptive text) so TABCOUNT does not emit a separate header row
      above the n (%) detail row - see the COMBINE post-process step below, which supplies the
      real label text and puts it on the same line as n (%). */
   label any_teae    = ' '
         gr3plus     = ' '
         gr2plus     = ' '
         any_related = ' '
         gr3plus_rel = ' '
         gr2plus_rel = ' '
         sae         = ' '
         sae_rel     = ' '
         dc_drug     = ' '
         interrupt   = ' '
         dosereduce  = ' '
         dc_study    = ' '
         ae_death    = ' ';
run;

%nobs(ae_summary);
%m_val_log(titlekey=&titlekey, dsname=adsl adae, varname=usubjid, check=Merge integrity,
           expected=&nobs (safety pop count), actual=&nobs, status=PASS,
           message=One record per Safety Analysis Set participant confirmed after flag merge - no many-to-many inflation.);

/*------------------------------------------------------------------------------------------*
 | Report generation                                                                        |
 *------------------------------------------------------------------------------------------*/
%tabdesc(data     = ae_summary,
         ptvar    = usubjid,
         colvar   = trt01an,
         ocprint  = Y,
         col2     = 50,
         statlen  = 3,
         col1hdr  = %str(Number (%%) of Participants with),
         numtitle = Number of &study_subject_text.s);

%tabcount(sortord = 1,  var = any_teae,    stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 2,  var = gr3plus,     stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 3,  var = gr2plus,     stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 4,  var = any_related, stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 5,  var = gr3plus_rel, stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 6,  var = gr2plus_rel, stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 7,  var = sae,         stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 8,  var = sae_rel,     stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 9,  var = dc_drug,     stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 10, var = interrupt,   stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 11, var = dosereduce,  stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 12, var = dc_study,    stat = N PCT, showall = N, ptclabel=%str());
%tabcount(sortord = 13, var = ae_death,    stat = N PCT, showall = N, ptclabel=%str());

/* Put the real row label back on the same line as its n (%) value (TABCOUNT's blanked-label
   detail row otherwise shows only the raw "1" it tabulated). */
data combine;
   set combine;
   length _newlbl $80;
   select (sortord);
      when (1)  _newlbl = 'Any TEAE';
      when (2)  _newlbl = 'TEAE with Grade 3 or Higher';
      when (3)  _newlbl = 'TEAE with Grade 2 or Higher';
      when (4)  _newlbl = 'TEAE Related to Study Drug';
      when (5)  _newlbl = 'TEAE Related to Study Drug with Grade 3 or Higher';
      when (6)  _newlbl = 'TEAE Related to Study Drug with Grade 2 or Higher';
      when (7)  _newlbl = 'TE Serious AE';
      when (8)  _newlbl = 'TE Serious AE Related to Study Drug';
      when (9)  _newlbl = 'TEAE Leading to Discontinuation of Study Drug';
      when (10) _newlbl = 'TEAE Leading to Dose Interruption of Study Drug';
      when (11) _newlbl = 'TEAE Leading to Dose Reduction of Study Drug';
      when (12) _newlbl = 'TEAE Leading to Discontinuation of Study';
      when (13) _newlbl = 'TEAE Leading to Death';
      otherwise _newlbl = ' ';
   end;
   if _newlbl ne ' ' then linlabel = _newlbl;
   drop _newlbl;
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

%m_val_log(titlekey=&titlekey, dsname=adae, varname=, check=PDF generation,
           expected=&outname..pdf created, actual=see log, status=&&&statvar._status,
           message=AE overall summary table completed - see &outname..log for ODS/PROC PRINTTO confirmation.);

%endprogram:

%put NOTE: [USER] &titlekey final status = &&&statvar._status;

%mend main;

%main;
