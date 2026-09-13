 
/* start of header *********************************************************************************
Program Name:      t-s-aebrief.sas
Program Author:    Caroline Pearson (cpearson1)
Program Purpose:   Create Standard AE Overall Table
 
*********************************************************************************** end of header */
 
 
%macro mk_t_s_aebrief(       subjid=, /*Specifies variable with unique subject id*/
                            statlen=, /*Value to send to STATLEN parameter of TABDESC*/
                           titlekey=, /*Specifies the titlekey for the TFL in the TNF file. */
                                lib=, /*SAS libref for dsin created in the init.inc file*/
                               dsin=, /*Participant-level ADaM dataset.*/
                             tmacro=, /*User-written macro in TOOLS that pre-processes dsin.*/
                             colvar=, /*Numeric variable, usually TRT01AN, that defines columns*/
                            trt_fmt=, /*Format for the numeric values of colvar*/
                           pop_flag=, /*Population flag used by %fetch macro to subset dsin.*/
                       where_cl_pop=, /*Optional WHERE clause for dsin*/
                          keep_adsl=, /*Variables to keep in dsin when merging with other datasets.*/
                             aedsin=, /*AE-level ADaM dataset*/
                           tmacroae=, /*User-written macro in TOOLS to process aesdin*/
                      where_cl_data=, /*Optional WHERE clause for aedsin*/
                        sev_grd_sys=, /*Whether or not grading system is used for severity*/
                            disp_g3=, /*Display Grade 3 or 4[O], 3 or Higher[Y], or none[N]*/
							disp_g2=, /*Display Grade 2,3, or 4[O], 2 or Higher[Y], or none[N]*/
							 MAXSEV=, /*Occurrence flag for maximum severity/intensity*/
                           disp_ref=, /*Display count of TEAEs related to study reference drug*/
                            num_ref=, /*Number of study reference drugs*/
						   	ref_name=, /*List of reference drug names (pipe-delimited)*/
                            rel_ref=, /*Pipe-delimited list of variables for determining relationship to ref drug*/
						disp_anyref=, /*Display count of TEAEs related to any study drug.*/
                         disp_refg2=, /*Display count of Grades (>=2)of TEAEs related to study drug*/
                         disp_refg3=, /*Display count of Grades (>=3)of TEAEs related to study drug*/
					  MAXSEV_ANYREL=, /*Occurrence flag for max sev/int related to reference drug.*/
						 MAXSEV_REL=, /*Space-delim. list of Occurrence flags for max sev/int related to ref drug*/
                         disp_sdisc=, /*Display count of AEs leading to study discontinuation?*/
                         disp_inter=, /*Display count of AEs leading to study drug interruption?*/
						   disp_mod=, /*Display count of AEs leading to study drug modification?*/
					 disp_mod_inter=, /*Display count of AEs leading to study drug modification or interruption?*/
                         disp_reduc=, /*Display count of AEs leading to dose reduction?*/
					   disp_ref_acn=, /*Display count of action taken for reference drug?*/
					   acn_ref_name=, /*Pipe-delimited names of ref drugs involved in action taken*/
                            acn_ref=, /*Pipe-delimited list of variables that specify action taken for ref drugs"*/
                    disp_anyref_acn=, /*Display counts of AEs for each action taken for any study drug*/
                         disp_sproc=, /*Display count of TEAEs related to study procedures?*/
						   aesi_var=, /*Space-delimited list of SMQ variables for TEAE of interest*/
						   aesi_lbl=, /*Pipe-delimited list of the names of the TEAE of interest*/
						   disp_irr=, /*Display count of infusion related reactions?*/
						   disp_dlt=, /*Display count of dose-limiting toxicity?*/
						    dlt_var=, /*Specifies the name of a dose-limiting toxicity variable*/
						 disp_dthfl=, /*Display deaths?*/
                       disp_dth30fl=, /*Display deaths within 30 days last dose and after 30 days of last dose?*/
                      disp_lead2dth=, /*Display a section for TEAE Leading to Death?*/
					    disp_reldth=, /*Display section for related TEAE Leading to Death?*/
					disp_ref_reldth=, /*Display section for reference drug related TEAE Leading to Death?*/
			     disp_anyref_reldth=, /*Display section for any study drug related TEAE Leading to Death?*/
                       disp_tedthfl=, /*Display treatment-emergent deaths?*/
                          other_acn=, /*The name of the variable for OTHER ACTION TAKEN.*/
                              prefl=, /*Display pre-treatment AEs?*/
                            ocprint=, /*Specifies whether to print an OVERALL column.*/
                            pvalpat=, /*Specifies what type of p value to produce for participant count summaries.*/
                           opgroups=, /*List of treatment values to be summarized in the p-value calculations. */
						pval_header=, /*Text of treatment comparison for p value in column header*/
                          col1width=, /*Width of Column 1 in characters*/
                            spacing=, /*Integer that determines the number of blank columns between table columns*/
                            spanhdr=, /*Text that will appear above and across columns listed in spanrang.*/
                           spanrang=, /*Column numbers that will be arrayed beneath spanhdr.*/
                             cwidth=, /*Column Width*/
							cleanup=);
   options missing='';
 
   %global r_rel_cnt r_acn_cnt aesi_var_cnt aesi_lbl_cnt;
 
   ****************************************************************************;
   * Upcase all Y/N/O parameters at the beginning of macro processing         *;
   ****************************************************************************;
   %m_stars_upcase(varlist=
sev_grd_sys~1 disp_g2~1 disp_g3~1 disp_ref~1 disp_anyref~1 disp_refg2~1 disp_refg3~1
disp_sdisc~1 disp_inter~1 disp_mod~1 disp_mod_inter~1 disp_reduc~1 disp_ref_acn~1
disp_anyref_acn~1 disp_sproc~1 disp_irr~1 disp_dlt~1 disp_dthfl~1 disp_dth30fl~1
disp_lead2dth~1 disp_reldth~1 disp_ref_reldth~1 disp_anyref_reldth~1 disp_tedthfl~1
prefl~1 ocprint~1  cleanup~1
);
 
 
 
   ****************************************************************************;
   * Set Parameter Defaults if not Populated                                  *;
   ****************************************************************************;
   %if &disp_g2=O or &disp_g3=O %then %do;
        %if disp_reldth=N %then %put NOTE: DISP_RELDTH set to Y given DISP_G2=O or DISP_G3=O;
        %if disp_lead2dth=N %then %put NOTE: DISP_LEAD2DTH set to Y given DISP_G2=O or DISP_G3=O;
        %let disp_reldth=Y;
        %let disp_lead2dth=Y;
   %end;
   %if &disp_refg2=O or &disp_refg3=O %then %do;
        %if &disp_reldth=N %then %put NOTE: DISP_RELDTH set to Y given DISP_REFG2=O or DISP_REFG3=O;
        %if &disp_ref_reldth=N %then %put NOTE: DISP_REF_RELDTH set to Y given DISP_REFG2=O or DISP_REFG3=O;
        %let disp_reldth=Y;
        %let disp_ref_reldth=Y;
        %if &disp_anyref_reldth=N %then %put NOTE: DISP_ANYREF_RELDTH set to Y given (DISP_REFG2=O or DISP_REFG3=O) and DISP_ANYREF=Y;
        %if &disp_anyref=Y %then %let disp_anyref_reldth=Y;
   %end;
 
   proc format;
      value yn
         0 = 'N'
         1 = "Y";
   run;
 
   /*============================================================================
    						E R R O R - C H E C K S
   ==============================================================================*/
 
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
 
   %if &disp_ref. = Y %then %do; * Get names of study ref drugs dynamically and checks;
      %if &num_ref = %then %do;
         %let num_ref = 1;
         data _null_;
            put "WARN" "ING: [USER] User selected Y to display Study Reference Drug but did not specify the number of ref. drug. Defaults to 1";
         run;
      %end;
   %end;
 
   %if (%nrbquote(&rel_ref.) ^= or %nrbquote(&acn_ref.) ^=) and %nrbquote(&num_ref.)= %then %do;
      data _null_;
         put "ERR" "OR: [USER] User must populate NUM_REF if ACN_REF and/or REL_REF parameters are specified";
         abort abend;
      run;
   %end;
