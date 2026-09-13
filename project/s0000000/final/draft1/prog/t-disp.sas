/* start of header *********************************************************************************
Program Name:      t-disp.sas
Program Author:    GitHub Copilot (copilot)
Program Purpose:   Create Table 15.8.1.3.1.1 Participant Disposition, All Screened Participants

*********************************************************************************** end of header */

/*----------------------------------------------------------------------------------------------
  METADATA-TO-DATASET MAPPING (Phase 0)
  Source:  DSS TFL Shells_Tables.json Shells[TitleKey=t-disp] Result rows (official source of
           truth for variables/where-clauses/display text); cross-checked against DSS TFL
           Shells.json outputs[id=Out_01] "Participant Disposition" analyses An_01-An_25.
  Population:      All Screened Participants (ADSL.SCRNFL = 'Y')
  Column variable:  ADSL.TRT01PN (1=Drug A, 2=Drug B, format TRTFMT.)
  Rows (Label / variable / where-clause, verbatim from DSS TFL Shells_Tables.json):
     1. Count of Subjects by Treatment            -> table header (TABDESC headtot)
     2. Screened                                  -> ADSL.SCRNFL == Y  (derived ALL_SCRN=1)
     3. ITT Analysis Set                           -> ADSL.ITTFL == Y
     4. Safety Analysis Set                        -> ADSL.SAFFL == Y
     5. PK Analysis Set                            -> ADSL.PKFL == Y
     6. Study Drug Completion Status (header)
        Completed Study Drug                       -> ADSL.COMT01FL == Y
        Discontinued Study Drug                    -> ADSL.COMT01FL == N
     7. Reason for Discontinuation of Study Drug (header)
        Adverse Event                              -> ADSL.DCT01RS == ADVERSE EVENT
        Lack of Efficacy                           -> ADSL.DCT01RS == LACK OF EFFICACY
     8. Study Completion Status (header)
        Completed Study                            -> ADSL.COMSFL == Y
        Prematurely Discontinued Study              -> ADSL.COMSFL == N
     9. Reason for Discontinuation of Study (header)
        Death                                       -> ADSL.DCSREAS == DEATH
        Withdrawal by Subject                      -> ADSL.DCSREAS == WITHDRAWAL BY SUBJECT
----------------------------------------------------------------------------------------------*/

options missing='' mprint mlogic=0 symbolgen=0;

%let titlekey = t-disp;
%let outname  = &titlekey;
%let statvar  = %sysfunc(translate(&titlekey,'_','-'));  /* macro variable names cannot contain '-' */
%global &statvar._status;
%let &statvar._status = PASS;

/*--- Study folder layout: prog/ is the working directory; adamdata/ and tools/ are siblings ---*/
%let tools = ../tools;
libname adamdata "../adamdata";
libname tools    "&tools";
libname libfmt   "&tools";
options fmtsearch = (libfmt work);

%include "&tools/init.inc";

/*------------------------------------------------------------------------------------------*
 | Shared validation-log utility - appends one row per check to the permanent               |
 | TOOLS.VAL_REPORT dataset via PROC APPEND so concurrent/successive table runs never        |
 | clobber each other's rows (Phase 1d requirement).                                         |
 *------------------------------------------------------------------------------------------*/
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

/*------------------------------------------------------------------------------------------*
 | Phase 0 / Phase 1e defensive checks: dataset + required variables must exist before any   |
 | analysis or PDF work is attempted.                                                        |
 *------------------------------------------------------------------------------------------*/
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

%m_req_check(dsname=adsl,
             varlist=subjid usubjid trt01pn scrnfl ittfl saffl pkfl comt01fl
                     dct01rs comsfl dcsreas);

%if &&&statvar._status = ERROR %then %do;
   %put %str(ER)ROR: [USER] &titlekey - one or more required ADSL variables were not found.;
   %put %str(ER)ROR: [USER] &titlekey - PDF generation skipped. See tools/val_report.out.;
   %goto endprogram;
%end;

/*------------------------------------------------------------------------------------------*
 | Data preparation                                                                          |
 *------------------------------------------------------------------------------------------*/
%fetch(library = adamdata,
          data = adsl,
           out = disp0,
       dataopt = where=(scrnfl = 'Y'),
        sortby = subjid);

%nobs(disp0);
%m_val_log(titlekey=&titlekey, dsname=adsl, varname=scrnfl, check=Population record count,
           expected=>0 screened participants, actual=&nobs, status=%sysfunc(ifc(&nobs>0,PASS,ERROR)),
           message=All Screened Participants population count for disposition table.);

%if &nobs = 0 %then %do;
   %let &statvar._status = ERROR;
   %goto endprogram;
%end;

/* de-duplicate to one record per participant (ADSL is already 1 rec/subject, guard anyway) */
proc sort data=disp0 out=disp0 nodupkey;
   by subjid;
run;

/* Formats must be compiled before the DATA step below applies them via FORMAT= */
proc format;
   value total     1 = 'Total';
   value comt01fmt 1 = 'Completed Study Drug'  2 = 'Discontinued Study Drug';
   value comsfmt   1 = 'Completed Study'       2 = 'Prematurely Discontinued Study';
run;

