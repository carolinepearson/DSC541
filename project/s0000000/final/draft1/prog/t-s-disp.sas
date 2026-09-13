/* start of header *********************************************************************************
Program Name:      t-s-disp.sas
Program Author:    Caroline Pearson (cpearson1)
Program Purpose:   Create Standard Disposition Table
 
*********************************************************************************** end of header */
 
%macro mk_t_s_disp(          subjid=,
                            statlen=,
                           titlekey=,
                                lib=,
                               dsin=,
                            eff_pop=,
                       where_cl_pop=,
                             tmacro=,
                             colvar=,
                       colvar_saffl=,
                            trt_fmt=,
                        show_scrnfl=,
                      show_scfailfl=,
                      show_notEnrll=,
                      show_notDosed=,
                         show_effFl=,
                      opt_popfl_var=,
                      opt_popfl_lbl=,
                   colvar_opt_popfl=,
                       show_compTrt=,
                       show_dctReas=,
                      show_compStdy=,
                       show_dcsReas=,
                        drug_assign=,
                   drug_comptrt_var=,
                   drug_dctReas_var=,
                          drug_name=,
                     show_drug_zero=,
                   show_comptrt_any=,
                           byPeriod=,
                         num_period=,
                          period_nm=,
                            ocprint=,
                            showAll=,
                          col1Width=,
                             cWidth=,
                            spacing=,
                            spanHdr=,
                           spanRang=,
                            cleanup=);
 
   options missing='';
 
   %let cleanup = %upcase(&cleanup.);
 
   %global combinelist;
   %let combinelist=;
 
   %let done16=;
 
   %if &byPeriod. eq Y and %length(&drug_comptrt_var.) > 0 %then %do;
      %put NOTE: Found byPeriod=<&byPeriod.> and drug_comptrt_var=<&drug_comptrt_var.>.;
      %put NOTE- In STARS v1.4+, you must choose between either by Period or by Drug.;
      %put NOTE- The macro &sysmacroname. will now %sysfunc(compress(a b o r t)).;
 
      data _null_;
        abort abend;
      run;
   %end;
 
   %***************************************************************************;
   %* Count # of optional population vars and labels                          *;
   %***************************************************************************;
   %local m_n_optVar
          m_n_optLbl;
   %let m_n_optVar = 0;
   %let m_n_optLbl = 0;
   %let m_n_optvar = %sysfunc(countW(&opt_popfl_var, ' '));
   %let m_n_optlbl = %sysfunc(countW(&opt_popfl_lbl, '|'));
   %if &m_n_optvar. NE &m_n_optlbl. %then %do;
      %put NOTE: Found <&m_n_optvar.> variables and <&m_n_optlbl.> labels for Optional Populations.;
      %put NOTE- The macro requires a matching set 1-1.;
      %put NOTE- The macro &sysmacroname. will now %sysfunc(compress(a b o r t)).;
 
      data _null_;
        abort abend;
      run;
   %end;
 
   %***************************************************************************;
   %* Provide the default value of <colvar_opt_popfl> as # from above × COLVAR*;
   %***************************************************************************;
   %if %length(&colvar_opt_popfl.) lt 1 %then %do;
      %let colvar_opt_popfl=;
      %do _k = 1 %to &m_n_optVar.;
         %let colvar_opt_popfl= &colvar_opt_popfl. &colvar.;
      %end;
   %end;
 
   %***************************************************************************;
   %* Count # Tx/Rx complete status (four). New STARS v1.4                    *;
   %*    dx_compflv  Tx/Rx Complete status variables   (space)                *;
   %*    dx_fmts     Tx/Rx Complete status var formats (space)                *;
   %*    dx_whyv     Tx/Rx D/con reason variables      (space)                *;
   %*    dx_list     Labels for above                  (pipe |)               *;
   %* n.b. The # of all above *must* match or leave macro                     *;
   %***************************************************************************;
   %local dx_ass dx_compflv dx_fmts dx_whyv dx_list;
   %let dx_ass     = %sysfunc(countw(&drug_assign.,      %str(|)));
   %let dx_compflv = %sysfunc(countw(&drug_comptrt_var., %str( )));
   %let dx_whyv    = %sysfunc(countw(&drug_dctreas_var., %str( )));
   %let dx_list    = %sysfunc(countw(&drug_name.,        %str(|)));
   %let dx_var     = %sysfunc(var(&dx_ass., &dx_compflv., &dx_whyv., &dx_list.));
   %if &dx_var. ne 0 %then %do;
      %put NOTE: The same number of values must be reported in these 4 parameters:;
      %put NOTE- drug_assign (observed &dx_ass.)     |&drug_assign.|.;
      %put NOTE- dx_compflv  (observed &dx_compflv.) |&drug_comptrt_var.|.;
      %put NOTE- dx_whyv     (observed &dx_whyv.) |&drug_dctreas_var.|.;
      %put NOTE- dx_list     (observed &dx_list.) |&drug_name.|.;
      %put NOTE- The macro &sysmacroname. will now %sysfunc(compress(a b o r t)).;
 
      data _null_;
        abort abend;
      run;
   %end;
 
   %***************************************************************************;
   %* 2024-12-18 PDH Feedback and fail if above params provided but only 1    *;
   %*                Study Drug in use.                                       *;
   %***************************************************************************;
   %if &dx_ass. eq 1 and %length(&dx_ass.&dx_compflv.&dx_whyv.&dx_list.) gt 1 %then %do;
      %put NOTE: Please only specify mutiple drug parameters if more than one Study Drug is in use in the analysis.;
      %put NOTE- drug_assign (observed &dx_ass.)     |&drug_assign.|.;
      %put NOTE- dx_compflv  (observed &dx_compflv.) |&drug_comptrt_var.|.;
      %put NOTE- dx_whyv     (observed &dx_whyv.) |&drug_dctreas_var.|.;
      %put NOTE- dx_list     (observed &dx_list.) |&drug_name.|.;
 
      data _null_;
        abort abend;
      run;
   %end;
 
   ****************************************************************************;
   * Formats                                                                  *;
   ****************************************************************************;
   proc format;
      value total
         1 = 'Total';
      value scrnfail
         1 = 'Screen Failed';
      value ayn
         1 = 'Not Dosed';
      value comptrt
         1 = 'Continuing Study Drug'
         2 = 'Completed Study Drug'
         3 = 'Prematurely Discontinued Study Drug';
      value anyDx
         1 = 'Continuing Any Study Drug'
         2 = 'Prematurely Discontinued All Study Drug';
      value $m_poplbl
         'randfl',
         'RANDFL' = 'Randomized'
         'enrlfl',
         'ENRLFL' = 'Enrolled'
         'ittfl',
         'ITTFL' = 'ITT'
         'fasfl',
         'FASFL' = 'Full Analysis Set';
   run;
 
   %***************************************************************************;
   %* Set Parameter Defaults if not Populated                                 *;
   %***************************************************************************;
   %if &colvar_saffl. = %then %do;
      %if %length(&colvar) gt 0 %then %let colvar_saffl = &colvar.;
   %end;
   %if %length(&drug_name.) = 0 %then %do;
      %let drug_name=Study Drug;
   %end;
 
   %***************************************************************************;
   %* Shorten many parameters to first character and upper case               *;
   %***************************************************************************;
   %if %length(&show_scrnfl.) > 0 %then %do;
      %let show_scrnfl = %upcase(%substr(%str(&show_scrnfl), 1, 1));
   %end;
   %if %length(&show_scfailfl.) > 0 %then %do;
      %let show_scfailfl = %upcase(%substr(%str(&show_scfailfl), 1, 1));
   %end;
   %if %length(&show_notenrll.) > 0 %then %do;
      %let    show_notenrll = %upcase(%substr(%str(&show_notenrll), 1, 1));
   %end;
   %if %length(&show_notdosed.) > 0 %then %do;
      %let show_notdosed = %upcase(%substr(%str(&show_notdosed), 1, 1));
   %end;
   %if %length(&show_efffl.) > 0 %then %do;
      %let show_efffl = %upcase(%substr(%str(&show_efffl), 1, 1));
   %end;
   %if %length(&showall.) > 0 %then %do;
      %let showall = %upcase(%substr(%str(&showall), 1, 1));
   %end;
   %if %length(&show_drug_zero.) > 0 %then %do;
      %let show_drug_zero = %upcase(%substr(%str(&show_drug_zero), 1, 1));
   %end;
   %if %length(&show_comptrt.) > 0 %then %do;
      %let show_comptrt = %upcase(%substr(%str(&show_comptrt), 1, 1));
   %end;
   %if %length(&show_dctreas.) > 0 %then %do;
      %let show_dctreas = %upcase(%substr(%str(&show_dctreas), 1, 1));
   %end;
   %if %length(&show_compstdy.) > 0 %then %do;
      %let show_compstdy = %upcase(%substr(%str(&show_compstdy), 1, 1));
   %end;
   %if %length(&show_dcsreas.) > 0 %then %do;
      %let show_dcsreas = %upcase(%substr(%str(&show_dcsreas), 1, 1));
   %end;