/*=============================(NEW)=====================================================*/
   %if %index(&disp_g2.&disp_g3.&disp_refg2.&disp_refg3,O) and %index(&disp_g2.&disp_g3.&disp_refg2.&disp_refg3,Y) %then %do;
      data _null_;
         put "ERR" "OR: [USER] User must be consistent in use of O or Y for DISP_G2, DISP_G3, DISP_REFG2, DISP_REFG3 given study either is or is not Oncology";
         abort abend;
      run;
   %end;
 
   %if (%nrbquote(&rel_ref.) ^= or %nrbquote(&acn_ref.) ^=) and %nrbquote(&num_ref.)= %then %do;
      data _null_;
         put "ERR" "OR: [USER] User must populate NUM_REF if ACN_REF and/or REL_REF parameters are specified";
         abort abend;
      run;
   %end;
 
    %if (%nrbquote(&disp_g2.) = O or %nrbquote(&disp_g3.)=O) and %nrbquote(&maxsev.)= %then %do;
      data _null_;
         put "ERR" "OR: [USER] User must populate MAXSEV if DISP_G2=O and/or DISP_G3=O";
         abort abend;
      run;
   %end;
 
     %if %nrbquote(&disp_anyref.) = Y and (%nrbquote(&disp_g2.) = O or %nrbquote(&disp_g3.)=O) and %nrbquote(&MAXSEV_ANYREL.)= %then %do;
      data _null_;
         put "ERR" "OR: [USER] User must populate MAXSEV_ANYREL if DISP_ANYREF=Y and DISP_G2=O and/or DISP_G3=O";
         abort abend;
      run;
   %end;
 
%* 10/30/2025 7:27:31 AM EJC: METADATA change for MAXSEV_REL 11/24/2025 MSD: added error for num_ref>1 and disp_ref=N;
%*	 NOTE: Value must not be null when NUM_REF=1 and (DISP_G3=O or DISP_G2=O) or NUM_REF gt 1 and (DISP_REFG3=O or DISP_REFG2=O);
 