data disp1;
   set disp0;

   /* Screened - every record in this population is screened by definition */
   all_scrn = 1;

   /* ITT/Safety/PK are character Y/N flags in ADSL - recode to 1/missing (never 0) so TABCOUNT
      shows exactly one row (n (%) where flag='Y') instead of separate rows for Y and N. */
   if upcase(ittfl) = 'Y' then ittfln = 1;
   if upcase(saffl) = 'Y' then safffln = 1;
   if upcase(pkfl)  = 'Y' then pkfln = 1;

   /* Study-drug completion status for Period 01 */
   length comt01n 8;
   if      upcase(comt01fl) = 'Y' then comt01n = 1;
   else if upcase(comt01fl) = 'N' then comt01n = 2;

   /* Reason for premature D/C of study drug - only populated when discontinued */
   length dct01cat $40;
   if upcase(comt01fl) = 'N' then do;
      if upcase(dct01rs) = 'ADVERSE EVENT'      then dct01cat = 'Adverse Event';
      else if upcase(dct01rs) = 'LACK OF EFFICACY' then dct01cat = 'Lack of Efficacy';
   end;

   /* Overall study completion status */
   length comsn 8;
   if      upcase(comsfl) = 'Y' then comsn = 1;
   else if upcase(comsfl) = 'N' then comsn = 2;

   /* Reason for premature D/C of study - only populated when discontinued */
   length dcsreascat $40;
   if upcase(comsfl) = 'N' then do;
      if upcase(dcsreas) = 'DEATH'                    then dcsreascat = 'Death';
      else if upcase(dcsreas) = 'WITHDRAWAL BY SUBJECT' then dcsreascat = 'Withdrawal by Subject';
   end;

   format trt01pn trtfmt.
          all_scrn total.
          comt01n comt01fmt.
          comsn   comsfmt.;
   /* All_scrn/ittfln/safffln/pkfln labels are blanked (not descriptive text) so TABCOUNT does
      not emit a separate header row above the n (%) detail row - see the COMBINE post-process
      step below, which supplies the real label text and puts it on the same line as n (%). */
   label all_scrn  = ' '
         ittfln    = ' '
         safffln   = ' '
         pkfln     = ' '
         comt01n   = 'Study Drug Completion Status'
         dct01cat  = 'Reason for Discontinuation of Study Drug'
         comsn     = 'Study Completion Status'
         dcsreascat= 'Reason for Discontinuation of Study';
run;

/*------------------------------------------------------------------------------------------*
 | Report generation - uses global bpgl SP macros directly (fetch/tabdesc/tabcount/tabdcat/  |
 | tabprep/tabdrpt/printset). ocprint=Y adds an overall (Total) column.                      |
 *------------------------------------------------------------------------------------------*/
%tabdesc(data     = disp1,
         ptvar    = subjid,
         colvar   = trt01pn,
         ocprint  = Y,
         col2     = 50,
         statlen  = 3,
         numtitle = Number of &study_subject_text.s);

%tabcount(sortord = 1, var = all_scrn, stat = N, showall = N, ptclabel=%str());
%tabcount(sortord = 2, var = ittfln,   stat = N, showall = N, ptclabel=%str());
%tabcount(sortord = 3, var = safffln,  stat = N, showall = N, ptclabel=%str());
%tabcount(sortord = 4, var = pkfln,    stat = N, showall = N, ptclabel=%str());
%tabdcat (sortord = 5, var = comt01n,  stat = N PCT, showall = Y, nomisspc = Y);
%tabcount(sortord = 6, var = dct01cat, stat = N PCT, showall = N, ptclabel=%str());
%tabdcat (sortord = 7, var = comsn,    stat = N PCT, showall = Y, nomisspc = Y);
%tabcount(sortord = 8, var = dcsreascat, stat = N PCT, showall = N, ptclabel=%str());

/* Put the real row label back on the same line as its n (%) value (TABCOUNT's blanked-label
   detail row otherwise shows only the raw "1" it tabulated), and per the shell, the Screened
   row shows a count only in the Total column (value3) - Drug A/Drug B (value1/value2) are
   blank since every participant in this population is screened by definition. TABPREP indents
   linlabel by LEVEL*3 spaces (via %cntwrap) - TABCOUNT sets LEVEL=1 for these single-variable
   rows, so LEVEL is forced to 0 here to keep the label flush left (no leading spaces). */
data combine;
   set combine;
   length _newlbl $80;
   select (sortord);
      when (1) do; _newlbl = 'Screened'; value1 = ' '; value2 = ' '; end;
      when (2) _newlbl = 'ITT Analysis Set';
      when (3) _newlbl = 'Safety Analysis Set';
      when (4) _newlbl = 'PK Analysis Set';
      otherwise _newlbl = ' ';
   end;
   if _newlbl ne ' ' then do;
      linlabel = left(_newlbl);
      level = 0;
   end;
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

%m_val_log(titlekey=&titlekey, dsname=adsl, varname=, check=PDF generation,
           expected=&outname..pdf created, actual=see log, status=&&&statvar._status,
           message=Disposition table completed - see &outname..log for ODS/PROC PRINTTO confirmation.);

%endprogram:

%put NOTE: [USER] &titlekey final status = &&&statvar._status;

%mend main;

%main;