/*   %if %length(&show_dctreas.) > 0 %then %do;*/
/*      %let show_dctreas = %upcase(%substr(%str(&show_dctreas), 1, 1));*/
/*   %end;*/
   %if %length(&show_comptrt_any.) > 0 %then %do;
      %let show_comptrt_any = %upcase(%substr(%str(&show_comptrt_any), 1, 1));
   %end;
   %if %length(&byperiod.) > 0 %then %do;
      %let byperiod = %upcase(%substr(%str(&byperiod), 1, 1));
   %end;
 
   %***************************************************************************;
   %* Set output validation dataset and output names                          *;
   %***************************************************************************;
   %let outdsn = vdata.%sysfunc(translate(&titlekey., '_', '-.'));
 
   %if &eff_pop. = %then %do;
      data _null_;
         put "ERR" "OR: [USER] User must define the population used for efficacy analyses to appear in table: EFF_POP";
         abort abend;
      run;
   %end;
 
   %if (&m_n_optLbl. gt 0 and &m_n_optVar. lt 1) or (&m_n_optLbl. le 0 and &m_n_optLbl. ge 1) %then %do;
      data _null_;
         put "ERR" "OR: [USER] User If OPT_POPFL_VAR/OPT_POPFL_LBL is populated";
         put "ERR" "OR- then corresponding OPT_POPFL_LBL/OPT_POPFL_VAR must be populated";
         abort abend;
      run;
   %end;
 
   %if &byperiod. = Y and &num_period. = %then %do;
      data _null_;
         put "ERR" "OR: [USER] User must specify number of periods: NUM_PERIOD in ";
         put "ERR" "OR- study when by treatment: BYPERIOD = Y";
         abort abend;
      run;
   %end;
 
   %if &byperiod. = Y and &num_period. = 1 %then %do;
      data _null_;
         put "USER W" "ARNING: [USER] BYPERIOD = Y, NUM_PERIOD = 1. Table will display as single period study w/o Period labels.";
      run;
   %end;
 
   %if &byperiod. = Y and &num_period. > 1  and %nrbquote(&period_nm.) =  %then %do;
      data _null_;
         put "USER W" "ARNING: [USER] BYPERIOD = Y, NUM_PERIOD = &num_period. but period name description is missing.";
         put "USER W" "ARNING: [USER] Table display will show Period 1, Period 2 etc. for period labels.";
      run;
   %end;
 
   %if &byperiod. ne Y and %length(&num_period)>0 %then %do;
      %if %eval(&num_period.) > 1  %then %do;
         data _null_;
            put "USER W" "ARNING: [USER] BYPERIOD = N or missing but NUM_PERIOD = &num_period. Table will not display by period.";
         run;
      %end;
      %let num_period = 1;
   %end;
   %else %do;
      %let num_period = 1;
   %end;
 
   %if &colvar.  = %then %do;
      data _null_;
          put "ERR" "OR: [USER] User must define the treatment group parameter: COLVAR";
         abort abend;
      run;
   %end;
 
   %if &trt_fmt. =  %then %do;
      data _null_;
         put "ERR" "OR: [USER] Treatment Group format not specified - please enter value for TRT_FMT.";
         abort;
      end;
   %end;
 
   %***************************************************************************;
   %* Quietly get the variable #s for the various population flags.           *;
   %* n.b. ending of {vs} below denotes Variable Number.                      *;
   %***************************************************************************;
   %let dsid = %sysfunc(open(&lib..&dsin.));
   %let   randflvn = %sysfunc(varnum(&dsid, RANDFL));
   %let   cohortvn = %sysfunc(varnum(&dsid, COHORT));
   %let  scrnfflvn = %sysfunc(varnum(&dsid, SCRNFFL));
   %let scrnfailvn = %sysfunc(varnum(&dsid, SCRNFAIL));
   %let rc = %sysfunc(close(&dsid));
 
   %***************************************************************************;
   %* Read in Data and Preprocess                                             *;
   %***************************************************************************;
   %* First with no data selection to get *all* records.                      *;
   %***************************************************************************;
   %fetch(library = &lib.,
             data = &dsin.,
              out = m_scrn);
 
   %if %length(&tmacro.) gt 0 and %upcase(&tmacro.) ne NULL %then %do;
      %&tmacro(data = m_scrn);
   %end;
 
   %let dsid = %sysfunc(open(m_scrn));
   %let scrnfflvn  = %sysfunc(varnum(&dsid, SCRNFFL));
   %let scfailflvn = %sysfunc(varnum(&dsid, SCFAILFL));
   %let rc = %sysfunc(close(&dsid));
 
      proc sql noprint;
         select count(distinct(trt01pn))
                %if &ocprint=Y %then %do;
                   +1
                %end;
                into :totcolall trimmed
         from m_scrn;
      quit;
 
   %if &show_scrnfl.   eq Y or
       &show_scfailfl. eq Y or
       &show_notEnrll. eq Y or
       &show_notDosed. eq Y %then %do;
      %let poplbl = %sysfunc(putC(&eff_pop., $m_poplbl.));
      data m_scrn;
         set m_scrn;
         **********************************************************************;
         * Total Screened Subjects                                            *;
         **********************************************************************;
         all_scrn = 1;
      %if &show_scfailfl. eq Y %then %do;
         %******************************************************************;
         %* Screen Fail Subjects                                           *;
         %******************************************************************;
         %if &scfailflvn ge 1 %then %do;
         if scfailfl eq 'Y' then scrnfail = 1;
         %end;
      %end;
      %if &show_notenrll. = Y %then %do;
         **********************************************************************;
         * Prep for Panel # 3 DCSSREAS                                        *;
         **********************************************************************;
         length crit_notenrl $ 60;
         label dcssreas = "Reason &study_subject_text. Not &poplbl.";
         if (all_scrn eq 1) and
            (dcssreas ne '') then crit_notenrl = "Met All Eligibility Criteria but Not &poplbl.";
      %end;
         format
      %if &scrnfflvn. ge 1 %then %do;
               scrnfl $screen.
      %end;
      %if &scfailflvn. ge 1 and &show_scfailfl. eq Y %then %do;
               scrnfail scrnfail.
      %end;
             all_scrn   total.;
      %if &show_scrnfl eq Y %then %do;
         label scrnfl = ' ';
      %end;
         label all_scrn = 'Screened';
      run;
 
      %************************************************************************;
      %* Original panels at top of Shell. Work off FETCH -> m_scrn, possibly  *;
      %* modified by user written TMACRO.                                     *;
      %************************************************************************;
      %TABDESC(    data = m_scrn,
                 colvar = all_scrn,
                  ptvar = &subjid,
                   col2 = &col1width,
                statlen = &statlen,
                col1hdr = ,
                spacing = &spacing,
                ocprint = &ocprint);
 
      %if &show_scrnfl. eq Y %then %do;
         %*********************************************************************;
         %* OPTIONAL Screen                                                   *;
         %*********************************************************************;
         %TABDCAT(sortord = 1, var = scrnfl, stat = N);
         data combine;
            set combine;
            if (compress(linlabel, ' ') eq 'Y') then linlabel = 'Screened';
         run;
      %end;
      %if &show_scfailfl. = Y %then %do;
         %*********************************************************************;
         %* OPTIONAL Screen Failure                                           *;
         %*********************************************************************;
         %TABDCAT(sortord = 2, var = scrnfail,     stat = N);
      %end;
 
      %if &show_notenrll. = Y %then %do;
         %*********************************************************************;
         %* OPTIONAL Not Enrolled / Why Not?                                  *;
         %*********************************************************************;
         %TABDCAT( sortord = 3, var = crit_notenrl, stat = N);  *OPTIONAL Met Crit not enrolled;