%* EJC 10/27/2025 1:17:50 PM - Typo for DISP_REFG3    %if (%nrbquote(&disp_refg2.) = O or %nrbquote(&disp_refg3=O)=O) and %nrbquote(&MAXSEV_REL.)= %then %do;
    %if &NUM_REF = 1 and (%nrbquote(&DISP_G2) = O or %nrbquote(&DISP_G3) = O) and %nrbquote(&MAXSEV_REL) = %then %do;
      data _null_;
         put "ERR" "OR: [USER] User must populate MAXSEV_REL if NUM_REF=1 and (DISP_G2=O or DISP_G3=O)";
         abort abend;
      run;
   %end;
   %if &NUM_REF > 1 and (%nrbquote(&DISP_REFG2) = O or %nrbquote(&DISP_REFG3) = O) and %nrbquote(&MAXSEV_REL) = %then %do;
      data _null_;
         put "ERR" "OR: [USER] User must populate MAXSEV_REL if NUM_REF > 1 and (DISP_REFG2=O or DISP_REFG3=O)";
         abort abend;
      run;
   %end;
   %if &NUM_REF > 1 and (%nrbquote(&DISP_REFG2) = O or %nrbquote(&DISP_REFG3) = O) and %nrbquote(&DISP_REF) = N %then %do;
      data _null_;
         put "ERR" "OR: [USER] DISP_REF=N not valid if NUM_REF > 1 and (DISP_REFG2=O or DISP_REFG3=O)";
         abort abend;
      run;
   %end;
 
   ****************************************************************************;
   * If reference drugs present parameterize their corresponding action taken *;
   * and related vars                                                         *;
   ****************************************************************************;
   %if &num_ref. > %then %do;
      %do i = 1 %to &num_ref.;
         %if %nrbquote(&rel_ref.) ne %then %do;
            *******************************************************************;
            * Related category not always collected for reference drugs       *;
            *******************************************************************;
            %let r_rel_cnt = %eval(%sysfunc(countc(&rel_ref., '|')) + 1);
            %let r_rel&i. = %scan(&rel_ref., &i, '|');
         %end;
         %else %let r_rel_cnt = 0;
 
         %if %nrbquote(&acn_ref.) ne %then %do;
            *******************************************************************;
            * Action taken category not always collected for reference drug   *;
            *******************************************************************;
            %let r_acn_cnt = %eval(%sysfunc(countc(&acn_ref., '|'))+1);
            %let r_acn&i. = %scan(&acn_ref., &i, '|');
         %end;
         %else %let r_acn_cnt = 0;
 
         %if %nrbquote(&ref_name.) ne %then %do;
            %let r_name_cnt = %eval(%sysfunc(countc(&ref_name., '|'))+1);
            *******************************************************************;
            * Confirm that number of refnames matches num_ref                 *;
            *******************************************************************;
            %if &r_name_cnt. = &num_ref. %then %do;
               %let refname&i. = %qscan(&ref_name, &i, '|');
            %end;
            %else %do;
               data _null_;
                  put "ERR" "OR: [USER] Number of reference drug names must match NUM_REF parameter value";
                  abort abend;
               run;
            %end;
         %end;
 
         %if %nrbquote(&acn_ref_name.) ne %then %do;
            %let r_acn_name_cnt = %eval(%sysfunc(countc(&acn_ref_name., '|'))+1);
            *******************************************************************;
            * Confirm that number of refnames matches num_ref                 *;
            *******************************************************************;
            %if &r_acn_name_cnt. = %eval(%sysfunc(countc(&acn_ref., '|'))+1) %then %do;
               %let acn_refname&i. = %qscan(&acn_ref_name, &i, '|');
            %end;
            %else %do;
               data _null_;
                  put "ERR" "OR: [USER] Number of ACN reference drug names must match number of ACN variables";
                  abort abend;
               run;
            %end;
         %end;
      %end;
      %let i = ;
   %end;
   %else %do;
      %let r_rel_cnt = 0;
      %let r_acn_cnt = 0;
   %end;
 
   %if &disp_ref. = N and (&disp_refg2. = Y or &disp_refg3. = Y) %then %do;
      %let disp_refg2 = N;
      %let disp_refg3 = N;
 
      data _null_;
         put "WARN" "ING: [USER] DISP_REF = N but other reference drug parameters are Y - These will not display unless DISP_REF = Y";
      run;
   %end;
 
   %if &disp_ref. = Y and  &disp_anyref. = N %then %do;
      %let disp_anyref = Y;
 
      data _null_;
         put "WARN" "ING: [USER] DISP_REF = Y but DISP_ANYREF = N - DISP_ANYREF cannot be N if DISP_REF = Y";
      run;
   %end;
 
   %if &disp_ref_acn. = Y and  &disp_anyref_acn. = N %then %do;
      %let disp_anyref_acn = Y;
 
      data _null_;
         put "WARN" "ING: [USER] DISP_REF_ACN = Y but DISP_ANYREF_ACN = N - DISP_ANYREF_ACN cannot be N if DISP_REF = Y";
      run;
   %end;
 
 
			*******************************************************************;
            * Confirm that number of elements in MAXSEV_REL matches rel_ref   *;
            *******************************************************************;
 
    /*********(EXTRACT MAXSEV_REL PARAMETER VALUES)***********/
	   	%if "&MAXSEV_REL" ne %then %do;
   			%PUT &=MAXSEV_REL;
			%let numsevrefs  = %sysfunc(countw(%str(&MAXSEV_REL), %str( )));
			%PUT &=numsevrefs;
   			%do ii=1 %to  %eval(&numsevrefs);
				%let maxsevref&ii = %scan(%str(&MAXSEV_REL),&ii,%str( ));
			%end;
		%end;
 
 	  %if (&DISP_REFG2=O or &DISP_REFG3=O) AND ((%eval(&r_rel_cnt.) NE %eval(&numsevrefs.)))  %then %do;
       data _null_;
                  put "ERR" "OR: [USER] Number of elements in MAXSEV_REL and REL_REF are not the same";
                  abort abend;
       run;
    %end;
			
   ****************************************************************************;
   * AESI_VAR and AESI_LBL processing                                         *;
   ****************************************************************************;
   %if %length(&aesi_var.)>0 %then %do;
      %do i = 1 %to %eval(%sysfunc(countw(&aesi_var%str( ))));
          %let aesi_var_cnt = %eval(%sysfunc(countw(&aesi_var%str( ))));
          %let aesi_var&i. = %qscan(&aesi_var, &i, %str( ));
 
         %if %nrbquote(&aesi_lbl.) ne %then %do;
            %let aesi_lbl_cnt = %eval(%sysfunc(countc(&aesi_lbl., '|'))+1);
            *******************************************************************;
            * Confirm that number of aesi_lbl matches aesi_var                *;
            *******************************************************************;
            %if &aesi_var_cnt. = &aesi_lbl_cnt. %then %do;
               %let aesi_lbl&i. = %qscan(&aesi_lbl, &i, '|');
            %end;
            %else %do;
               data _null_;
                  put "ERR" "OR: [USER] Number of AESI_LBL must match number of AESI_VAR variables";
                  abort abend;
               run;
            %end;
         %end;
	  %end;
   %end; %else %do;
      %let aesi_var_cnt = 0;
      %let aesi_lbl_cnt = 0;
   %end;
 
   ****************************************************************************;
   * Read in Data and Preprocess                                              *;
   ****************************************************************************;
      * Get ADSL data for denominators;
   %FETCH(  library = &lib.,
            data    = &dsin.,
            out     = &dsin._1,
            sortby  = &subjid,
            dataopt = where=(&pop_flag. = "Y"));
 
   %if %nrbquote(&tmacro)^= and %upcase(&tmacro)^=NULL %then %do;
      %&tmacro(data=&dsin._1);
   %end;
 
   %M_CHKVAR(var = &subjid,        inds = &dsin._1, libnm = work);
   %M_CHKVAR(var = &pop_flag.,     inds = &dsin._1, libnm = work);
   %M_CHKVAR(var = &colvar.,      inds = &dsin._1, libnm = work);
   %M_CHKVAR(var = dthfl,      	   inds = &dsin._1, libnm = work);
	%if &disp_dth30fl. = Y %then %do;
		%M_CHKVAR(var = dth30fl,      	   inds = &dsin._1, libnm = work);
		%M_CHKVAR(var = dthg30fl,      	   inds = &dsin._1, libnm = work);
	%end;
	%if &disp_tedthfl. = Y %then %do;
		%M_CHKVAR(var = tedthfl,      	   inds = &dsin._1, libnm = work);
	%end;
    %if %upcase(&disp_dlt) = Y %then %do;
        %M_CHKVAR(var = dltfl,      	   inds = &dsin._1, libnm = work);
	%end;
 
   data &dsin._1 ;
      set &dsin._1 &where_cl_pop;
   run;
 
   proc sort data=&dsin._1;
      by &subjid &colvar;
   run;
 
   %nobs(&dsin._1);
   %if &nobs > 0 and %upcase(&disp_dlt) = Y %then %do;
     * Count AEDLT flagged subjects;
      proc sql noprint;
         select max(&colvar) into: __mtrt from &dsin._1;
         %do i=1 %to &__mtrt;
            select count(usubjid) into: dltcnt_&i from &dsin._1 where dltfl="Y" and &colvar=&i;
         %end;
         select count(usubjid) into: dltcnt_%eval(&__mtrt + 1) from &dsin._1 where dltfl="Y";
      quit;
      %do i=1 %to %eval(&__mtrt + 1); %let dltcnt_&i=&&dltcnt_&i; %end;
   %end;
 
   	 * Get ADAE data;
   %FETCH(library = &lib.,
          data    = &aedsin. ,
          out     = &aedsin._1,
          dataopt = where=(&pop_flag. = "Y"),
          sortby  = &subjid);
 
   %if %nrbquote(&tmacroae)^= and %upcase(&tmacroae)^=NULL %then %do;
      %&tmacroae(data=&aedsin._1);
   %end;
 
   data &aedsin._1 ;
      set &aedsin._1 &where_cl_data;
   run;
 
   proc sort data=&aedsin._1;
      by &subjid &colvar;
   run;
 
   /**************************************************************************************/
   /* ERR OR CHECKING - Verify that all necessary ADAE vars exist in dataset;            */
   /**************************************************************************************/
   %M_CHKVAR(var = trtemfl,        inds = &aedsin._1, libnm = work);
   %M_CHKVAR(var = arel,           inds = &aedsin._1, libnm = work);
   %M_CHKVAR(var = atoxgr,         inds = &aedsin._1, libnm = work);
   %M_CHKVAR(var = aeser,          inds = &aedsin._1, libnm = work);
   %M_CHKVAR(var = aacn1,          inds = &aedsin._1, libnm = work);
   %if %upcase(&other_acn.) ^= %then %do;
      %M_CHKVAR(var = &other_acn., inds = &aedsin._1, libnm=work);
   %end;
   %if &prefl. = Y %then %do;
      %M_CHKVAR(var = prefl,       inds = &aedsin._1, libnm = work);
   %end;
 
   %if %nrbquote(&rel_ref.) ne %then %do;
      %do i = 1 %to &r_rel_cnt;
         %M_CHKVAR(var = %upcase(&&r_rel&i), inds = &aedsin._1, libnm = work);
      %end;
      %let i = ;
   %end;
 
   %if %nrbquote(&acn_ref.) ne %then %do;
      %do i = 1 %to &r_acn_cnt.;
         %M_CHKVAR(var = %upcase(&&r_acn&i), inds = &aedsin._1, libnm = work);
      %end;
      %let i = ;
   %end;
 
 
   %MACRO ck_dsvar_dth(inds =, var =, mvar= );
      %local rc dsid;
      %global &mvar._dthfl;
 
      %let dsid = %sysfunc(open(work.&inds.));
 
      %if &dsid. %then %do;
         %if %sysfunc(varnum(&dsid., &var.)) %then %do;
            %let &mvar._dthfl=1;
            %let rc = %sysfunc(close(&dsid.));
            %return;
         %end;
         %else %do;
            %let &mvar._dthfl=0;
            %let rc = %sysfunc(close(&dsid.));
            %return;
         %end;
      %end;
   %MEND ck_dsvar_dth;
   %ck_dsvar_dth(inds = &aedsin._1, var = dthfl, mvar=adae);
   %ck_dsvar_dth(inds = &dsin._1, var = dthfl, mvar=adsl);
 
   %if &adae_dthfl^=1 and &adsl_dthfl^=1 %then %do;
      data _null_;
         put "ERR" "OR:  [USER] Variable DTHFL does" " not exist in &lib..&dsin. and &aedsin. dataset.";
         abort;
      run;
   %end;
 
   %if %upcase(&other_acn.) ne and %upcase(&other_acn.) ne AACNOTH and %upcase(&other_acn.) ne AEACNOTH %then %do;
      data _null_;
            put "WARN" "ING: [USER] In" "valid variable choice for OTHER_ACN: select AACNOTH or AEACNOTH. Will be set to null otherwise";
      run;
      %let &other_acn. = ;
   %end;
 
 
   data _adae_1 _adae_2; *keep all ADSL subjects who appear in ADAE;
      merge &aedsin._1 (in=in1 drop=dthfl) &dsin._1 (in = inadsl keep=&subjid &colvar dthfl
										%if &disp_dth30fl. = Y %then %do; dth30fl dthg30fl %end;
         								%if &disp_tedthfl. = Y %then %do; tedthfl %end; );
 
      by &subjid &colvar;
 
      if in1 then output _adae_1;
	  if inadsl then output _adae_2;
   run;
 
 
   /*-------------------------------------------------------------------------------
                  D A T A     P R O C E S S I N G
   ---------------------------------------------------------------------------------*/
 
   %MACRO AE_CRIT(order = , crit = , text = );
      proc sort data = _adae_1 out = temp_&order. nodupkey;
	     where &crit;
         by &subjid &colvar;
      run;
 
      data temp_&order.;
         length text $200;
         merge &dsin._1(in=inadsl keep=&subjid &colvar) temp_&order.(in = inadae);
         by &subjid &colvar;
         if inadsl;
 
         cat= &order.;
         text=compbl("&text.");
         yn=inadae;
      run;
   %MEND AE_CRIT;
 
   %MACRO AE_DTH_CRIT(order = , crit = , text = );
      proc sort data = _adae_2 out = temp_&order. nodupkey;
	     where &crit;
         by &subjid &colvar;
      run;
 
      data temp_&order.;
         length text $200;
         merge  &dsin._1(in=inadsl keep=&subjid &colvar) temp_&order.(in = inadae);
         by &subjid &colvar;
         if inadsl;
 
         cat= &order.;
         text=compbl("&text.");
         yn=inadae;
      run;
   %MEND AE_DTH_CRIT;
 
   *** Remove temp_xx datasets from previous run;
   /*DATA TEMP_;XXX=0;RUN; *//*This is necessary to avoid "work.temp_" causing a "NOT FOUND" note*/
 
