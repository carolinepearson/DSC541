/* start of header *********************************************************************************
Program Name:      t-s-demog.sas
Program Author:    Caroline Pearson (cpearson1)
Program Purpose:   Create Standard Demographics Table
 
*********************************************************************************** end of header */
 
%macro mk_t_s_demog(subjid=,
                   statlen=,
                  titlekey=,
                       lib=,
                      dsin=,
                  pop_flag=,
              where_cl_pop=,
                    tmacro=,
                    colvar=,
                   trt_fmt=,
                       age=,
                      ageu=,
                   age_grp=,
                  age_grpf=,
                   notperm=,
                   misspct=,
                     d_bwt=,
                  d_bwtsex=,
                     d_bht=,
                  d_bhtsex=,
                    d_bbmi=,
                 d_bbmisex=,
                    d_bbsa=,
                 d_bbsasex=,
				    d_genident=,
                 d_sexorie=,
                   bmi_grp=,
                  bmi_grpf=,
                    region=,
                   regionf=,
                   ocprint=,
                   showall=,
                  pvalcont=,
                   pvalcat=,
                  opgroups=,
                  misspval=,
                  nomisspc=,
			      pval_header=,
                 col1width=,
                    cwidth=,
                   spacing=,
                   spanhdr=,
                  spanrang=,
                   cleanup=);
 
   options missing='';
 
   %** upcase certain parameters and only keep certain number of characters for each parameter, if needed **;
   %m_stars_upcase(varlist=misspct~1 d_bwt~1 d_bwtsex~1 d_bht~1 d_bhtsex~1 d_bbmi~1 d_bbmisex~1 d_bbsa~1 d_bbsasex~1 d_genident~1 d_sexorie~1 ocprint~1
                   showall~1 misspval~1 nomisspc~1 cleanup~1);
 
   %** initialize msgcnt for checks below and to be used in m_stars_chk_keyparms **;
   %let msgcnt=0;
 
   %if &nomisspc = N and %nrbquote(&notperm)^= %then %do;
      %let msgcnt=%eval(&msgcnt+1);
      %let msg&msgcnt=NOTPERM must be NULL if NOMISSPC is set to N.;
   %end;
 
   %if &misspval = Y and %nrbquote(&notperm)^= %then %do;
      %let msgcnt=%eval(&msgcnt+1);
      %let msg&msgcnt=NOTPERM must be NULL if MISSPVAL is set to Y.;
   %end;
 
   %** will create message to log if any of these parameters are not populated **;
   %m_stars_chk_keyparms (parameters=pop_flag colvar trt_fmt);
 
   %** ERRFLAG is created in M_STARS_CHK_KEYPARMS **;
   %if &errflag gt 0 %then %goto endprogram;
 
   ****************************************************************************;
   * AGE_GRP and AGE_GRPF processing                                         *;
   ****************************************************************************;
   %if %length(&age_grp.)>0 %then %do;
      %do i = 1 %to %eval(%sysfunc(countw(&age_grp%str( ))));
          %let age_grp_cnt = %eval(%sysfunc(countw(&age_grp%str( ))));
          %let age_grp&i. = %qscan(&age_grp, &i, %str( ));
 
         %if %nrbquote(&age_grpf.) ne %then %do;
            %let age_grpf_cnt = %eval(%sysfunc(countw(&age_grpf%str( ))));
            *******************************************************************;
            * Confirm that number of age_grpf matches age_grp                *;
            *******************************************************************;
            %if &age_grp_cnt. = &age_grpf_cnt. %then %do;
               %let age_grpf&i. = %qscan(&age_grpf, &i, %str( ));
            %end;
            %else %do;
               data _null_;
                  put "ERR" "OR: [USER] Number of age_grpf must match number of age_grp variables";
                  abort abend;
               run;
            %end;
         %end;
	  %end;
   %end; %else %do;
      %let age_grp_cnt = 0;
      %let age_grpf_cnt = 0;
   %end;
 
   ****************************************************************************;
   * BMI_GRP and BMI_GRPF processing                                         *;
   ****************************************************************************;
   %if %length(&bmi_grp.)>0 %then %do;
      %do i = 1 %to %eval(%sysfunc(countw(&bmi_grp%str( ))));
          %let bmi_grp_cnt = %eval(%sysfunc(countw(&bmi_grp%str( ))));
          %let bmi_grp&i. = %qscan(&bmi_grp, &i, %str( ));
 
         %if %nrbquote(&bmi_grpf.) ne %then %do;
            %let bmi_grpf_cnt = %eval(%sysfunc(countw(&bmi_grpf%str( ))));
            *******************************************************************;
            * Confirm that number of bmi_grpf matches bmi_grp                *;
            *******************************************************************;
            %if &bmi_grp_cnt. = &bmi_grpf_cnt. %then %do;
               %let bmi_grpf&i. = %qscan(&bmi_grpf, &i, %str( ));
            %end;
            %else %do;
               data _null_;
                  put "ERR" "OR: [USER] Number of bmi_grpf must match number of bmi_grp variables";
                  abort abend;
               run;
            %end;
         %end;
	  %end;
   %end; %else %do;
      %let bmi_grp_cnt = 0;
      %let bmi_grpf_cnt = 0;
   %end;
 
   ****************************************************************************;
   * REGION and REGIONF processing                                         *;
   ****************************************************************************;
   %if %length(&region.)>0 %then %do;
      %do i = 1 %to %eval(%sysfunc(countw(&region%str( ))));
          %let region_cnt = %eval(%sysfunc(countw(&region%str( ))));
          %let region&i. = %qscan(&region, &i, %str( ));
 
         %if %nrbquote(&regionf.) ne %then %do;
            %let regionf_cnt = %eval(%sysfunc(countw(&regionf%str( ))));
            *******************************************************************;
            * Confirm that number of regionf matches region                *;
            *******************************************************************;
            %if &region_cnt. = &regionf_cnt. %then %do;
               %let regionf&i. = %qscan(&regionf, &i, %str( ));
            %end;
            %else %do;
               data _null_;
                  put "ERR" "OR: [USER] Number of regionf must match number of region variables";
                  abort abend;
               run;
            %end;
         %end;
	  %end;
   %end; %else %do;
      %let region_cnt = 0;
      %let regionf_cnt = 0;
   %end;
 
   /************************************/
   /*** Process source data ***/
   /************************************/
   %fetch(library = &lib,
             data = &dsin,
              out = _&dsin._,
          dataopt = where=(&pop_flag = 'Y' ),
          sortby  = &subjid);
 
 
   %if %str(&tmacro) ^= %str() and %upcase(&tmacro)^=NULL %then %do;
       %&tmacro(data=_&dsin._);
    %end;
 
   *** Check existence of BBSA in ADSL;
   %if %upcase(&d_bbsa) = Y or %upcase(&d_bbsasex) = Y %then %do;
      %M_CHKVAR(var = bbsa,  inds = _&dsin._,  libnm = work, abort=y);
      %let chk_bbsa=&m_chkvar;
      /*
      %if &chk_bbsa=0 %then %do;
         data _null_;
            put "ERR" "OR: [USER] d_bbsa=Y or d_bbsasex=Y but BBSA does not exist in %upcase(&dsin)";
            abort abend;
         run;
       %end;
       */
   %end;
 
   data adsl;
      set _&dsin._ &where_cl_pop;
      *************************************************************************;
      * Create numeric var versions to control output order                   *;
      *************************************************************************;
      racen = input(upcase(race), fracec.);
      sexn = input(upcase(sex), fsexc.);
      ethnicn = input(upcase(ethnic), fethnicc.);
      *************************************************************************;
      * E rror check vars                                                     *;
      *************************************************************************;
      if min(racen)   < 1 then put "User W" "arning: in" "valid Race variable value, race = " race;
      if min(sexn)    < 1 then put "User W" "arning: in" "valid Sex variable value, sex = "  sex;
      if min(ethnicn) < 1 then put "User W" "arning: in" "valid Ethnic variable value, ethnic = " ethnic;
      %if %nrbquote(&notperm)^= %then %do;
      racen2 = racen;
      ethnicn2 = ethnicn;
         %let _ii_ = 1;
         %do %while(%nrbquote(%scan(&notperm,&_ii_,"|"))^=);
            if upcase(race)="%upcase(%scan(&notperm,&_ii_,"|"))" then racen2=.;
            if upcase(ethnic)="%upcase(%scan(&notperm,&_ii_,"|"))" then ethnicn2=.;
            %let _ii_=%eval(&_ii_+1);
         %end;
      %end;
      %if %upcase(&d_bwtsex.) = Y %then %do;
         if      sexn = 1 then bwt_m = bwt;
         else if sexn = 2 then bwt_f = bwt;
      %end;
      %if %upcase(&d_bhtsex.) = Y %then %do;
         if      sexn = 1 then bht_m = bht;
         else if sexn = 2 then bht_f = bht;
      %end;
      %if %upcase(&d_bbmisex.) = Y %then %do;
         if      sexn = 1 then bbmi_m = bbmi;
         else if sexn = 2 then bbmi_f = bbmi;
      %end;
      %if %upcase(&d_bbsasex.) = Y %then %do;
         if      sexn = 1 then bbsa_m = bbsa;
         else if sexn = 2 then bbsa_f = bbsa;
      %end;
      *************************************************************************;
      * Set labels dynamically for age in case different age units are used   *;
      *************************************************************************;
      age_l = 'Age (' || compress(lowcase(&ageu) || ')');
      call symput('age_l', trim(age_l));
      format
            sexn fsexn.
           racen fracen.
         ethnicn fethnicn.
         &colvar &trt_fmt..
      %if %nrbquote(&notperm)^= %then %do;
          racen2 fracen. ethnicn2 fethnicn.
      %end;
	  %if %upcase(&d_genident.) = Y %then %do;
          genidentn genidentn.
	  %end;
 
      %if %upcase(&d_sexorie.) = Y %then %do;
          sexorien sexorn.
	  %end;
      ;
 
      %if %nrbquote(&age_grp)^= %then %do;
         %let _ii_=1;
         %do %while(%scan(&age_grp,&_ii_," ")^=);
            format %scan(&age_grp,&_ii_," ") %scan(&age_grpf,&_ii_," ").;
            %let _ii_=%eval(&_ii_+1);
         %end;
      %end;
 
      %if %nrbquote(&bmi_grp)^= %then %do;
         %let _ii_=1;
         %do %while(%scan(&bmi_grp,&_ii_," ")^=);
            format %scan(&bmi_grp,&_ii_," ") %scan(&bmi_grpf,&_ii_," ").;
            %let _ii_=%eval(&_ii_+1);
         %end;
      %end;
 
      %if %nrbquote(&region)^= %then %do;
         %let _ii_=1;
         %do %while(%scan(&region,&_ii_," ")^=);
            format %scan(&region,&_ii_," ") %scan(&regionf,&_ii_," ").;
            %let _ii_=%eval(&_ii_+1);
         %end;
      %end;
   run;
 
   data final;
      set adsl;
      label &age    = "&age_l."
           sexn    = "Sex at Birth"
           racen   = "Race"
           ethnicn = "Ethnicity"
           %if %nrbquote(&notperm)^= %then %do;
              racen2  = "Race"
              ethnicn2= "Ethnicity"
           %end;
           %if %upcase(&d_bwt.) = Y %then %do;
              bwt      = "Weight (kg)"
           %end;
           %if %upcase(&d_bwtsex.) = Y %then %do;
              bwt_m = "Weight (kg): Male"
              bwt_f = "Weight (kg): Female"
           %end;
            %if %upcase(&d_bht.) = Y %then %do;
              bht      = "Height (cm)"
           %end;
           %if %upcase(&d_bhtsex.) = Y %then %do;
              bht_m = "Height (cm): Male"
              bht_f = "Height (cm): Female"
           %end;
           %if %upcase(&d_bbmi.) = Y %then %do;
              bbmi   = "Body Mass Index (kg/m^2)"
           %end;
           %if %upcase(&d_bbmisex.) = Y %then %do;
              bbmi_m = "Body Mass Index (kg/m^2): Male"
              bbmi_f = "Body Mass Index (kg/m^2): Female"
           %end;
           %if %upcase(&d_bbsa. = Y) %then %do;
              bbsa   = "Body Surface Area (m^2)"
           %end;
           %if %upcase(&d_bbsasex.) = Y %then %do;
              bbsa_m = "Body Surface Area (m^2): Male"
              bbsa_f = "Body Surface Area (m^2): Female"
           %end;
	       %if %upcase(&d_genident.) = Y %then %do;
               genidentn = "Gender Identity"
	       %end;
           %if %upcase(&d_sexorie.) = Y %then %do;
              sexorien = "Sexual Orientation"
	       %end;
           %if %nrbquote(&age_grp)^= %then %do;
              %let _ii_=1;
              %do %while(%scan(&age_grp,&_ii_," ")^=);
                 %if &_ii_=1 %then %do;
                    %scan(&age_grp,&_ii_," ")="Age Group"
                 %end;
                 %else %do;
                    %scan(&age_grp,&_ii_," ")=" "
                 %end;
                 %let _ii_=%eval(&_ii_+1);
              %end;
           %end;
           %if %nrbquote(&bmi_grp)^= %then %do;
              %let _ii_=1;
              %do %while(%scan(&bmi_grp,&_ii_," ")^=);
                 %if &_ii_=1 %then %do;
                    %scan(&bmi_grp,&_ii_," ")="Body Mass Index Group"
                 %end;
                 %else %do;
                    %scan(&bmi_grp,&_ii_," ")=" "
                 %end;
                 %let _ii_=%eval(&_ii_+1);
              %end;
           %end;
           %if %nrbquote(&region)^= %then %do;
              %let _ii_=1;
              %do %while(%scan(&region,&_ii_," ")^=);
                 %if &_ii_=1 %then %do;
                    %scan(&region,&_ii_," ")="Region"
                 %end;
                 %else %do;
                    %scan(&region,&_ii_," ")=" "
                 %end;
                 %let _ii_=%eval(&_ii_+1);
              %end;
           %end;
 
      ;
   run;
 
   ****************************************************************************;
   * Determine total number of trt groups to appear across table to find best *;
   * col2 width.                                                              *;
   * Add one to account for total col if &OCPRINT = Y                         *;
   ****************************************************************************;
   proc sql noprint;
      select count(distinct(&colvar.)) into: totcol
      from final;
   quit;
 
   %let totcol = %cmpres(&totcol.);
   %if &ocprint. = Y %then %let totcol = %cmpres(%eval(&totcol. + 1));
   %let totvar = %cmpres(value&totcol.);
   *%put totvar = &totvar;
 
   ****************************************************************************;
   *                       CREATE OUTPUT REPORT                               *;
   ****************************************************************************;
   %tabdesc(analfile = final,
               ptvar = &subjid,
             statlen = &statlen,
              colvar = &colvar,
             opvalue = Y,
             ocprint = &ocprint,
                col2 = &col1width,
             spacing = &spacing,
            pvalcont = &pvalcont,
             pvalcat = &pvalcat,
            opgroups = &opgroups);
 
   *** OUTPUT REPORT VARIABLES ****;
   %tabdcont( sortord = 1,
                  var = &age,
              meandec = 0,
                sddec = 1,
               meddec = 0,
               qrtdec = 0,
             rangedec = 0);
 
   %if %nrbquote(&age_grp)^= %then %do;
      %let _ii_=1;
      %do %while(%scan(&age_grp,&_ii_," ")^=);
         %tabdcat(sortord = 1.&_ii_,
                      var = %scan(&age_grp,&_ii_," "),
                  misspct = &misspct,
                 misspval = &misspval,
                 nomisspc = &nomisspc,
                     stat = N PCT,
                  showall = &showall);
         %let _ii_=%eval(&_ii_+1);
      %end;
   %end;
 
   %tabdcat(sortord = 2,
                var = sexn,
            misspct = &misspct,
           misspval = &misspval,
           nomisspc = &nomisspc,
               stat = N PCT,
            showall = &showall);
 
   %if %upcase(&d_genident.) = Y %then %do;
      %tabdcat(sortord = 2.3,
                var = genidentn,
            misspct = &misspct,
           misspval = &misspval,
           nomisspc = &nomisspc,
               stat = N PCT,
            showall = &showall);
	%end;
 
   %if %upcase(&d_sexorie.) = Y %then %do;
       %tabdcat(sortord = 2.6,
                var = sexorien,
            misspct = &misspct,
           misspval = &misspval,
           nomisspc = &nomisspc,
               stat = N PCT,
            showall = &showall);
   %end;
 
   %tabdcat(sortord = 3,
                var = racen,
            misspct = &misspct,
           misspval = &misspval,
           nomisspc = &nomisspc,
           %if %nrbquote(&notperm)^= %then %do;
               stat = N,
           %end;
           %else %do;
               stat = N PCT,
           %end;
            showall = &showall);
 
   %tabdcat(sortord = 4,
                var = ethnicn,
            misspct = &misspct,
           misspval = &misspval,
           nomisspc = &nomisspc,
           %if %nrbquote(&notperm)^= %then %do;
               stat = N,
           %end;
           %else %do;
               stat = N PCT,
           %end;
            showall = &showall);
 
   %if %upcase(&d_bwt.) = Y %then %do;
      %TABDCONT(sortord = 5, var = bwt, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
      %if &d_bwtsex. = Y %then %do;
         %TABDCONT(sortord = 6, var = bwt_m, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
         %TABDCONT(sortord = 7, var = bwt_f, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
      %end;
   %end;
 
   %if %upcase(&d_bht.) = Y %then %do;
      %TABDCONT(sortord = 8, var = bht, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
      %if &d_bhtsex. = Y %then %do;
         %TABDCONT(sortord = 9, var = bht_m, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
         %TABDCONT(sortord = 10, var = bht_f, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
      %end;
   %end;
 
   %if %upcase(&d_bbmi.) = Y %then %do;
      %TABDCONT(sortord = 11, var = bbmi, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
      %if &d_bbmisex. = Y %then %do;
         %TABDCONT(sortord = 12, var = bbmi_m, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
         %TABDCONT(sortord = 13, var = bbmi_f, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
      %end;
   %end;
 
   %if %nrbquote(&bmi_grp)^= %then %do;
      %let _ii_=1;
      %do %while(%scan(&bmi_grp,&_ii_," ")^=);
         %tabdcat(sortord = 11.&_ii_,
                      var = %scan(&bmi_grp,&_ii_," "),
                  misspct = &misspct,
                 misspval = &misspval,
                 nomisspc = &nomisspc,
                     stat = N PCT,
                  showall = &showall);
         %let _ii_=%eval(&_ii_+1);
      %end;
   %end;
 
   %if %upcase(&d_bbsa.) = Y %then %do;
      %TABDCONT(sortord = 14, var = bbsa, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
      %if &d_bbsasex. = Y %then %do;
         %TABDCONT(sortord = 15, var = bbsa_m, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
         %TABDCONT(sortord = 16, var = bbsa_f, meandec = 1, sddec = 2, meddec  = 1, qrtdec = 1, rangedec = 1);
      %end;
   %end;
 
   %if %nrbquote(&region)^= %then %do;
      %let _ii_=1;
      %do %while(%scan(&region,&_ii_," ")^=);
         %tabdcat(sortord = 20.&_ii_,
                      var = %scan(&region,&_ii_," "),
                  misspct = &misspct,
                 misspval = &misspval,
                 nomisspc = &nomisspc,
                     stat = N PCT,
                  showall = &showall);
         %let _ii_=%eval(&_ii_+1);
      %end;
   %end;
 
   %if %nrbquote(&notperm)^= %then %do;
      data combine1;
         set combine;
         if sortord in (3,4) then do;
           call missing(pval1, pval2, pvalc1, pvalc2);
         end;
      run;
 
      *************************************************************************;
      *                        CREATE OUTPUT REPORT                           *;
      *************************************************************************;
      %tabdesc( analfile = final,
                   ptvar = &subjid,
                 statlen = &statlen,
                  colvar = &colvar,
                 opvalue = Y,
                 ocprint = &ocprint,
                    col2 = &col1width,
                 spacing = &spacing,
                pvalcont = &pvalcont,
                 pvalcat = &pvalcat);
 
      %tabdcat( sortord = 3,
                    var = racen2,
                misspct = N,
               misspval = N,
               nomisspc = Y,
                   stat = N PCT,
                showall = N);
 
      %tabdcat( sortord = 4,
                    var = ethnicn2,
                misspct = N,
               misspval = N,
               nomisspc = Y,
                   stat = N PCT,
                showall = N);
 
      proc sort data = combine;
        by sortord statord;
      run;
 
      proc sort data = combine1;
        by sortord statord;
      run;
 
      data pval(keep = sortord pval:);
         set combine;
         by sortord;
         if last.sortord;
      run;
 
      data combine;
         merge
            combine1
            combine;
         by sortord statord;
      run;
 
      data combine;
         merge
            combine
            pval;
         by sortord;
      run;
   %end;
 
   %tabprep(titlekey= &titlekey,
            outname = &titlekey,
            spanhdr = &spanhdr,
           spanrang = &spanrang);
 
   data summary vdata.%sysfunc(tranwrd(&titlekey, -, _));
      set summary;
      allmiss = compress(cats(of value1-&totvar.),'0');
      if allmiss = '' and  compress(upcase(linlabel)) = '-MISSING-' then delete; *remove all 0 _Missing_ rows;
   run;
 
   %if %length(&pvalcont)>0 or %length(&pvalcat)>0 %then %do;
      ** count number of characters for pval_header for each line **;
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
   %end;
 
   %tabdrpt(cwidth = &cwidth.);
 
   %if &cleanup=Y %then %do;
      proc datasets library = work
                    nolist
                    memtype = data
                    kill;
         run;
      quit;
   %end;
 
   %endprogram:
 
%mend mk_t_s_demog;
 
%mk_t_s_demog(
   subjid=subjid,
   statlen=3,
   titlekey=t-s-demog,
   lib=adamdata,
   dsin=adsl,
   pop_flag=ittfl,
   where_cl_pop= ,
   tmacro= ,
   colvar=trt01pn,
   trt_fmt=trtfmt,
   age=age,
   ageu=ageu,
   age_grp=agegr1n,
   age_grpf=agegrfmt,
   notperm= ,
   misspct=N,
   d_bwt=Y,
   d_bwtsex=N,
   d_bht=Y,
   d_bhtsex=N,
   d_bbmi=Y,
   d_bbmisex=N,
   d_bbsa=N,
   d_bbsasex=N,
   d_genident=N,
   d_sexorie=N,
   bmi_grp= ,
   bmi_grpf= ,
   region= ,
   regionf= ,
   ocprint=Y,
   showall=N,
   pvalcont= ,
   pvalcat= ,
   opgroups= ,
   misspval=N,
   nomisspc=N,
   pval_header=P Value,
   col1width=50,
   cwidth= ,
   spacing=3,
   spanhdr= ,
   spanrang= ,
   cleanup=Y
   );
 