%put NOTE: PDH showall = <&showall.>;
         %TABCOUNT(sortord = 4, var = dcssreas,     stat = N, sortby = F, showall = &showall.);  *OPTIONAL Met Crit not enrolled rsn.;
/*original call*/
/*       %TABDCAT(sortord = 4, var = dcssreas,     stat = N);*/
      %end;
 
      %if &show_scrnfl. = Y or &show_notenrll. = Y %then %do;
         %*********************************************************************;
         %* Move the single VALUE to the right-most column.                   *;
         %* Clear all other columns to the left of right-most.                *;
         %*********************************************************************;
         data combine1;
            set combine;
            value&totcolall. = value1;
            array vls(&totcolall.) value1 - value&totcolall.;
            do i = 1 to (&totcolall. - 1);
               vls(i) = '';
            end;
         run;
      %end;
   %end;
 
   %m_get_s_data(     library = &lib.,
                         data = &dsin.,
                          out = &dsin._1,
                       colvar = &colvar,
                     pop_flag = &eff_pop.,
                 where_cl_pop = &where_cl_pop.,
                    keep_adsl = Usubjid &subjid saffl comsfl dcsreas tr: &colvar &eff_pop.
   %if &byperiod. ne Y %then %do;
                                comt: dct:
   %end;
   %if &randflvn. ge 1 %then %do;
                                randfl
   %end;
   %if &cohortvn. ge 1 %then %do;
                                coh:
   %end;
   %if &show_scrnfl. eq Y or &show_notenrll. eq Y %then %do;
      %if &scrnfflvn. ge 1 %then %do;
                                scrnffl
      %end;
   %end;
   %if &show_scfailfl. eq Y %then %do;
      %if &scfailflvn. ge 1 %then %do;
                                scfailfl
      %end;
   %end;
   %if &show_notenrll. = Y %then %do;
                                dcssreas
   %end;
   %if &m_n_optvar. gt 0 %then %do;
                                &opt_popfl_var.
   %end;
   %if %length(&drug_comptrt_var.) ge 1 %then %do;
                                &drug_comptrt_var.
   %end;
   %if %length(&drug_dctreas_var.) ge 1 %then %do;
                                &drug_dctreas_var.
   %end;
   %if &byperiod. eq Y %then %do;
      %do _i = 1 %to &num_period.;
                                comt0&_i.fl
                                dct0&_i.rs
      %end;
   %end;
                     , Xmacro = &tmacro);
 
   data &dsin._1;
      set &dsin._1;
      where (&colvar ne .);
   run;
   %let dsid = %sysfunc(open(&dsin._1));
   %let scfailflvn = %sysfunc(varnum(&dsid, SCFAILFL));
   %let rc = %sysfunc(close(&dsid));
 
   %NOBS(&dsin._1);
   %if &nobs > 0 %then %do;
      %************************************************************************;
      %* Determine total number of columns including "Total" column to adjust *;
      %* display options later on.                                            *;
      %************************************************************************;
      proc sql noprint;
         select count(distinct(&colvar.))
                %if &ocprint=Y %then %do;
                   +1
                %end;
                into: totcol trimmed
         from &dsin._1;
      quit;
 
      %************************************************************************;
      %* Create display labels for each period if needed                      *;
      %************************************************************************;
      %if &byperiod. = Y and &num_period. ne %then %do;
         %if %nrbquote(&period_nm.) = %then %do;
            %do _i = 1 %to &num_period.;
               %GLOBAL per&_i.lbl;
               %let per&_i.lbl = Period 0&_i.;
               %put Period &_i. Label = &&per&_i.lbl.;
            %end;
         %end;
         %else %do;
            %******************************************************************;
            %* Scan and parse out each label to store as macro vars           *;
            %******************************************************************;
            %do _i = 1 %to &num_period.;
               %GLOBAL per&_i.lbl;
               %let per&_i.lbl = %qscan(%nrbquote(&period_nm.), &_i., |);
               %put Period &_i. Label = &&per&_i.lbl.;
            %end;
         %end;
         %let _i = ;
      %end;
 
      %************************************************************************;
      %* Determine if COMSFL or COMSxxFL vars should be used                  *;
      %* COMSxxFL will be used if captured on CRF                             *;
      %* COMSFL = Study Completion Flag (overall)                             *;
      %************************************************************************;
      %macro comsxxfl;
         %global use_comsxxfl;
         %if (&byperiod. = Y) and (&num_period. ne ) and (&show_compstdy. = Y or &show_compstdy. = O) %then %do;
            %local rc dsid;
            %let dsid = %sysfunc(open(&dsin._1));
 
            %if &dsid. and %sysfunc(varnum(&dsid., coms0&num_period.fl)) %then %do;
               %let use_comsxxfl = Y;
               %let rc = %sysfunc(close(&dsid.));
               %return;
            %end;
            %else %do;
               data _null_;
                  put "USER N" "OTE: [USER] By period study completion vars COMSxxFL do not exist. COMSFL will be used.";
               run;
               %let use_comsxxfl = N;
               %let rc = %sysfunc(close(&dsid.));
            %end;
         %end;
         %else %let use_comsxxfl = N;
      %mend comsxxfl;
      %comsxxfl;
 
      %************************************************************************;
      %* Determine if any subject discont. trt or study for display category  *;
      %* purposes based on TFL standards                                      *;
      %************************************************************************;
      %macro num_disc(var = );
         %global n_&var.;
 
         proc sql noprint;
            select count(&var) into: n_&var. trimmed
               from &dsin._1
                  where &var. = 'N';
         quit;
      %mend num_disc;
 
      %num_disc(var = comsfl);     *Disc. overall study;
 
      %if &byperiod. = Y and &num_period. ge 1 %then %do;
         %************************************************************************;
         %* New in v1.4, only perform below if reporting by Period, not if       *;
         %* reporting just Overall, or if reporting by Study Drug.               *;
         %************************************************************************;
 
         %do _i = 1 %to &num_period.; *Disc trt and study by period counts if applicable;
            %*********************************************************************;
            %* ADaM IG v1.1 Mapping Spec: Study Drug Completion Flag Period XX   *;
            %*********************************************************************;
            %NUM_DISC(var = comt0&_i.fl);
            %*********************************************************************;
            %* ADaM IG v1.1 Mapping Spec: Study Completion Flag for Period XX    *;
            %*********************************************************************;
            %if &use_comsxxfl. = Y %then %NUM_DISC(var = coms0&_i.fl);
         %end;
         %let _i = ;
      %end;
 
      %************************************************************************;
      %* Determine if Enrolled or Randomized should be used in table labels   *;
      %* n.b. Original code before format for this was added.                 *;
      %************************************************************************;
      %let dsid = %sysfunc(open(&dsin._1));
      %if       &eff_pop. = randfl %then %let poplbl = Randomized;
      %else %if &eff_pop. = enrlfl %then %let poplbl = Enrolled;
      %else %if &eff_pop. = ittfl  %then %let poplbl = ITT;
      %else %if &eff_pop. = fasfl  %then %let poplbl = Full Analysis Set;
      %else %do;
         %if       &dsid. and %sysfunc(varnum(&dsid., randfl)) %then %let poplbl = Randomized;
         %else %if &dsid. and %sysfunc(varnum(&dsid., enrlfl)) %then %let poplbl = Enrolled;
         %else %if &dsid. and %sysfunc(varnum(&dsid., ittfl))  %then %let poplbl = ITT;
         %else %if &dsid. and %sysfunc(varnum(&dsid., fasfl))  %then %let poplbl = Full Analysis Set;
      %end;
      %let dsid = %sysfunc(close(&dsid.));
 
    ***************************************************************************;
    * Get EFF Population of Interest - RAND, ITT, PPROT ENRL etc.             *;
    * Process for Panel # 4                                                   *;
    ***************************************************************************;
 
   %***************************************************************************;
   %* Check quietly to see if NDOSFL exists in WORK &dsin._1                  *;
   %* Might be native in ADSL or might be added by TMACRO code.               *;
   %***************************************************************************;
   %local ndosflvn;
   %let dsid = %sysfunc(open(&dsin._1));
   %let ndosflvn = %sysfunc(varnum(&dsid, NDOSFL));
   %let rc = %sysfunc(close(&dsid));
 
    data &eff_pop.;
      set &dsin._1;
      where (&eff_pop. eq 'Y');
      if (trt01pn ne .) and (trt01an eq .)
   %if &ndosflvn. ge 1 %then %do;
         and (ndosfl eq 'Y')
   %end;
             then not_dosed = 1;
      format
        &colvar. &trt_fmt..
        &eff_pop. $&eff_pop..
        not_dosed ayn.;
      label &eff_pop = ' ';
    run;
 
   %TABDESC(    data = &eff_pop.,
              colvar = &colvar.,
               ptvar = &subjid,
                col2 = &col1width,
             statlen = &statlen,
             col1hdr = ,
             spacing = &spacing,
             ocprint = &ocprint);
 
   %TABDCAT(sortord = 5, var = &eff_pop., stat = N, nomisspc = N); *OPTIONAL Rand/Enrl/ITT/FASFL pop;
 
   %if &show_notdosed. = Y %then %do;
      %TABDCAT(sortord = 6, var = not_dosed, stat = N, nomisspc = N);  *OPTIONAL Rand/Enrl/ITT/FASFL but not dosed;
   %end;
 
   data combine2;
      set combine;
      if sortord eq 6 then linlabel = strip("All &poplbl.") || ' but Never Dosed';
   run;
 
      *************************************************************************;
      * Process OPT_POPFL Population(s)                                       *;
      *************************************************************************;
      %local so         /* Sort Order                                         */
             m_opti     /* Loop counter over # Optional Pop Flags             */
             m_thisvar  /* This Optional Variable                             */
             m_thislbl  /* This Optional Label                                */
             m_thisflg; /* This optional Flag variable                        */
      %if &opt_popfl_var. ne %then %do;
         %let so=7;
         %do m_opti = 1 %to &m_n_optVar.;
            %let so = %eval(&so + 1);
            %let m_thisvar = %scan(&opt_popfl_var.,    &m_opti., %str( ));
            %let m_thislbl = %scan(&opt_popfl_lbl.,    &m_opti., %str(|));
            %let m_thisflg = %scan(&colvar_opt_popfl., &m_opti., %str( ));
 
            data &m_thisvar.;
               set &dsin._1;
               by &subjid.;
               where &m_thisvar. eq 'Y';
               format &m_thisflg. &trt_fmt.. ;
               label &m_thisvar. = ' ';
            run;
 
            %TABDESC(    data = &m_thisvar.,
                       colvar = &m_thisflg.,
                        ptvar = &subjid,
                         col2 = &col1width,
                      statlen = &statlen,
                      col1hdr = ,
                      spacing = &spacing,
                      ocprint = &ocprint);
 
           %TABDCAT(sortord = &so, var = &m_thisvar., stat = N); *OPTIONAL population display;
 
            data opt_combine&m_opti.;
               set combine;
               if "&opt_popfl_lbl." ne "" then linlabel = left("&m_thislbl.");
            run;
         %end;
      %end;
 
      %if &opt_popfl_var. ne %then %do;
         data opt_combine;
            set opt_combine:;
         run;
      %end;
 
      *************************************************************************;
      * Process Safety Population Vars                                        *;
      *************************************************************************;
      data safety1(where = (N(&colvar.)      ge 1))
           safety2(where = (N(&colvar_saffl) ge 1));
         set &dsin._1(where = (&eff_pop eq 'Y'));
         by &subjid;
         label
                     saffl = ' '
                  &colvar. = ' '
            &colvar_saffl. = ' ';
         format
            &colvar.         &trt_fmt..
            &colvar_saffl.   &trt_fmt..
                    saffl    $saffl.
                 comsfl_n  compstud.;
      %if &show_comptrt. ne N and &dx_ass. eq 1 %then %do;
         format comt01n comptrt.;
      %end;
      %else %do;
         call missing(comt01n); %* Only in one-drug studies                   *;
      %end;
      *************************************************************************;
      * Counts of all subjects in each period                                 *;
      *************************************************************************;
      %if &byperiod. = Y %then %do;
         %do _i = 1 %to &num_period.;
           length allper0&_i. $ 150;
           allper0&_i. = "&&per&_i.lbl Treatment Period";
         %end;
      %end;
      %let _i = ;
      %************************************************************************;
      %* Drug or Treatment Completion - All studies will have the             *;
      %* by period trt status vars                                            *;
      %* STARS v1.4 The above is a bad assumption. Some studies do not have   *;
      %*            the idea of PERIOD baked in. Sometimes this macro will    *;
      %*            break down by individual Study Durgs not time / Period.   *;
      %************************************************************************;
      %if &byperiod = Y %then %do;
         %do _j = 1 %to &num_period.;
            if (comt0&_j.fl eq '' or comt0&_j.fl eq 'N') and
               (dct0&_j.rs eq '')                          then comt0&_j.n = 1; * Continuing               for period _j;
            if (comt0&_j.fl eq 'Y')                        then comt0&_j.n = 2; * Completed                for period _j;
            if (comt0&_j.fl eq '' or comt0&_j.fl = 'N') and
               dct0&_j.rs ne ''                            then comt0&_j.n = 3; * Prematurely Discontinued for period _j;
            format comt0&_j.n comptrt.;
            label comt0&_j.n = 'Study Drug Completion Status';
            label dct0&_j.rs = 'Reason for Premature Discontinuation of Study Drug';
         %end;
      %end;
      %else %if &dx_ass. gt 1 %then %do;
         %*********************************************************************;
         %* Not By Period, multiple Study Drugs                               *;
         %*********************************************************************;
      %end;
      %else %do;
         %*********************************************************************;
         %* Not By Period, only 1 Study Drug                                  *;
         %*********************************************************************;
            if (comt01fl eq '' or comt01fl eq 'N') and
               (dct01rs eq '')                          then comt01n = 1; * Continuing               for period _j;
            if (comt01fl eq 'Y')                        then comt01n = 2; * Completed                for period _j;
            if (comt01fl eq '' or comt01fl = 'N') and
               dct01rs ne ''                            then comt01n = 3; * Prematurely Discontinued for period _j;
            format comt01n comptrt.;
            label comt01n = 'Study Drug Completion Status';
            label dct01rs = 'Reason for Premature Discontinuation of Study Drug';
      %end;
      %let _j = ;
         **********************************************************************;
         * Study Completion - All studies will have overall study vars        *;
         **********************************************************************;
         if (comsfl eq '') and (dcsreas eq '') then comsfl_n = 1; * Continuing;
         if (comsfl eq 'Y')                    then comsfl_n = 2; * Completed;
         if (comsfl eq 'N') or
            (comsfl = '' and dcsreas ne '')    then comsfl_n = 3; * Discontinued;
         label
            comsfl_n = 'Study Completion Status'
             dcsreas = 'Reason for Premature Discontinuation of Study';
      %if &byperiod. = Y and &use_comsxxfl. = Y %then %do;
         **********************************************************************;
         * Break out study completion by period if available                  *;
         **********************************************************************;
         %do _k = 1 %to %eval(&num_period.);
          if (coms0&_k.fl eq '') and (dcs0&_k.rs eq '') then coms0&_k.n = 1; * Continuing for period _k;
          if (coms0&_k.fl eq 'Y')                       then coms0&_k.n = 2; * Completed for period _k;
          if (coms0&_k.fl eq 'N') or
             (coms0&_k.fl = '' and dcs0&_k.rs ne '')    then coms0&_k.n = 3;
          format coms0&_k.n compstud.;
          label coms0&_k.n = 'Study Completion Status';
          label dcs0&_k.rs = 'Reason for Premature Discontinuation of Study';
         %end;
         %let _k = ;
      %end;
      run;
 
      %TABDESC(    data = safety2,
                 colvar = &colvar_saffl,
                  ptvar = &subjid,
                   col2 = &col1width,
                statlen = &statlen,
                col1hdr = ,
                spacing = &spacing,
                ocprint = &ocprint);
      %TABDCAT(sortord = 7, var = saffl, stat = N);
      data combine7;
         set combine;
         where (start eq 'Y');
      run;
 
      %************************************************************************;
      %* Restore COLVAR to <& COLVAR> as COLVAR_SAFFL is only used for SAFFL  *;
      %* Also change data set pointer to <eff_pop>.                           *;
      %************************************************************************;
      %TABDESC(    data = safety1,
                 colvar = &colvar,
                  ptvar = &subjid,
                   col2 = &col1width,
                statlen = &statlen,
                col1hdr = ,
                spacing = &spacing,
                ocprint = &ocprint);
 
      *************************************************************************;
      * Multiple trt period variables and by period study status variables    *;
      *************************************************************************;
      %do _z = 1 %to &num_period.;
         %if &byperiod. = Y and &num_period. ne 1 %then %do;
            %TABDCAT(sortord = %eval(10+5*&_z.), var = allper0&_z., showall = &showall.); *OPTIONAL Num. of subjects in period;
         %end;
 
         %if &show_comptrt. = Y or &show_comptrt. = O %then %do;
            %TABDCAT(sortord = %eval(11+5*&_z.), var = comt0&_z.n, showall = &showall.);  *OPTIONAL Period x Trt status;
            %let done16 = Y;
            %if &show_comptrt. = O %then %do;
            %******************************************************************;
            %* Oncology TA can request that row Completed SD is removed by    *;
            %* setting <show_comptrt> to <O>.                                 *;
            %******************************************************************;
               data combine;
                  set combine;
                  if (linlabel eq 'Completed Study Drug') then delete;
               run;
            %end;
         %end;
         %*********************************************************************;
         %* Only display if subjects discontinued Tx per standard             *;
         %* TFL shell instructions                                            *;
         %*********************************************************************;
         %if &byPeriod. eq Y %then %do;
            %if &show_dctreas. = Y and %eval(&&n_comt0&_z.fl.) ge 1 %then %do;
               %TABCOUNT(sortord = %eval(12+5*&_z.), var = dct0&_z.rs, showall = &showall., sortby = F);
            %end;
         %end;
         %else %if &byperiod. eq N and &dx_compflv. le 1 and &show_dctreas. eq Y %then %do;
               %TABCOUNT(sortord = 19, var = dct01rs, showall = &show_drug_zero., sortby = F);
               %***************************************************************;
               %* indent Reason for Premature Discont of Study Drug           *;
               %***************************************************************;
               data combine;
                  set combine;
                  if (sortord eq 19) then linlabel = '   ' || strip(linlabel);
               run;
         %end;
         **********************************************************************;
         * Study discontinuation vars                                         *;
         **********************************************************************;
         %if &num_period. > 1 and &use_comsxxfl. = Y %then %do;
            %if &show_compstdy. = Y or &show_compstdy. = O %then %do;
               %TABDCAT(sortord = %eval(13+5*&_z.), var = coms0&_z.n, showall = &showall.);
            %end;
            *******************************************************************;
            * Only display if subjects discontinued study per standard        *;
            * TFL shell instructions                                          *;
            *******************************************************************;
            %if &show_dcsreas. = Y and &use_comsxxfl. = Y and %eval(&&n_coms0&_z.fl.) ge 1 %then %do;
               %TABCOUNT(sortord = %eval(14+5*&_z.), var = dcs0&_z.rs, showall = &showall., sortby = F);
            %end;
         %end;
      %end;
 
      %if &show_comptrt. eq Y and &byperiod. ne Y and &done16. ne Y %then %do;
         %*********************************************************************;
         %* If no ByPeriod chosen                                             *;
         %*********************************************************************;
         %TABDCAT(sortord =  16, var = comt01n, showall = &showall.);
      %end;
 
      %let _z = ;
      *************************************************************************;
      * Study discon Status                                                   *;
      *************************************************************************;
      %if (&show_compstdy. = Y or &show_compstdy. = O) and &num_period. = 1 %then %do; *Single period study uses COMSFL and corresponding reasons;
         %TABDCAT(sortord = 150, var = comsfl_n, showall = &showall.); *OPTIONAL Overall study discont.;
      %end;
      %************************************************************************;
      %* Only display if subjects discontinued study per standard TFL         *;
      %* shell instructions                                                   *;
      %************************************************************************;
      %if &show_dcsreas. = Y and &num_period. = 1 and %eval(&n_comsfl.) ge 1 %then %do;
         %TABCOUNT(sortord = 151, var = dcsreas, showall = &showall., sortby = F); *OPTIONAL Overall study discont. rsn;
      %end;
 
      data combine3;
         set combine;
      run;
 
      %************************************************************************;
      %* New section in v1.4:                                                 *;
      %*   Derive 2 new fields, optional depending on <SHOW_COMPTRT_ANY>      *;
      %*      CASD = Continuing Any Study Drug:1+ of vars in drug_comptrt_var *;
      %*             are set to missing                                       *;
      %*     PDASD = All vars listed in drug_comptrt_var  are missing         *;
      %************************************************************************;
      %if &show_comptrt_any. = Y %then %do;
         proc sql noprint;
            select max(&colvar.) into :numaray trimmed
               from &dsin._1;
         quit;
 
   %macro bldaray(n);
      %************************************************************************;
      %* Utility macro to generate two sets of <n> array statements. <n> is # *;
      %* of values <COLVAR> takes on.                                         *;
      %* The first set of arrays is for What Happened, using the set of Drug  *;
      %* completion flag vars provided in <drug_comptrt_var>.                 *;
      %*                                                                      *;
      %* The second set of arrays for the Reason variables provided in        *;
      %* <drug_dctreas_var>. The D/CON ALL SD needs to look at these vars.    *;
      %************************************************************************;
      %local _a _d thispat thisvar thiswhy;
 
      %do _a = 1 %to &numaray.;
          array drg_f&_a. {*}
         %do _d = 1 %to &dx_ass.;
            %let thispat = %scan(&drug_assign.,      &_d.);
            %let thisvar = %scan(&drug_comptrt_var., &_d.);
            %if %sysfunc(find(&thispat., &_a.)) %then &thisvar.;
         %end;
          ;
          array drg_r&_a. {*}
         %do _d = 1 %to &dx_ass.;
            %let thispat = %scan(&drug_assign.,      &_d.);
            %let thiswhy = %scan(&drug_dctreas_var., &_d.);
            %if %sysfunc(find(&thispat., &_a.)) %then &thiswhy.;
         %end;
         ;
      %end;
   %mend bldaray;
 