proc sql noprint;
   create table meminfox as select *
      from dictionary.tables
      where (libname eq 'WORK') and (index(memname,'TEMP_')>0);
quit;
%IF &SQLOBS NE 0 %THEN %DO;
	PROC SQL NOPRINT;
		select memname into :memlist separated by ","
			from meminfox;
 
			drop table &memlist;
	QUIT;
 
	%PUT &=memlist;
%END;
 
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmm(AE MAXSEV GRADES WITH OCCURRENCE FLAGS)mmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
 
 
   ****************************************************************************;
   * TEAE by Grade  [NEW: Include Max Intensity/Severity Occurrence Flags]     ;            ;                                                       *;
   ****************************************************************************;
   %AE_CRIT(order = 1, crit = %str(trtemfl = "Y"), text = Any TEAE);
 
   %if &sev_grd_sys. = Y %then %do;
      %if &disp_g3.  = O AND &MAXSEV NE %then %do;
         %AE_CRIT(order = 2,
                crit = %str(trtemfl = "Y" AND &MAXSEV="Y" and upcase(atoxgr) in ("3", "4", "GRADE 3", "GRADE 4")),
                text = TEAE with Grade 3 or 4);
      %end; %else %if &disp_g3.  = Y %then %do;
         %AE_CRIT(order = 2,
                crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("3", "4", "5", "GRADE 3", "GRADE 4", "GRADE 5")),
                text = TEAE with Grade 3 or Higher);
      %end;
 
      %if &disp_g2.  = O AND &MAXSEV NE %then %do;
         %AE_CRIT(order = 3,
                   crit = %str(trtemfl = "Y" AND &MAXSEV="Y" and upcase(atoxgr) in ("2", "3", "4", "GRADE 2", "GRADE 3", "GRADE 4")),
                   text = %str(TEAE with Grade 2, 3 or 4));
      %end; %else %if &disp_g2.  = Y %then %do;
         %AE_CRIT(order = 3,
                   crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("2", "3", "4", "5", "GRADE 2", "GRADE 3", "GRADE 4", "GRADE 5")),
                   text = TEAE with Grade 2 or Higher);
      %end;
   %end;
   %else %do;
      %AE_CRIT(order = 2,
                crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("SEVERE")),
                text = Severe TEAE);
   %end;
 
   ****************************************************************************;
   * Related TEAE                                                    *;
   ****************************************************************************;
   %if %upcase(&disp_anyref)=Y %then %do;
       %AE_CRIT(order = 4,
                crit = %str(trtemfl = "Y" and upcase(arel) = "RELATED"),
                text = TEAE Related to Any Study Drug);
   %end; %else %do;
       %AE_CRIT(order = 4,
                crit = %str(trtemfl = "Y" and upcase(arel) = "RELATED"),
                text = TEAE Related to Study Drug);
   %end;
 
   *** Optional Related TEAE for Study Ref. Drug;
   %if &disp_ref = Y and %upcase(&disp_anyref)=Y %then %do;
         %do i = 1 %to &r_rel_cnt.;
            %AE_CRIT(order = %eval(4+&i.),
                     crit = %str(trtemfl = "Y" and upcase(&&r_rel&i.) = "RELATED"),
                     text = TEAE Related to &&refname&i.);
         %end;
 
		****************************************************************************;
   		* Related TEAE by Grade  (INCLUDE MAX SEV OCCURRENCE FLAGS)                                                  *;
   		****************************************************************************;
