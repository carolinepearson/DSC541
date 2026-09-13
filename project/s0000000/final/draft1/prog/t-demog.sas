/* start of header *********************************************************************************
Program Name:      t-demog.sas
Program Author:    GitHub Copilot (copilot)
Program Purpose:   Create Table 15.8.3.1.1 Demographics and Baseline Characteristics, ITT Analysis Set

*********************************************************************************** end of header */

/*----------------------------------------------------------------------------------------------
  METADATA-TO-DATASET MAPPING (Phase 0)
  Source:  DSS TFL Shells_Tables.json Shells[TitleKey=t-demog] Result rows (official source of
           truth for variables/where-clauses/display text); cross-checked against DSS TFL
           Shells.json outputs[id=Out_02] "Demographics and Baseline Characteristics".
  Population:      ITT Analysis Set (ADSL.ITTFL = 'Y')
  Column variable: ADSL.TRT01PN (1=Drug A, 2=Drug B, format TRTFMT.)
  Rows (Label / variable / where-clause / category list, verbatim from the shell JSON):
     1. Count of Subjects by Treatment  -> table header
     2. Age (years)                     -> ADSL.AGE, continuous (n/Mean/SD/Median/Q1,Q3/Min,Max)
     3. Age Group                       -> ADSL.AGEGR1N: 1='< 65 years', 2='>= 65 years'
     4. Sex at Birth                    -> ADSL.SEX: 'M'='Male', 'F'='Female' (exactly 2 categories -
                                           no "Unknown" row is defined in the shell, so none is shown)
     5. Race                            -> ADSL.RACE: exactly 6 categories (AMERICAN INDIAN OR ALASKA
                                           NATIVE, ASIAN, BLACK, NATIVE HAWAIIAN OR PACIFIC ISLANDER,
                                           WHITE, OTHER)
     6. Ethnicity                       -> ADSL.ETHNIC: exactly 2 categories (NOT HISPANIC OR LATINO,
                                           HISPANIC OR LATINO)
     7. Weight (kg)                     -> ADSL.BWT, continuous
     8. Height (cm)                     -> ADSL.BHT, continuous
     9. Body Mass Index (kg/m^2)        -> ADSL.BBMI, continuous

  Sex/Race/Ethnicity are recoded via the shared format catalog informats/formats (FSEXC./
  FSEXN., FRACEC./FRACEN., FETHNICC./FETHNICN.) so the real ADSL controlled-terminology values
  (e.g. RACE='BLACK OR AFRICAN AMERICAN') resolve correctly. SHOWALL=N is used for every
  categorical row (Age Group/Sex/Race/Ethnicity) so a category with zero observed participants
  is never printed as a row unless it actually occurs in the ITT population data.
----------------------------------------------------------------------------------------------*/

options missing='' mprint mlogic=0 symbolgen=0;

%let titlekey = t-demog;
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

%m_req_check(dsname=adsl,
             varlist=subjid usubjid trt01pn ittfl age ageu agegr1n sex race ethnic bwt bht bbmi);

%if &&&statvar._status = ERROR %then %do;
   %put %str(ER)ROR: [USER] &titlekey - one or more required ADSL variables were not found.;
   %put %str(ER)ROR: [USER] &titlekey - PDF generation skipped. See tools/val_report.out.;
   %goto endprogram;
%end;

/*------------------------------------------------------------------------------------------*
 | Data preparation - ITT Analysis Set, one record per participant                          |
 *------------------------------------------------------------------------------------------*/
%fetch(library = adamdata,
          data = adsl,
           out = demog0,
       dataopt = where=(ittfl = 'Y'),
        sortby = subjid);

%nobs(demog0);
%m_val_log(titlekey=&titlekey, dsname=adsl, varname=ittfl, check=Population record count,
           expected=>0 ITT participants, actual=&nobs, status=%sysfunc(ifc(&nobs>0,PASS,ERROR)),
           message=ITT Analysis Set population count for demographics table.);

%if &nobs = 0 %then %do;
   %let &statvar._status = ERROR;
   %goto endprogram;
%end;

proc sort data=demog0 out=demog0 nodupkey;
   by subjid;
run;

data demog1;
   set demog0;

   /* Numeric recodes control display order; use the shared format catalog (not a local format)
      so real ADSL controlled-terminology values (e.g. 'BLACK OR AFRICAN AMERICAN') resolve. */
   racen   = input(upcase(race),   fracec.);
   sexn    = input(upcase(sex),    fsexc.);
   ethnicn = input(upcase(ethnic), fethnicc.);

   if racen   = . then put "WARN" "ING: [USER] Unrecognized RACE value for USUBJID=" usubjid " race=" race;
   if sexn    = . then put "WARN" "ING: [USER] Unrecognized SEX value for USUBJID="  usubjid " sex="  sex;
   if ethnicn = . then put "WARN" "ING: [USER] Unrecognized ETHNIC value for USUBJID=" usubjid " ethnic=" ethnic;

   age_l = 'Age (' || compress(lowcase(ageu)) || ')';
   call symputx('age_l', trim(age_l));

   format trt01pn trtfmt.
          sexn    fsexn.
          racen   fracen.
          ethnicn fethnicn.
          agegr1n agegrfmt.;
   label age      = "Age (Years)"
         sexn     = "Sex at Birth"
         racen    = "Race"
         ethnicn  = "Ethnicity"
         agegr1n  = "Age Group"
         bwt      = "Weight (kg)"
         bht      = "Height (cm)"
         bbmi     = "Body Mass Index (kg/m^2)";
run;

/*------------------------------------------------------------------------------------------*
 | Report generation                                                                        |
 *------------------------------------------------------------------------------------------*/
%tabdesc(data     = demog1,
         ptvar    = subjid,
         colvar   = trt01pn,
         ocprint  = Y,
         col2     = 50,
         statlen  = 3,
         numtitle = Number of &study_subject_text.s);

%tabdcont(sortord = 1, var = age,     meandec=1, sddec=2, meddec=1, qrtdec=1, rangedec=1);
%tabdcat (sortord = 2, var = agegr1n, stat = N PCT, showall = N, nomisspc = Y);
%tabdcat (sortord = 3, var = sexn,    stat = N PCT, showall = N, nomisspc = Y);
%tabdcat (sortord = 4, var = racen,   stat = N PCT, showall = N, nomisspc = Y);
%tabdcat (sortord = 5, var = ethnicn, stat = N PCT, showall = N, nomisspc = Y);
%tabdcont(sortord = 6, var = bwt,     meandec=1, sddec=2, meddec=1, qrtdec=1, rangedec=1);
%tabdcont(sortord = 7, var = bht,     meandec=1, sddec=2, meddec=1, qrtdec=1, rangedec=1);
%tabdcont(sortord = 8, var = bbmi,    meandec=1, sddec=2, meddec=1, qrtdec=1, rangedec=1);

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
           message=Demographics table completed - see &outname..log for ODS/PROC PRINTTO confirmation.);

%endprogram:

%put NOTE: [USER] &titlekey final status = &&&statvar._status;

%mend main;

%main;