page;
         data m_comptrt;
            set &dsin._1;
            where (&eff_pop. eq 'Y');
         %*********************************************************************;
         %* Dynamically build <n> ARRAY statements, one for each level of     *;
         %* <ColVar>. Each one contains the appropriate variables in          *;
         %* <DRUG_COMPTRT_VAR>. The pattern of numbers in <DRUG_ASSIGN> will  *;
         %* determine what is appropriate for each array.                     *;
         %*********************************************************************;
         %bldaray(&numaray.);
            attrib CASD       /*       label = 'Continuing Any Study Drug';   */
              length = 8
              format = anyDx.
               label = '';
            attrib PDASD
              length = 8
              format = anyDx.
               label = '';/*label = 'Prematurely Discontinued All Study Drug';*/
            casd_n = 0;
            pdasd_n = 0;
      %do _a = 1 %to &numaray.;
         %*********************************************************************;
         %* For each value of <COLVAR>, there is a distinct array of FL vars  *;
         %* and of RS vars. Rules for assigning outcomes:                     *;
         %*    For CASD if 1+ FL var is missing, and the corresponding RS var *;
         %*    is not, then count it.                                         *;
         %*    For PDASD if all (in that array) FL vars are {N}, and the      *;
         %*    corresponding RS var is not missing, then count it.            *;
         %*********************************************************************;
            if &colvar. eq &_a. then do;
               do _a = 1 to dim(drg_f&_a.);
                  if drg_f&_a.{_a} eq ' '   and
                     drg_R&_a.(_a) eq ''  then casd_n  + 1;
                  if drg_f&_a.(_a) eq 'N'   and
                     drg_R&_a.(_a) ne ''  then pdasd_n + 1;
               %***************************************************************;
               %* At the end of the loop on Data step var [_a], use the temp  *;
               %* vars [CASD_N PDSAD_N] to derive the final vars {CASD PDSAD].*;
               %***************************************************************;
                  if (_a eq dim(drg_f&_a.)) then do;
                     if casd_n  gt             0  then  casd = 1;
                     else                               casd = 0;
                     if pdasd_n eq dim(drg_f&_a.) then pdasd = 2;
                     else                              pdasd = 0;
                  end;
               end;
            end;
      %end;
            drop _a casd_n pdasd_n;
         run;
 
         %TABDESC(    data = m_comptrt,
                    colvar = &colvar.,
                     ptvar = &subjid,
                      col2 = &col1width,
                   statlen = &statlen,
                   col1hdr = ,
                   spacing = &spacing,
                   ocprint = &ocprint);
 
      %if &show_comptrt_any. = Y %then %do;
         %TABDCAT(sortord =  18, var =  casd, stat = N pct, showall = &showall.);
 
         data combinec;
           set combine;
           if (left(linlabel) =: '0') then delete;
         run;
 
         data combine;
            if (0) then set combine;
         run;
         %TABDCAT(sortord =  19, var = pdasd, stat = N pct, showall = &showall.);
 
         data combined;
           set combine;
           statord = tranwrd(statord, '2', '1');
           %*******************************************************************;
           %* Remove extra rows                                               *;
           %*******************************************************************;
           if (left(linlabel) =: '0') then delete;
         run;
         %end;
      %end;
 
      %************************************************************************;
      %* New in v1.4:                                                         *;
      %* If <drug_comptrt_var> is not blank (or dx_compflv > 0)               *;
      %* Provide 1 or 2 panels for each drug listed:                          *;
      %*         What is the outcome (2 or 3 rows)?                           *;
      %*         Why did the d/cons occur? (# rows data driven)               *;
      %* n.b. The creation of the panels is independent of one another.       *;
      %************************************************************************;
      %if &dx_compflv. ge 1 and &show_comptrt. ne N %then %do;
         %do _dx = 1 %to &dx_compflv.;
            %let thischrt = %scan(&drug_assign.,      &_dx., |);
            %let thisflag = %scan(&drug_comptrt_var., &_dx.);
            %let thiswhy  = %scan(&drug_dctreas_var., &_dx.);
            %let thislbl  = %scan(&drug_name.,        &_dx., |);
 
            proc format;
              value thistx
                1 = "&thislbl. Completion Status";
            run;
 
            data m_drug&_dx.;
              set &dsin._1;
              if (_N_ eq 1) then compstrng = "&thischrt.";
            if (&dx_compflv. gt 1) then do;
              if (find(compstrng, put(&colvar., 1.)));
            end;
              if (&thisflag. eq '') and (&thiswhy. eq '') then comsfl_n = 1; %* Continuing;
              if (&thisflag. eq 'Y')                      then comsfl_n = 2; %* Completed;
              if (&thisflag. eq 'N') or
                 (&thisflag. eq '' and &thiswhy. ne '')   then comsfl_n = 3; %* Discontinued;
              thistx = 1;
              retain compstrng;
              format
                 comsfl_n comptrt.
                   thistx thistx.;
              label
                 &colvar. = "&thislbl. Completion Status"
                 comsfl_n = "&thislbl. Completion Status";
            run;
 
            %nobs(m_drug&_dx.);
            %if &nobs gt 0 %then %do;
               %TABDESC(    data = m_drug&_dx.,
                          colvar = &colvar.,
                           ptvar = &subjid.,
                            col2 = &col1width.,
                         statlen = &statlen.,
                         col1hdr = ,
                      showAllCol = Y
                         spacing = &spacing.,
                         ocprint = &ocprint.);
 
               %TABDCAT(sortord = %eval(20 + (&_dx. * 2)), var = comsfl_n, stat = N pct, nomisspc=N);
 
            %if &_dx eq 1 %then %do;
            %******************************************************************;
            %* First time around build an empty (no-data) dataset with the    *;
            %* correct metadata structure (PDV).                              *;
            %******************************************************************;
            data combineDx;
               if (0) then set combine;
               stop;
            run;
            %end;
 
            data combineDx;
               update
                  combineDx
                  combine;
               by sortord start;
            run;
            %end;
         %end;
         %let _dx=;
      %end; %* End of processing multi-drugs for What                         *;
 
      %if &dx_compflv. ge 1 and &show_dcsreas. ne N %then %do;
         %*********************************************************************;
         %* Now repeat for the why panels (reason)                            *;
         %*********************************************************************;
         %do _dx = 1 %to &dx_compflv.;
            %let thisflag = %scan(&drug_comptrt_var., &_dx.);
            %let thiswhy  = %scan(&drug_dctreas_var., &_dx.);
            %let thislbl  = %scan(&drug_name.,        &_dx., |);
 
            proc format;
              value thistx
                1 = "Reason for Premature Discontinuation of &thislbl.";
            run;
 
            data m_drugwhy&_dx.;
              set &dsin._1;
              thiswhy = 1;
              format
                thiswhy thistx.;
              label
                 &colvar. = "&thislbl. Completion Status";
            run;
 
            %nobs(m_drugwhy&_dx.);
            %if &nobs gt 0 %then %do;
 
               %TABDESC(    data = m_drugwhy&_dx.,
                          colvar = &colvar.,
                           ptvar = &subjid.,
                            col2 = &col1width.,
                         statlen = &statlen.,
                         col1hdr = ,
                      showAllCol = Y
                         spacing = &spacing.,
                         ocprint = &ocprint.);
 
               %TABCOUNT(sortord = %eval(21 + (&_dx. * 2)), var = &thiswhy., stat = N pct, sortby = F, showall = &showall.);
            %if &_dx eq 1 %then %do;
            %******************************************************************;
            %* First time around build an empty (no-data) dataset with the    *;
            %* correct metadata structure (PDV).                              *;
            %******************************************************************;
            data combineWhy;
               if (0) then set combine;
               stop;
            run;
            %end;
            data combineWhy;
               update
                  combineWhy
                  combine;
               by sortord start;
            run;
            %end;
         %end;
         %let _dx=;
      %end; %* End of processing multi-drugs for Why                          *;
 
      *************************************************************************;
      * Combine all datasets together                                         *;
      * Take care around the Dx and Why datasets, they may not exist for a    *;
      * particular macro run.                                                 *;
      *************************************************************************;
      data combine(label = "Combine all datasets");
         set
      %if &show_scrnfl. = Y or &show_notenrll. = Y %then %do;
             combine1
      %end;
             combine2
             combine7
      %if &opt_popfl_var. ne %then %do;
             opt_combine
      %end;
      %if &show_comptrt. ne N and &dx_ass. gt 1 %then %do;
             combineDx
      %end;
      %if &show_dcsreas. ne N and &dx_ass. gt 1 %then %do;
             combineWhy
      %end;
      %if %sysfunc(exist(combinec)) %then %do;
             combinec
      %end;
      %if %sysfunc(exist(combined)) %then %do;
             combined
      %end;
             combine3(in = C3);
         num_period = symgetn("num_period");
         **********************************************************************;
         * Delete eff_pop if not selected by user to appear                   *;
         **********************************************************************;
      %if &show_efffl. ne Y %then %do;
         if sortord eq 5 then delete;
      %end;
         if (C3) and find(%upcase("&opt_popfl_var."), 'SAFFL') then do;
            if sortord eq 7 then delete;
         end;
         %*********************************************************************;
         %* Dynamically parse default label from lines that used              *;
         %* %TABCOUNT to appear correctly                                     *;
         %*********************************************************************;
         %* Modify to only take SUBSTR if <Reason for> is present             *;
         %*********************************************************************;
         if indexW(label1, "Number Of &study_subject_text.s With Event, Per ") > 0 then do;
/*            label1 = substr(label1, indexW(label1, 'Reason for '));*/
            x = index(label1, 'Per ') + 4;
            if (x gt 0) then label1 = substr(label1, x);
         end;
         drop x;
      run;
 
      proc sort data = combine;
         by sortord;
      run;
 
      data combine;
         set combine;
         by sortord;
      %if &byperiod. = Y %then %do;
         **********************************************************************;
         * If byperiod then indent sub-period sections further build in here  *;
         * so tabprep does appropriate indentation for spill over lines       *;
         **********************************************************************;
         if num_period > 1 then do;
            do _z = 1 to num_period;
               if (5*_z + 11) <= sortord <= (5*_z + 14) then linlabel = '   ' ||
                                                                        (linlabel);
            end;
         end;
         drop _z;
      %end;
      %if &show_comptrt. = O %then %do;
         if (linlabel eq 'Completed Study Drug') then delete;
      %end;
      run;
 
      %let dctn=;
      proc sql noprint;
         select distinct sortord into :dctn separated by ','
            from combine
               where (linlabel like 'Reason for Discontinuation of%');
      quit;
 
      data combine;
         set combine;
         linlabel2 = linlabel;
         array vls {&totcolall.} value1 - value&totcolall.;
         if indexW(linlabel, 'Population Flag') > 1 then delete;
         if upcase(linlabel) = "NUMBER OF %upcase(&study_subject_text.)S" then delete;
         **********************************************************************;
         * If requested to remove middle row of Drug Tx panel                 *;
         **********************************************************************;
         if ("&show_comptrt." eq 'O')                   and
            (left(linlabel2) =: 'Completed Study Drug') and
            (left(label1) eq 'Study Completion Status') then delete;
      %if &show_comptrt_any. eq Y %then %do;
         if (sortord in (18, 19)) then do;
            *******************************************************************;
            * For Any drug and All drug d/cons, collapse into one line        *;
            *******************************************************************;
           call missing(label1);
           if (catx('', of value1 - value&totcolall.)) eq '' then delete;
         end;
         retain linlabel2;
      %end;
      %if &show_dctreas ne Y and %length(&dctn.) ge 1 %then %do;
         if (sortord in (&dctn.)) then delete;
      %end;
         if (find(linlabel, 'Completed Study Drug')) then do;
            *******************************************************************;
            * If Oncology flag set, then delete middle row of panel for       *;
            * Completing Study Drug                                           *;
            *******************************************************************;
            if ("&show_comptrt." eq "O") then delete;
         end;
      run;
 
      proc sort data = combine;
         by sortord statord;
      run;
 
      data combine;
         set combine;
         by sortord statord;
         array vls {&totcolall.} value1 - value&totcolall.;
         valdim = dim(vls) - 1;
      if "&show_compstdy." eq 'O' then do;
         %***************************************************************;
         %* User request to supress <Completed Study> row.              *;
         %***************************************************************;
         if (find(label1, 'Study Completion Status')) then do;
            if (find(linlabel, 'Completed Study')) then delete;
         end;
      end;
      if (linlabel eq 'Prematurely Discontinued All Study Drug') and
         (sortord eq 19) then sortord = sortord - 1;
      run;
 
      *************************************************************************;
      * Prepare table for output                                              *;
      *************************************************************************;
      %************************************************************************;
      %* Code from Kim to address issue with using <TABCOUNT> instead of      *;
      %* <TABDCAT>, supporing use of SORTBY parameter                         *;
      %************************************************************************;
         %if &show_notenrll=Y and &_ptclevl=0 %then %do;
            %let _ptclevl=1;
            %let _ptcvars=dcssreas;
         %end;
 
      %tabprep(titlekey = &titlekey,
                outname = &titlekey,
                headtot = N,
                spanhdr = &spanhdr,
               spanrang = &spanrang);
 
      proc sort data = summary;
         by sortord;
      run;
 
      data summary;
         set summary;
         by sortord;
         if (sortord in (18)) then linlabel = left(linlabel);
         array vls {&totcolall.} value1 - value&totcolall.;
         linlabel2 = linlabel;
         if upcase(linlabel) = "NUMBER OF %upcase(&study_subject_text.)S" then delete;
         if (statord eq ' ') then linlabel2 = linlabel;
         linlabel = linlabel2;
         retain linlabel2;
      %if &show_drug_zero. eq N and &dx_ass. gt 1 and &showall. ne Y %then %do;
         if (find(linlabel2, 'Completion Status') gt 0) then do;
            if (compress(value&totcolall., ' ') eq '0') then do;
               do j = 1 to (&totcolall. - 1); /* else */
                  call missing(vls{j});
               end;
            end;
         end;
         drop j;
      %end;
         if first.sortord then do;
            linlabel = left(linlabel);
            if last.sortord then do;
               if index(linlabel, '~') then linlabel = strip(compbl(linlabel));
            end;
         end;
      %if &num_period gt 1 %then %do;
         do _z = 1 to num_period;
            if (5*_z + 11) <= sortord <= (5*_z + 14) then linlabel = '  ' ||
                                                                     strip(linlabel);
         end;
      %end;
      run;
 
      data summary;
         set summary;
         array vls {&totcolall.} value1 - value&totcolall.;
         if (statord eq ' ') then linlabel2 = linlabel;
            *******************************************************************;
            * For Any drug and All drug d/cons, collapse into one line        *;
            *******************************************************************;
         retain linlabel2;
            *******************************************************************;
            * If Oncology flag set, then delete middle row of panel for       *;
            * Completing Study Drug                                           *;
            *******************************************************************;
      %if &show_drug_zero. eq N and &dx_ass. gt 1 and &showall. ne Y %then %do;
         if (find(linlabel2, 'Completion Status') gt 0) then do;
            if (compress(value&totcolall., ' ') eq '0') then do;
               do j = 1 to (&totcolall. - 1);
                  call missing(vls{j});
               end;
            end;
         end;
         drop j;
      %end;
         retain linlabel2;
      run;
 
      proc sort data = summary;
         by pageno sortord statord;
      run;
 
      data summary
           &outdsn.;
         set summary;
         by pageno sortord statord;
         %***************************************************************;
         %* User request to supress <Completed Study> row.              *;
         %***************************************************************;
      %if &dx_compflv. ge 1 and &show_drug_zero. eq N %then %do;
         %***************************************************************;
         %* Clear out Value cols where drug was not dosed. If the drug  *;
         %* being examined does not appear in the relevant column by    *;
         %* <drug_assign> then erase the <0> value which is an artifact *;
         %* and not a real finding.                                     *;
         %* Also: to be consistent with the original study teams report,*;
         %* if finding of only <0> are reported and that drug is not    *;
         %* given under that heading, then blank out the findings under *;
         %* both the current column and also the far right column       *;
         %***************************************************************;
         array vls {&totcolall.} value1 - value&totcolall.;
         valdim = dim(vls) - 1;
         array dxnom {&dx_compflv.} $ 50 dxnom1 - dxnom&dx_compflv.;
         array dxasn {&dx_compflv.} $ 10 dxasn1 - dxasn&dx_compflv.;
         length
                  _jc $  10
                word1 $ 100
            drugindex
            drugnames $ 200;
         drugnames = "&drug_name.";
         drugindex = "&drug_assign.";
         do _i = 1 to &dx_compflv.;
           dxnom{_i} = scan(drugnames,  _i, '|');
           dxasn{_i} = scan(drugindex,  _i, '|');
         end;
         drop word1 _i _j valdim;
         retain word1 valdim;
         if (20 <= sortord <= 99 ) then do;
            if first.sortord       then word1 = scan(linlabel,  1, ' ');
            if (word1 eq 'Reason') then word1 = scan(linlabel, -1, ' ');
            do _j = 1 to valdim;
               _jc = put(_j, 1.);
               k = 0;
               do until(indexW(dxnom{k}, word1) gt 0);
                  k = k + 1;
               end;
               thisasgn = dxasn{k};
               findyn = index(thisasgn, trim(_jc));
               if (findyn ne 0) then;
         %if &dx_compflv. gt 1 %then %do;
            %******************************************************************;
            %* Only execute this code if >1 Drug name provided                *;
            %******************************************************************;
               else if compress(vls{_j}, ' ') eq '0' then do;
                  vls{_j} = '';
         %if &ocprint = Y %then %do;
                  vls{&totcolall.} = '';
         %end;
               end;
         %end;
            end;
         end;
      %end;
         if first.sortord then do;
            linlabel = left(linlabel);
            if last.sortord then do;
               if index(linlabel, '~') then linlabel = strip(compbl(linlabel));
            end;
         end;
         %*********************************************************************;
         %* If byperiod then indent sub-period sections further.              *;
         %*********************************************************************;
      %if &num_period gt 1 %then %do;
            do _z = 1 to num_period;
               if (5*_z + 11) <= sortord <= (5*_z + 14) then linlabel = '  ' ||
                                                                        strip(linlabel);
            end;
      %end;
      run;
 
      %tabdrpt(titlekey = &titlekey,
                outname = &titlekey,
                 cwidth = &cwidth.);
   %end;
   %else %do;
    ***************************************************************************;
    * No OBS to report on                                                     *;
    ***************************************************************************;
      data final &outdsn.;
         length noevent $ 200;
         noevent = "No %lowcase(&study_subject_text.) met this condition.";
      run;
 
      %PRINTSET(outname= &titlekey., titlekey= &titlekey., foot_nodata=Y);
 
      proc report data = final headline headskip split='~ ' missing spacing = 1;
         column ('___' '   ' noevent );
         define noevent / display width=149 ' ' center flow;
      run;
 
      %PAGESET(outname = &titlekey.);
   %end;
 
   %***************************************************************************;
   %* Clean up WORK library datasets                                          *;
   %***************************************************************************;
   %if &cleanup = Y %then %do;
      proc datasets lib = WORK kill memtype = data nolist;
         run;
      quit;
   %end;
 
%mend mk_t_s_disp;
 
%mk_t_s_disp(
   subjid=subjid,
   statlen=3,
   titlekey=t-s-disp,
   lib=adamdata,
   dsin=adsl,
   eff_pop=ittfl,
   where_cl_pop= ,
   tmacro= ,
   colvar=trt01pn,
   colvar_saffl= ,
   trt_fmt=trtfmt,
   show_scrnfl=Y,
   show_scfailfl=N,
   show_notenrll=N,
   show_notdosed=N,
   show_efffl=Y,
   opt_popfl_var=pkfl,
   opt_popfl_lbl=Pharmacokinetic Analysis Set,
   colvar_opt_popfl= ,
   show_comptrt=Y,
   show_dctreas=Y,
   show_compstdy=Y,
   show_dcsreas=Y,
   drug_assign= ,
   drug_comptrt_var= ,
   drug_dctreas_var= ,
   drug_name= ,
   show_drug_zero=N,
   show_comptrt_any=N,
   byperiod=N,
   num_period= ,
   period_nm= ,
   ocprint=Y,
   showall=N,
   col1width=50,
   cwidth= ,
   spacing=3,
   spanhdr= ,
   spanrang= ,
   cleanup=Y
   );
 