%* 10/29/2025 3:34:59 PM EJC: Added MAXSEV_ANYREL 11/24/2025 MSD: Updated logic for DISP_G3 vs DISP_REFG3;
	     %if &disp_g3. = O and %length(&MAXSEV_ANYREL) > 0 %then %do;
	         %AE_CRIT(order = 15,
                   crit = %str(trtemfl = "Y" AND &MAXSEV_ANYREL="Y" and upcase(atoxgr) in ("3", "4", "GRADE 3", "GRADE 4") and upcase(arel) = "RELATED"),
                   text = TEAE Related to Any Study Drug with Grade 3 or 4);
             %if &disp_refg3. = O %then %do;
                 %do i = 1 %to &r_rel_cnt.;
                    %AE_CRIT(order = %eval(15+&i.),
                          crit = %str(trtemfl = "Y" AND &&maxsevref&i. = "Y" and upcase(atoxgr) in ("3", "4", "GRADE 3", "GRADE 4") and upcase(&&r_rel&i.) = "RELATED"),
                          text = TEAE Related to &&refname&i. with Grade 3 or 4);
    	         %end;
    	     %end;
	     %end; %else %if &disp_g3. = Y %then %do;
	        %AE_CRIT(order = 15,
                   crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("3", "4", "5", "GRADE 3", "GRADE 4", "GRADE 5") and upcase(arel) = "RELATED"),
                   text = TEAE Related to Any Study Drug with Grade 3 or Higher);
 
            %if &disp_refg3. = Y %then %do;
                %do i = 1 %to &r_rel_cnt.;
                   %AE_CRIT(order = %eval(15+&i.),
                          crit = %str(trtemfl = "Y"  and upcase(&&r_rel&i.) = "RELATED" and upcase(atoxgr) in ("3", "4", "5", "GRADE 3", "GRADE 4", "GRADE 5")),
                          text = TEAE Related to &&refname&i. with Grade 3 or Higher);
    	        %end;
    	    %end;
	     %end;
	     /*%else %if &disp_refg3. = N and &disp_g3 = Y %then %do;
	        %AE_CRIT(order = 15,
                   crit = %str(trtemfl = "Y"  and upcase(atoxgr) in ("3", "4", "5", "GRADE 3", "GRADE 4", "GRADE 5") and upcase(arel) = "RELATED"),
                   text = TEAE Related to Any Study Drug with Grade 3 or Higher);
	     %end;
	     */
 
%* 10/29/2025 3:52:47 PM EJC: Added MAXSEV_ANYREL 11/24/2025 MSD: Updated logic for DISP_G2 vs DISP_REFG2;
 /*>>>>>>*/	%if &disp_g2. = O and %length(&MAXSEV_ANYREL) > 0 %then %do;
	         %AE_CRIT(order = 30,
                   crit = %str(trtemfl = "Y" and &MAXSEV_ANYREL="Y"  and upcase(atoxgr) in ("2", "3", "4", "GRADE 2", "GRADE 3", "GRADE 4") and upcase(arel) = "RELATED"),
                   text = %str(TEAE Related to Any Study Drug with Grade 2, 3 or 4));
             %if &disp_refg2. = O %then %do;
                 %do i = 1 %to &r_rel_cnt.;
                    %AE_CRIT(order = %eval(30+&i.),
                          crit = %str(trtemfl = "Y" AND &&maxsevref&i. = "Y" and upcase(&&r_rel&i.) = "RELATED" and upcase(atoxgr) in ("2", "3", "4", "GRADE 2", "GRADE 3", "GRADE 4")),
                          text = %str(TEAE Related to &&refname&i. with Grade 2, 3 or 4));
    	         %end;
    	     %end;
	     %end; %else %if &disp_g2. = Y %then %do;
	         %AE_CRIT(order = 30,
                   crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("2", "3", "4", "5", "GRADE 2", "GRADE 3", "GRADE 4", "GRADE 5") and upcase(arel) = "RELATED"),
                   text = TEAE Related to Any Study Drug with Grade 2 or Higher);
             %if &disp_refg2. = Y %then %do;
                 %do i = 1 %to &r_rel_cnt.;
                    %AE_CRIT(order = %eval(30+&i.),
                          crit = %str(trtemfl = "Y" and upcase(&&r_rel&i.) = "RELATED" and upcase(atoxgr) in ("2", "3", "4", "5", "GRADE 2", "GRADE 3", "GRADE 4", "GRADE 5")),
                          text = TEAE Related to &&refname&i. with Grade 2 or Higher);
    	         %end;
    	     %end;
	     %end;
	     /*%else %if &disp_refg2. = N and &disp_g2 = Y %then %do;
	         %AE_CRIT(order = 30,
                   crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("2", "3", "4", "5", "GRADE 2", "GRADE 3", "GRADE 4", "GRADE 5") and upcase(arel) = "RELATED"),
                   text = TEAE Related to Any Study Drug with Grade 2 or Higher);
	     %end;
	     */
   %*  11/24/2025 MSD: Fixed, plus added oncology;
   %end; %else %if &disp_ref = N and %upcase(&disp_anyref)=Y %then %do;
         %if &disp_g3. = O and %length(&MAXSEV_ANYREL) > 0 %then %do;
	        %AE_CRIT(order = 15,
                   crit = %str(trtemfl = "Y" AND &MAXSEV_ANYREL="Y" and upcase(atoxgr) in ("3", "4", "GRADE 3", "GRADE 4") and upcase(arel) = "RELATED"),
                   text = TEAE Related to Any Study Drug with Grade 3 or 4);
	     %end;
         %else %if &disp_g3. = Y %then %do;
	        %AE_CRIT(order = 15,
                   crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("3", "4", "5", "GRADE 3", "GRADE 4", "GRADE 5") and upcase(arel) = "RELATED"),
                   text = TEAE Related to Any Study Drug with Grade 3 or Higher);
	     %end;
 
         %if &disp_g2. = O and %length(&MAXSEV_ANYREL) > 0 %then %do;
	        %AE_CRIT(order = 30,
                   crit = %str(trtemfl = "Y" and &MAXSEV_ANYREL="Y"  and upcase(atoxgr) in ("2", "3", "4", "GRADE 2", "GRADE 3", "GRADE 4") and upcase(arel) = "RELATED"),
                   text = %str(TEAE Related to Any Study Drug with Grade 2, 3 or 4));
	     %end;
         %else %if &disp_g2. = Y %then %do;
	         %AE_CRIT(order = 30,
                   crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("2", "3", "4", "5", "GRADE 2", "GRADE 3", "GRADE 4", "GRADE 5") and upcase(arel) = "RELATED"),
                   text = TEAE Related to Any Study Drug with Grade 2 or Higher);
	     %end;
   %end; %else %do; *Disp_G2 and disp_G3 when not displaying for reference drug;
      %if &sev_grd_sys. = Y %then %do;
         %if &disp_g3.  = Y %then %do;
            %AE_CRIT(order = 5,
                crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("3", "4", "5", "GRADE 3", "GRADE 4", "GRADE 5") and upcase(arel) = "RELATED"),
                text = TEAE Related to Study Drug with Grade 3 or Higher);
         %end;
%* EJC 10/30/2025 7:40:52 AM: Changed MAXSEV to MAXSEV_REL;
         %else %if &disp_g3.  = O and %length(&MAXSEV_REL) > 0  %then %do;
            %AE_CRIT(order = 5,
                crit = %str(trtemfl = "Y" and &MAXSEV_REL = 'Y' and upcase(atoxgr) in ("3", "4", "GRADE 3", "GRADE 4") and upcase(arel) = "RELATED"),
                text = TEAE Related to Study Drug with Grade 3 or 4);
         %end;
 
         %if &disp_g2.  = Y %then %do;
            %AE_CRIT(order = 6,
                   crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("2", "3", "4", "5", "GRADE 2", "GRADE 3", "GRADE 4", "GRADE 5") and upcase(arel) = "RELATED"),
                   text = TEAE Related to Study Drug with Grade 2 or Higher);
         %end;
         %else %if &disp_g2. = O and %length(&MAXSEV_REL) > 0  %then %do;
            %AE_CRIT(order = 6,
                   crit = %str(trtemfl = "Y" and &MAXSEV_REL = 'Y' and upcase(atoxgr) in ("2", "3", "4", "GRADE 2", "GRADE 3", "GRADE 4") and upcase(arel) = "RELATED"),
                   text = %str(TEAE Related to Study Drug with Grade 2, 3 or 4));
         %end;
      %end;
      %else %do;
         %AE_CRIT(order = 5,
                crit = %str(trtemfl = "Y" and upcase(atoxgr) in ("SEVERE") and upcase(arel) = "RELATED"),
                text = Severe Related TEAE);
      %end;
   %end;
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
 
 
   ****************************************************************************;
   * TEAE related to Procedures                                               *;
   ****************************************************************************;
   %if &disp_sproc. = Y %then %do;
      %AE_CRIT(order = 50,
                crit = %str(trtemfl = "Y" and upcase(aerelprc) = "Y"),
                text = TEAE Related to Study Procedures);
   %end;
 
 
   ****************************************************************************;
   * Serious TEAE                                                             *;
   * Start at an arbitrary higher order number strictly for sorting purposes  *;
   ****************************************************************************;
   %AE_CRIT(order = 100,
             crit = %str(trtemfl = "Y" and aeser = "Y"),
             text = TE Serious AE);
 
   %if %upcase(&disp_anyref)=Y %then %do;
      %AE_CRIT(order = 120,
               crit = %str(trtemfl = "Y" and aeser = "Y" and upcase(arel) = "RELATED"),
               text = TE Serious AE Related to Any Study Drug);
 
      %if &disp_ref = Y %then %do;
         %do i = 1 %to &r_rel_cnt.;
            %AE_CRIT(order = %eval(120+&i.),
                   crit = %str(trtemfl = "Y" and aeser = "Y" and upcase(&&r_rel&i.) = "RELATED"),
                   text = TE Serious AE Related to &&refname&i. );
         %end;
	  %end;
   %end;  %else %do;
       %AE_CRIT(order = 120,
               crit = %str(trtemfl = "Y" and aeser = "Y" and upcase(arel) = "RELATED"),
               text = TE Serious AE Related to Study Drug);
   %end;
 
   ****************************************************************************;
   * Discontinuation - action - AESI - IRR and DLT                            *;
   ****************************************************************************;
   %if &nobs > 0 %then %do;
      %let acnvar=%str(("DRUG WITHDRAWN"));
      %let action=;
      %do i = 1 %to &r_acn_cnt.;
	      %if 1<=&i < &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) = &acnvar or);%end;
	      %if &i = &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) = &acnvar);%end;
          %let action=&action &&action&i;
      %end;
      %let action=%unquote(&action);
 
      %if %upcase(&disp_anyref_acn)=Y %then %do;
            %AE_CRIT(order = 150,
			         crit = %str(trtemfl="Y" and (&action)),
                     text = TEAE Leading to Premature Discontinuation of Any Study Drug);
 
            %if &disp_ref_acn = Y %then %do;
                %do i = 1 %to &r_acn_cnt.;
                    %AE_CRIT(order = %eval(150+&i.),
                             crit = %str(trtemfl="Y" and upcase(&&r_acn&i) = "DRUG WITHDRAWN"),
                             text = TEAE Leading to Premature Discontinuation of &&acn_refname&i.);
		        %end;
            %end;
      %end; %else %do;
          %if %length(&action)>0 %then %do;
	         %AE_CRIT(order = 150,
                     crit = %str(trtemfl="Y" and (&action)),
                     text = TEAE Leading to Premature Discontinuation of Study Drug);
           %end; %else %do;
             %AE_CRIT(order = 150,
                     crit = %str(trtemfl="Y" and upcase(aacn1) in &acnvar),
                     text = TEAE Leading to Premature Discontinuation of Study Drug);
		   %end;
      %end;
   %end;
 
   %if &disp_inter. = Y and &nobs > 0 %then %do;
   	  %let acnvar=%str(("DRUG INTERRUPTED"));
      %let action=;
      %do i = 1 %to &r_acn_cnt.;
	      %if 1<=&i < &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) = &acnvar or);%end;
	      %if &i = &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) = &acnvar);%end;
          %let action=&action &&action&i;
      %end;
	  %let action=%unquote(&action);
 
	  %if %upcase(&disp_anyref_acn)=Y %then %do;
              %AE_CRIT(order = 170,
                       crit = %str(trtemfl="Y" and (&action)),
                       text = TEAE Leading to Dose Interruption of Any Study Drug);
          %if &disp_ref_acn = Y %then %do;
             %do i = 1 %to &r_acn_cnt.;
                 %AE_CRIT(order = %eval(170+&i.),
                       crit = %str(trtemfl ="Y" and upcase(&&r_acn&i) in ("DRUG INTERRUPTED")),
                       text = TEAE Leading to Dose Interruption of &&acn_refname&i.);
		     %end;
		  %end;
	  %end; %else %do;
	      %if %length(&action)>0 %then %do;
              %AE_CRIT(order = 170,
                   crit = %str(trtemfl="Y" and (&action)),
                   text = TEAE Leading to Dose Interruption of Study Drug);
	      %end; %else %do;
            %AE_CRIT(order = 170,
                     crit = %str(trtemfl="Y" and upcase(aacn1) in &acnvar),
                     text = TEAE Leading to Dose Interruption of Study Drug);
		  %end;
	  %end;
   %end;
 
   %if &disp_mod. = Y and &nobs > 0 %then %do;
   	  %let acnvar=%str(("DOSE INCREASED" "DOSE REDUCED"));
      %let action=;
      %do i = 1 %to &r_acn_cnt.;
	      %if 1<=&i < &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) in &acnvar or);%end;
	      %if &i = &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) in &acnvar);%end;
          %let action=&action &&action&i;
      %end;
	  %let action=%unquote(&action);
 
	  %if %upcase(&disp_anyref_acn)=Y %then %do;
              %AE_CRIT(order = 180,
                       crit = %str(trtemfl="Y" and (&action)),
                       text = TEAE Leading to Dose Modification of Any Study Drug);
 
          %if &disp_ref_acn = Y %then %do;
             %do i = 1 %to &r_acn_cnt.;
                 %AE_CRIT(order = %eval(180+&i.),
                          crit = %str(trtemfl ="Y" and upcase(&&r_acn&i) in ("DOSE INCREASED" "DOSE REDUCED")),
                          text = TEAE Leading to Dose Modification of &&acn_refname&i.);
		     %end;
		  %end;
	  %end; %else %do;
          %if %length(&action)>0 %then %do;
             %AE_CRIT(order = 180,
                      crit = %str(trtemfl="Y" and (&action)),
                      text = TEAE Leading to Dose Modification of Study Drug);
		  %end; %else %do;
             %AE_CRIT(order = 180,
                     crit = %str(trtemfl="Y" and upcase(aacn1) in &acnvar),
                     text = TEAE Leading to Dose Modification of Study Drug);
		  %end;
	  %end;
   %end;
 
   %if &disp_mod_inter. = Y and &nobs > 0 %then %do;
   	  %let acnvar=%str(("DRUG INTERRUPTED" "DOSE INCREASED" "DOSE REDUCED"));
      %let action=;
      %do i = 1 %to &r_acn_cnt.;
	      %if 1<=&i < &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) in &acnvar or);%end;
	      %if &i = &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) in &acnvar);%end;
          %let action=&action &&action&i;
      %end;
	  %let action=%unquote(&action);
 
	  %if %upcase(&disp_anyref_acn)=Y %then %do;
           %AE_CRIT(order = 190,
                       crit = %str(trtemfl="Y" and (&action)),
                       text = TEAE Leading to Dose Modification or Interruption of Any Study Drug);
 
          %if &disp_ref_acn = Y %then %do;
             %do i = 1 %to &r_acn_cnt.;
                 %AE_CRIT(order = %eval(190+&i.),
                          crit = %str(trtemfl ="Y" and upcase(&&r_acn&i) in ("DRUG INTERRUPTED" "DOSE INCREASED" "DOSE REDUCED")),
                          text = TEAE Leading to Dose Modification or Interruption of &&acn_refname&i.);
		     %end;
		  %end;
	  %end; %else %do;
           %if %length(&action)>0 %then %do;
              %AE_CRIT(order = 190,
                   crit = %str(trtemfl="Y" and (&action)),
                   text = TEAE Leading to Dose Modification or Interruption of Study Drug);
		   %end; %else %do;
              %AE_CRIT(order = 190,
                   crit = %str(trtemfl="Y" and upcase(aacn1) in &acnvar),
                   text = TEAE Leading to Dose Modification or Interruption of Study Drug);
		   %end;
	  %end;
   %end;
 
   %if &disp_reduc. = Y and &nobs > 0 %then %do;
   	  %let acnvar=%str(("DOSE REDUCED"));
      %let action=;
      %do i = 1 %to &r_acn_cnt.;
	      %if 1<=&i < &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) = &acnvar or);%end;
	      %if &i = &r_acn_cnt. %then %do; %let action&i=%nrbquote(upcase(&&r_acn&i) = &acnvar);%end;
          %let action=&action &&action&i;
      %end;
	  %let action=%unquote(&action);
 
	  %if %upcase(&disp_anyref_acn)=Y %then %do;
              %AE_CRIT(order = 200,
                   crit = %str(trtemfl="Y" and (&action)),
                   text = TEAE Leading to Dose Reduction of Any Study Drug);
 
          %if &disp_ref_acn = Y %then %do;
             %do i = 1 %to &r_acn_cnt.;
                 %AE_CRIT(order = %eval(200+&i.),
                          crit = %str(trtemfl ="Y" and upcase(&&r_acn&i) in ("DOSE REDUCED")),
                          text = TEAE Leading to Dose Reduction of &&acn_refname&i.);
		     %end;
		  %end;
	  %end; %else %do;
	      %if %length(&action)>0 %then %do;
             %AE_CRIT(order = 200,
                      crit = %str(trtemfl="Y" and (&action)),
                      text = TEAE Leading to Dose Reduction of Study Drug);
          %end; %else %do;
             %AE_CRIT(order = 200,
                   crit = %str(trtemfl="Y" and upcase(aacn1) in &acnvar),
                   text = TEAE Leading to Dose Reduction of Study Drug);
		  %end;
	  %end;
   %end;
 
   ** Discontinuation of study;
   %if &disp_sdisc. = Y %then %do;
       %AE_CRIT(order = 205,
                crit = %str(trtemfl ="Y" and %nrquote(index(&other_acn,"DISCONTINUATION"))),
                text = TEAE Leading to Premature Discontinuation of Study);
   %end;
 
 /*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm(SMQ Processing)mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
 
   ** AESI;
   %if %length(&aesi_var.)>0 %then %do;
       %do i = 1 %to &aesi_var_cnt.;
           %AE_CRIT(order = %eval(210+&i.),
                    crit = %str(trtemfl ="Y" and strip(upcase(&&aesi_var&i.)) = strip(upcase("&&aesi_lbl&i."))),
                    text = %str(TEAE of Interest: &&aesi_lbl&i));
	   %end;
   %end;
 
    /*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
 
 
   ** AEIRR; /*crit = %str(aeirr = "Y")*/
   %if &disp_irr = Y %then %do;
       %AE_DTH_CRIT(order = 220,
	   				crit = %str(aeirr = "Y"),
                    text = TEAE Infusion-Related Reaction);
   %end;
 
   ** AEDLT: still use coulmn total as denominator to calculate percentage at this point);
   %if &disp_dlt = Y %then %do;
       %AE_DTH_CRIT(order = 221,
                    crit = %str(dltfl="Y" and &dlt_var = "Y"),
                    text = TEAE Dose-Limiting Toxicity);
   %end;
 
   ****************************************************************************;
   * Death                                                                    *;
   ****************************************************************************;
   %if &disp_dthfl. = Y %then %do;
       %AE_DTH_CRIT(order = 300,
                    crit = %str(dthfl = "Y"),
                    text = Death);
   %end;
 
   %if &disp_dth30fl. = Y %then %do;
      %AE_DTH_CRIT(order = 310,
                    crit = %str(dth30fl = "Y"),
                    text = Within 30 Days of Last Dose);
      %AE_DTH_CRIT(order = 320,
                    crit = %str(dthg30fl = "Y"),
                    text = After 30 Days of Last Dose);
   %end;
 
   %if &disp_lead2dth. = Y %then %do;
      %AE_DTH_CRIT(order = 330,
                    crit = %str(trtemfl ="Y" and dthfl eq "Y" and (aesdth eq "Y" or upcase(aeout) eq "FATAL")),
                    text = TEAE Leading to Death);
   %end;
 
   %if &disp_reldth. = Y %then %do;
       %if &disp_anyref_reldth. = Y %then %do;
          %AE_DTH_CRIT(order = 340,
                       crit = %str(trtemfl ="Y" and dthfl eq "Y" and (aesdth eq "Y" or upcase(aeout) eq "FATAL") and upcase(arel) = "RELATED"),
                       text = TEAE Related to Any Study Drug Leading to Death);
       %end; %else %do;
          %AE_DTH_CRIT(order = 340,
                       crit = %str(trtemfl ="Y" and dthfl eq "Y" and (aesdth eq "Y" or upcase(aeout) eq "FATAL") and upcase(arel) = "RELATED"),
                       text = TEAE Related to Study Drug Leading to Death);
	   %end;
	
	   %if &disp_ref_reldth. = Y %then %do;
          %do i = 1 %to &r_rel_cnt.;
              %AE_DTH_CRIT(order = %eval(340+&i.),
                           crit = %str(trtemfl ="Y" and dthfl eq "Y" and (aesdth eq "Y" or upcase(aeout) eq "FATAL") and upcase(&&r_rel&i.) = "RELATED"),
                           text = TEAE Related to &&refname&i Leading to Death);
	      %end;
       %end;
   %end;
 
   %if &disp_tedthfl. = Y %then %do;
      %AE_DTH_CRIT(order = 350,
                    crit = %str(tedthfl eq "Y"),
                    text = TE Death);
   %end;
 
   ****************************************************************************;
   * Non-TEAE Prior to First Dose of Study Drug                               *;
   ****************************************************************************;
   %if &prefl. = Y %then %do;
      %AE_CRIT(order = 360,
                crit = %str(prefl eq "Y"),
                text = Non-TEAE Prior to First Dose of Study Drug);
   %end;
 
   data aebrief;
      set temp_:;
      format yn yn. &colvar &trt_fmt..;
   run;
 
   data aebrief;
       set aebrief;
       cat_orig=cat;
       %if &disp_g2=O or &disp_g3=O %then %do;
            if text='TEAE Leading to Death' then cat=3.99;
       %end;
       %if &disp_refg2=O or &disp_refg3=O %then %do;
            if index(text,'Leading to Death') then do;
                %if &disp_anyref=Y %then %do;
                    if substr(text,1,30)='TEAE Related to Any Study Drug' then cat=49+(cat*0.001);
                %end;
                %else %do;
                    if substr(text,1,30)='TEAE Related to Any Study Drug' then cat=cat;
                %end;
                else if substr(text,1,26)='TEAE Related to Study Drug' then cat=49+(cat*0.001);
                else if substr(text,1,15)='TEAE Related to' then cat=49+(cat*0.001);
            end;
       %end;
   run;
 
   proc sort data=aebrief(keep=cat_orig cat text) out=cattext nodupkey;
        by cat cat_orig text;
   run;
 
   data _null_;
      set cattext;
      if cat ne cat_orig then put 'NOTE: Leading to Death reorder ' text;
   run;
 
   ****************************************************************************;
   * Check for 0 observations                                                 *;
   ****************************************************************************;
   %nobs(&dsin._1); %let nobs_adsl=&nobs; %put nobs_adsl= &nobs_adsl;
   %NOBS(aebrief);
 
   ****************************************************************************;
   * 3. OUTPUT TO FINAL REPORT                                                *;
   ****************************************************************************;
   %if &nobs_adsl. > 0 and &nobs. > 0 %then %do;
      %TABDESC(analfile = aebrief,
                 colvar = &colvar,
                  ptvar = &subjid,
                statlen = &statlen,
                   col2 = &col1width,
                spacing = &spacing,
                col1hdr =%str(Number (%%) of &study_subject_text.s with),
               undrline = Y,
                ocprint = &ocprint,
                pvalpat = &pvalpat,
               opgroups = &opgroups);
 
 
      %TABCOUNT(sortord  = 0,
                     var = cat text yn,
                     dec = 1 ,
                    stat = N PCT,
                  sortby = I,
                 showall = Y);
 
 
      data combine;
         set combine;
         where yn eq 1;
         sortord = cat;
         level = 1; ** otherwise the table will become 3 levels: cat*text*yn;
         label1 = ' ';
         linlabel = text;
      run;
 
	  %if %upcase(&disp_dlt) = Y %then %do; /* If DISP_DLT = Y, then the program dynamically checks/uses ADSL.DLTFL as the denominator for percentage calculations.*/
	  	 data combine(drop=i len count pct statval);
		    set combine;
            %do i=1 %to %eval(&__mtrt+1);
                dltcnt&i=&&dltcnt_&i;
			%end;
 
			if text="TEAE Dose-Limiting Toxicity" then do;
			    array values value1--value&_maxcol;
				array denoms dltcnt1--dltcnt&_maxcol;
				do i = 1 to &_maxcol;
                   count=input(scan(values[i], 1, '('), best.);
				   denom=denoms[i];
				   if denoms[i]^=0 then pct=(count/denom)*100;
				   statval = put(count, &_statlen.. );
				   len = length(statval);
                   if pct>0 then values[i]=substr(statval,1,len) || " (" || put(pct,5.1) || "%)";
				   else values[i]=substr(statval,1,len);
				end;
				pvalc1="--"; pvalc2="--";
			end;
		  run;
	  %end;
 
      %TABPREP(titlekey = &titlekey., outname = &titlekey.,
               spanhdr = &spanhdr., spanrang = &spanrang.);
 
      data summary vdata.%sysfunc(translate(&titlekey.,'_','-.'));
         set summary ;
         where type ne ' '; ** remove extra row by CAT;
         if level = 1 then linlabel = strip(text);
         if type eq '' then delete;
      run;
 
      ** Count number of characters for pval_header for each line **;
      data _null_;
         %let _ii_=1;
         %do %while(%nrbquote(%scan(&pval_header,&_ii_,"~"))^=);
            var&_ii_="%scan(&pval_header,&_ii_,"~")";
            len&_ii_=length(var&_ii_);
            %let _ii_=%eval(&_ii_+1);
         %end;
         mx_len=max(of len1-len%eval(&_ii_-1));
         call symput("mx_len",strip(put(mx_len,best.)));
      run;
 
      %let m_pr_pv1=&pval_header;
      %let m_prw_pv=%eval(&mx_len+1);
      %TABDRPT(cwidth = &cwidth.);
 
      %TABDRPT(cwidth = &cwidth);
   %end;
   %else %do;
      data final vdata.%sysfunc(translate(&titlekey.,'_','-.'));
         length noevent $ 200;
         noevent = "No %lowcase(&study_subject_text.) met this condition.";
      run;
 
         %PRINTSET(outname= &titlekey., titlekey = &titlekey., foot_nodata=Y);
 
         proc report data = final headline headskip split='~ ' missing spacing = 1;
         column ('___' '   ' noevent );
         define noevent / display   width = 149 ' ' center flow;
      run;
 
      %PAGESET(outname = &titlekey.);
   %end;
	
   %if &cleanup=Y %then %do;
      proc datasets library = work
                    nolist
                    memtype = data
                    kill;
         run;
      quit;
   %end;
 
%mend mk_t_s_aebrief;
 
%mk_t_s_aebrief(
   subjid=subjid,
   statlen=3,
   titlekey=t-s-aebrief,
   lib=adamdata,
   dsin=adsl,
   tmacro= ,
   colvar=trt01an,
   trt_fmt=trtfmt,
   pop_flag=saffl,
   where_cl_pop= ,
   keep_adsl= ,
   aedsin=adae,
   tmacroae= ,
   where_cl_data=(where=(trtemfl = 'Y')),
   sev_grd_sys=Y,
   disp_g3=Y,
   disp_g2=Y,
   maxsev= ,
   disp_ref=N,
   num_ref= ,
   ref_name= ,
   rel_ref= ,
   disp_anyref=N,
   disp_refg2=N,
   disp_refg3=N,
   maxsev_anyrel= ,
   maxsev_rel= ,
   disp_sdisc=Y,
   disp_inter=Y,
   disp_mod=N,
   disp_mod_inter=N,
   disp_reduc=Y,
   disp_ref_acn=N,
   acn_ref_name= ,
   acn_ref= ,
   disp_anyref_acn=N,
   disp_sproc=N,
   aesi_var= ,
   aesi_lbl= ,
   disp_irr=N,
   disp_dlt=N,
   dlt_var= ,
   disp_dthfl=N,
   disp_dth30fl=N,
   disp_lead2dth=Y,
   disp_reldth=N,
   disp_ref_reldth=N,
   disp_anyref_reldth=N,
   disp_tedthfl=N,
   other_acn=aeacnoth,
   prefl=N,
   ocprint=Y,
   pvalpat= ,
   opgroups= ,
   pval_header=P Value,
   col1width=50,
   spacing=3,
   spanhdr= ,
   spanrang= ,
   cwidth= ,
   cleanup=Y
   );
 
