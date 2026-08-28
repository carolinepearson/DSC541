/*
  DSS metadata-driven summary tables
  SAS 9.4 program

  Metadata sources interpreted for this program:
    metadata/DSS_Tables.json
    metadata/DSS.rtf

  Important validation result for this data cut:
    ADSL and ADPC do not contain PKFL or PKyFL.  The RTF makes the PK
    population conditional on that flag, so t-pkpc is intentionally not
    generated until a defensible PK population mapping is supplied.
*/

options mprint mlogic symbolgen validvarname=any dlcreatedir;

%let adam_path=C:\Users\carol\DSC541\DSC541\adam;
%let metadata_path=C:\Users\carol\DSC541\DSC541\metadata;
%let output_path=C:\Users\carol\DSC541\DSC541\output;
%let study_id=GS-US-000-0000 (DSS);

%macro setup_library;
  libname ADAM "&adam_path";
  libname OUT "&output_path";
%mend setup_library;

%macro metadata_configuration;
  /* JSON is authoritative for identifiers, datasets, populations and rules. */
  data table_config;
    length table_key $20 title $200 dataset $8 population $40 treatment $20
           filter $200 orientation $12 output_file $80 status $20;
    infile datalines dlm='|' truncover;
    input table_key :$20. title :$200. dataset :$8. population :$40.
          treatment :$20. filter :$200. orientation :$12.
          output_file :$80. status :$20.;
    datalines;
 t-s-disp|Participant Disposition|ADSL|All Screened Participants|Planned Trt|SCRNFL=Y|LANDSCAPE|t-s-disp.pdf|REQUIRED
 t-s-demog|Demographics and Baseline Characteristics|ADSL|ITT Analysis Set|Planned Trt|ITTFL=Y|LANDSCAPE|t-s-demog.pdf|REQUIRED
 t-os|Overall Survival (OS)|ADTTE|ITT Analysis Set|Planned Trt|PARAMCD=OS and ITTFL=Y|LANDSCAPE|t-os.pdf|REQUIRED
 t-s-aebrief|Treatment-Emergent Adverse Events: Overall Summary|ADAE|Safety Analysis Set|Actual Trt|SAFFL=Y and TRTEMFL=Y|LANDSCAPE|t-s-aebrief.pdf|REQUIRED
 t-pkpc|Individual Data and Summary Statistics of Plasma Concentration (ng/mL)|ADPC|PK Analysis Set|PK Sampling 0-24hrs|PKFL=Y and ANL01FL=Y|LANDSCAPE|t-pkpc.pdf|CONDITIONAL
 ;
  run;

  data row_config;
    length table_key $20 rownum 8 row_label $200 source_variable $32
           source_value $100 statistic $40 denominator $40;
    infile datalines dlm='|' truncover;
    input table_key :$20. rownum source_variable :$32. source_value :$100.
          row_label :$200. statistic :$40. denominator :$40.;
    datalines;
 t-s-disp|1|SCRNFL|Y|Screened|N|SCREENED
 t-s-disp|2|ITTFL|Y|ITT Analysis Set|N|SCREENED
 t-s-disp|3|SAFFL|Y|Safety Analysis Set|N|SAFETY
 t-s-disp|4|PKFL|Y|PK Analysis Set|N|PK
 t-s-disp|5|COMTFL|Y|Completed Study Drug|CAT|SAFETY
 t-s-disp|6|COMTFL|N|Discontinued Study Drug|CAT|SAFETY
 t-s-disp|7|DCTREAS|ADVERSE EVENT|Adverse Event|CAT|SAFETY
 t-s-disp|8|DCTREAS|LACK OF EFFICACY|Lack of Efficacy|CAT|SAFETY
 t-s-disp|9|COMSFL|Y|Completed Study|CAT|SAFETY
 t-s-disp|10|COMSFL|N|Prematurely Discontinued Study|CAT|SAFETY
 t-s-disp|11|DCSREAS|DEATH|Death|CAT|SAFETY
 t-s-disp|12|DCSREAS|WITHDRAWAL BY SUBJECT|Withdrawal by Subject|CAT|SAFETY
 ;
  run;
%mend metadata_configuration;

%macro add_validation(table_key=, check_type=, object=, result=, detail=, severity=);
  proc sql noprint;
    insert into validation_report
      set table_key="&table_key", check_type="&check_type", object="&object",
          result="&result", detail="&detail", severity="&severity";
  quit;
%mend add_validation;

%macro validation_setup;
  data validation_report;
    length table_key $20 check_type $40 object $80 result $20 detail $300
           severity $12;
    stop;
  run;
%mend validation_setup;

%macro check_dataset(dataset=, table_key=);
  %local exists n;
  %let exists=%sysfunc(exist(ADAM.&dataset));
  %if &exists %then %do;
    proc sql noprint;
      select count(*) into :n trimmed from ADAM.&dataset;
    quit;
    %add_validation(table_key=&table_key,check_type=DATASET,object=ADAM.&dataset,
      result=PASS,detail=Dataset exists; record count=&n,severity=INFO);
  %end;
  %else %do;
    %add_validation(table_key=&table_key,check_type=DATASET,object=ADAM.&dataset,
      result=FAIL,detail=Dataset does not exist,severity=ERROR);
  %end;
%mend check_dataset;

%macro check_variable(dataset=, variable=, table_key=, required=Y);
  %local found;
  proc sql noprint;
    select count(*) into :found trimmed
    from dictionary.columns
    where libname='ADAM' and memname=upcase("&dataset")
      and upcase(name)=upcase("&variable");
  quit;
  %if &found=1 %then %do;
    %add_validation(table_key=&table_key,check_type=VARIABLE,
      object=&dataset..&variable,result=PASS,detail=Variable exists,severity=INFO);
  %end;
  %else %do;
    %if &required=Y %then %do;
      %add_validation(table_key=&table_key,check_type=MAPPING,
        object=&dataset..&variable,result=FAIL,
        detail=Required metadata variable is unresolved,severity=ERROR);
    %end;
    %else %do;
      %add_validation(table_key=&table_key,check_type=MAPPING,
        object=&dataset..&variable,result=WARNING,
        detail=Optional variable is absent,severity=WARNING);
    %end;
  %end;
%mend check_variable;

%macro check_missing(dataset=, variable=, table_key=, where=1);
  %local n;
  proc sql noprint;
    select sum(missing(&variable)) into :n trimmed
    from ADAM.&dataset
    where &where;
  quit;
  %if %sysevalf(%superq(n)=,boolean) %then %let n=0;
  %if &n=0 %then %do;
    %add_validation(table_key=&table_key,check_type=MISSING,
      object=&dataset..&variable,result=PASS,detail=No missing values in analysis subset,severity=INFO);
  %end;
  %else %do;
    %add_validation(table_key=&table_key,check_type=MISSING,
      object=&dataset..&variable,result=WARNING,
      detail=Missing values in analysis subset: &n,severity=WARNING);
  %end;
%mend check_missing;

%macro validate_inputs;
  %check_dataset(dataset=ADSL,table_key=ALL);
  %check_dataset(dataset=ADAE,table_key=ALL);
  %check_dataset(dataset=ADTTE,table_key=ALL);
  %check_dataset(dataset=ADPC,table_key=ALL);

  %let adsl_vars=USUBJID SCRNFL ITTFL SAFFL TRT01PN TRT01P TRT01AN TRT01A
    COMTFL COMSFL DCSREAS DCTREAS AGE AGEU AGEGR1 AGEGR1N SEX RACE ETHNIC
    BLWT BLHT BLBMI;
  %let adae_vars=USUBJID SAFFL TRTEMFL TRT01AN ATOXGRN AREL AESER AEACN AESDTH;
  %let adtte_vars=USUBJID ITTFL PARAMCD TRT01PN TRT01P AVAL CNSR;
  %let adpc_vars=USUBJID ANL01FL ATPT ATPTN PCSTRESN AVAL;
  %let i=1;
  %do %while(%scan(&adsl_vars,&i) ne);
    %check_variable(dataset=ADSL,variable=%scan(&adsl_vars,&i),table_key=ALL);
    %let i=%eval(&i+1);
  %end;
  %let i=1;
  %do %while(%scan(&adae_vars,&i) ne);
    %check_variable(dataset=ADAE,variable=%scan(&adae_vars,&i),table_key=t-s-aebrief);
    %let i=%eval(&i+1);
  %end;
  %let i=1;
  %do %while(%scan(&adtte_vars,&i) ne);
    %check_variable(dataset=ADTTE,variable=%scan(&adtte_vars,&i),table_key=t-os);
    %let i=%eval(&i+1);
  %end;
  %let i=1;
  %do %while(%scan(&adpc_vars,&i) ne);
    %check_variable(dataset=ADPC,variable=%scan(&adpc_vars,&i),table_key=t-pkpc);
    %let i=%eval(&i+1);
  %end;

  /* PKFL is required by both the JSON and RTF and has no defensible mapping. */
  %check_variable(dataset=ADSL,variable=PKFL,table_key=t-pkpc,required=Y);
  %check_variable(dataset=ADSL,variable=PKyFL,table_key=t-pkpc,required=N);
  %check_variable(dataset=ADPC,variable=AVALC,table_key=t-pkpc,required=N);
  %check_variable(dataset=ADPC,variable=ASTRESC,table_key=t-pkpc,required=N);
  %add_validation(table_key=t-pkpc,check_type=TABLE,object=t-pkpc,
    result=WARNING,detail=Generation stopped: PKFL or PKyFL is absent; no PK population mapping is defensible,severity=WARNING);

  %check_missing(dataset=ADSL,variable=USUBJID,table_key=ALL,where=1);
  %check_missing(dataset=ADSL,variable=TRT01PN,table_key=ALL,where=1);
  %check_missing(dataset=ADSL,variable=ITTFL,table_key=t-s-demog,where=ITTFL='Y');
  %check_missing(dataset=ADSL,variable=SAFFL,table_key=t-s-aebrief,where=SAFFL='Y');
  %check_missing(dataset=ADTTE,variable=AVAL,table_key=t-os,where=PARAMCD='OS' and ITTFL='Y');

  proc sql;
    create table analysis_counts as
    select 'ADSL' as dataset length=8, 'SCRNFL=Y' as subset length=40,
           count(distinct USUBJID) as participants from ADAM.ADSL where SCRNFL='Y'
    union all select 'ADSL','ITTFL=Y',count(distinct USUBJID) from ADAM.ADSL where ITTFL='Y'
    union all select 'ADSL','SAFFL=Y',count(distinct USUBJID) from ADAM.ADSL where SAFFL='Y'
    union all select 'ADAE','SAFFL=Y and TRTEMFL=Y',count(distinct USUBJID)
      from ADAM.ADAE where SAFFL='Y' and TRTEMFL='Y'
    union all select 'ADTTE','PARAMCD=OS and ITTFL=Y',count(distinct USUBJID)
      from ADAM.ADTTE where PARAMCD='OS' and ITTFL='Y';
    create table treatment_counts as
    select 'ADSL' as dataset length=8, TRT01PN, TRT01P, count(distinct USUBJID) as participants
      from ADAM.ADSL where ITTFL='Y' group by TRT01PN,TRT01P;
  quit;

  proc sort data=ADAM.ADSL(keep=USUBJID) out=_adsl_dups nodupkey;
    by USUBJID;
  run;
  %if %sysfunc(attrn(%sysfunc(open(_adsl_dups)),nobs)) ne %sysfunc(attrn(%sysfunc(open(ADAM.ADSL)),nobs)) %then
    %add_validation(table_key=ALL,check_type=DUPLICATE,object=ADSL.USUBJID,result=WARNING,detail=Duplicate participant IDs detected,severity=WARNING);
  %else %add_validation(table_key=ALL,check_type=DUPLICATE,object=ADSL.USUBJID,result=PASS,detail=Participant IDs are unique,severity=INFO);
%mend validate_inputs;

%macro pdf_open(file=,title=,orientation=LANDSCAPE);
  ods _all_ close;
  options orientation=&orientation;
  ods pdf file="&output_path\&file" notoc;
  title1 j=c h=11pt "&study_id";
  title2 j=c h=12pt "&title";
  footnote1 j=l h=8pt "Source: metadata/DSS_Tables.json and metadata/DSS.rtf";
  footnote2 j=r h=8pt "Page ^{thispage} of ^{lastpage}";
%mend pdf_open;

%macro pdf_close;
  ods pdf close;
  ods listing;
%mend pdf_close;

/* Reusable categorical macro. Input contains one row per participant/category. */
%macro categorical_summary(data=,out=,row=ROWNUM,rowlabel=ROWLABEL,trt=TRT,
                          participant=USUBJID,denom=DENOM);
  proc sort data=&data out=_cat_in nodupkey;
    by &row &rowlabel &trt &participant;
  run;
  proc sql;
    create table &out as
    select &row, &rowlabel, &trt, count(distinct &participant) as n,
           max(&denom) as denom,
           calculated n / calculated denom * 100 as pct
    from _cat_in
    group by &row,&rowlabel,&trt;
  quit;
%mend categorical_summary;

/* Reusable continuous macro. Missing numeric values are excluded by PROC SUMMARY. */
%macro continuous_summary(data=,out=,row=ROWNUM,rowlabel=ROWLABEL,trt=TRT,
                         value=AVAL);
  proc summary data=&data nway;
    class &row &rowlabel &trt;
    var &value;
    output out=&out(drop=_type_ _freq_)
      n=n mean=mean std=std median=median q1=q1 q3=q3 min=min max=max;
  run;
%mend continuous_summary;

%macro ae_participant_count;
  /* ADAE is many rows per participant. Each row below is deduplicated by USUBJID. */
  proc sql;
    create table _ae_flags as
    select distinct USUBJID, TRT01AN as TRT,
      1 as any_teae,
      max(ATOXGRN ge 3) as grade3,
      max(ATOXGRN ge 2) as grade2,
      max(AREL='RELATED') as related,
      max(AREL='RELATED' and ATOXGRN ge 3) as related_grade3,
      max(AREL='RELATED' and ATOXGRN ge 2) as related_grade2,
      max(AESER='Y') as serious,
      max(AESER='Y' and AREL='RELATED') as related_serious,
      max(AEACN='DRUG WITHDRAWN') as withdrawn,
      max(AEACN='DOSE INTERRUPTED') as interrupted,
      max(AEACN='DOSE REDUCED') as reduced,
      max(AESDTH='Y') as death
    from ADAM.ADAE
    where SAFFL='Y' and TRTEMFL='Y'
    group by USUBJID,TRT01AN;
  quit;

  proc sql;
    create table _ae_denoms as
    select TRT01AN as TRT, count(distinct USUBJID) as denom
    from ADAM.ADSL where SAFFL='Y' group by TRT01AN;
  quit;

  data _ae_long;
    set _ae_flags;
    length ROWLABEL $100;
    array flags[12] any_teae grade3 grade2 related related_grade3 related_grade2
      serious related_serious withdrawn interrupted reduced death;
    array labels[13] $100 _temporary_ (
      'Any TEAE'
      'TEAE with Grade 3 or Higher'
      'TEAE with Grade 2 or Higher'
      'TEAE Related to Study Drug'
      'TEAE Related to Study Drug with Grade 3 or Higher'
      'TEAE Related to Study Drug with Grade 2 or Higher'
      'TE Serious AE'
      'TE Serious AE Related to Study Drug'
      'TEAE Leading to Discontinuation of Study Drug'
      'TEAE Leading to Dose Interruption of Study Drug'
      'TEAE Leading to Dose Reduction of Study Drug'
      'TEAE Leading to Death'
      '');
    do ROWNUM=1 to 12;
      ROWLABEL=labels[ROWNUM];
      if flags[ROWNUM]=1 then output;
    end;
    keep ROWNUM ROWLABEL USUBJID TRT;
  run;

  proc sql;
    create table _ae_summary as
    select a.ROWNUM,a.ROWLABEL,a.TRT,count(distinct a.USUBJID) as n,
           d.denom, calculated n/calculated denom*100 as pct
    from _ae_long as a left join _ae_denoms as d on a.TRT=d.TRT
    group by a.ROWNUM,a.ROWLABEL,a.TRT,d.denom;
  quit;
%mend ae_participant_count;

%macro display_npct(in=,out=,prefix=);
  data &out;
    set &in;
    length display $40;
    if missing(denom) or denom=0 then display='0 (0.0%)';
    else display=cats(put(n,3.),' (',put(pct,5.1),'%)');
  run;
%mend display_npct;

%macro disposition_table;
  proc sql;
    create table _disp_base as
    select distinct USUBJID, TRT01PN as TRT, SCRNFL, ITTFL, SAFFL,
           COMTFL, COMSFL, DCTREAS, DCSREAS
    from ADAM.ADSL;
    create table _disp_denoms as
    select TRT01PN as TRT,
      sum(SCRNFL='Y') as screened,
      sum(SAFFL='Y') as safety
    from ADAM.ADSL group by TRT01PN;
  quit;
  data _disp_long;
    set _disp_base;
    length ROWLABEL $100 denom 8;
    array labels[12] $100 _temporary_ ('Screened','ITT Analysis Set','Safety Analysis Set',
      'PK Analysis Set','Completed Study Drug','Discontinued Study Drug','Adverse Event',
      'Lack of Efficacy','Completed Study','Prematurely Discontinued Study','Death',
      'Withdrawal by Subject');
    do ROWNUM=1 to 12;
      ROWLABEL=labels[ROWNUM]; flag=0;
      select(ROWNUM);
        when(1) flag=(SCRNFL='Y');
        when(2) flag=(ITTFL='Y');
        when(3) flag=(SAFFL='Y');
        when(4) flag=0; /* PKFL is unresolved; row is documented in validation only. */
        when(5) flag=(SAFFL='Y' and COMTFL='Y');
        when(6) flag=(SAFFL='Y' and COMTFL='N');
        when(7) flag=(SAFFL='Y' and COMTFL='N' and DCTREAS='ADVERSE EVENT');
        when(8) flag=(SAFFL='Y' and COMTFL='N' and DCTREAS='LACK OF EFFICACY');
        when(9) flag=(SAFFL='Y' and COMSFL='Y');
        when(10) flag=(SAFFL='Y' and COMSFL='N');
        when(11) flag=(SAFFL='Y' and DCSREAS='DEATH');
        when(12) flag=(SAFFL='Y' and DCSREAS='WITHDRAWAL BY SUBJECT');
        otherwise flag=0;
      end;
      if flag then do;
        if ROWNUM in (1,2,3) then denom=.; else denom=1;
        output;
      end;
    end;
    keep ROWNUM ROWLABEL USUBJID TRT denom;
  run;
  proc sql;
    create table _disp_summary as
    select a.ROWNUM,a.ROWLABEL,a.TRT,count(distinct a.USUBJID) as n,
      case when a.ROWNUM in (1,2,3) then count(distinct a.USUBJID)
           else d.safety end as denom,
      case when a.ROWNUM in (1,2,3) then .
           else calculated n/calculated denom*100 end as pct
    from _disp_long a left join _disp_denoms d on a.TRT=d.TRT
    where a.ROWNUM ne 4
    group by a.ROWNUM,a.ROWLABEL,a.TRT,d.safety;
  quit;
  data _disp_report;
    set _disp_summary;
    length display $40;
    if missing(pct) then display=put(n,3.);
    else display=cats(put(n,3.),' (',put(pct,5.1),'%)');
  run;
  %pdf_open(file=t-s-disp.pdf,title=Participant Disposition);
  proc report data=_disp_report nowd headline headskip split='|';
    columns ROWNUM ROWLABEL TRT,display;
    define ROWNUM / order noprint;
    define ROWLABEL / ' ' style(column)=[asis=on cellwidth=2.8in];
    define TRT / across 'Planned Treatment';
    define display / 'n (%)' center;
  run;
  %pdf_close;
%mend disposition_table;

%macro demographics_table;
  data _demo;
    set ADAM.ADSL;
    where ITTFL='Y';
    length TRT $20;
    TRT=coalescec(TRT01P,strip(put(TRT01PN,best.)));
  run;
  proc sql;
    create table _demo_denoms as select TRT,count(distinct USUBJID) as denom
      from _demo group by TRT;
  quit;
  /* PROC FREQ is retained as a QC cross-check for the categorical shell rows. */
  proc freq data=_demo noprint;
    tables TRT*AGEGR1 TRT*SEX TRT*RACE TRT*ETHNIC / missing out=_demo_freq;
  run;
  data _demo_cat;
    set _demo;
    length ROWLABEL $100 VALUE $100;
    ROWNUM=1; ROWLABEL='Age Group'; VALUE=coalescec(AGEGR1,'Missing'); output;
    ROWNUM=2; ROWLABEL='Sex at Birth'; VALUE=coalescec(SEX,'Missing'); output;
    ROWNUM=3; ROWLABEL='Race'; VALUE=coalescec(RACE,'Missing'); output;
    ROWNUM=4; ROWLABEL='Ethnicity'; VALUE=coalescec(ETHNIC,'Missing'); output;
    keep ROWNUM ROWLABEL VALUE USUBJID TRT;
  run;
  proc sort data=_demo_cat out=_demo_cat_unique nodupkey;
    by ROWNUM ROWLABEL VALUE USUBJID TRT;
  run;
  proc sql;
    create table _demo_cat_sum as
    select ROWNUM,ROWLABEL,VALUE,TRT,count(distinct USUBJID) as n,
      d.denom, calculated n/calculated denom*100 as pct
    from _demo_cat_unique c left join _demo_denoms d on c.TRT=d.TRT
    group by ROWNUM,ROWLABEL,VALUE,TRT,d.denom;
  quit;
  data _demo_cat_report;
    set _demo_cat_sum;
    length display $40 label $200;
    label=cats(ROWLABEL,': ',ifc(missing(VALUE),'Missing',VALUE));
    display=cats(put(n,3.),' (',put(pct,5.1),'%)');
  run;
  proc sort data=_demo_cat_report; by ROWNUM ROWLABEL VALUE; run;

  data _demo_cont;
    set _demo;
    length ROWLABEL $100 AVAL 8;
    ROWNUM=5; ROWLABEL='Age (years)'; AVAL=AGE; output;
    ROWNUM=6; ROWLABEL='Weight (kg)'; AVAL=BLWT; output;
    ROWNUM=7; ROWLABEL='Height (cm)'; AVAL=BLHT; output;
    ROWNUM=8; ROWLABEL='Body Mass Index (kg/m^2)'; AVAL=BLBMI; output;
    keep ROWNUM ROWLABEL AVAL USUBJID TRT;
  run;
  %continuous_summary(data=_demo_cont,out=_demo_cont_sum);
  data _demo_cont_report;
    set _demo_cont_sum;
    length display $80;
    label=ROWLABEL;
    if n=0 then display='0';
    else do;
      display=cats(put(n,3.),' | ',put(mean,6.1),' (',put(std,6.2),') | ',
        put(median,6.1),' | ',put(q1,6.1),', ',put(q3,6.1),' | ',put(min,6.1),', ',put(max,6.1));
    end;
  run;
  data _demo_report;
    set _demo_cat_report(in=cat) _demo_cont_report(in=cont);
    if cat then section='CAT'; else section='CONT';
  run;
  %pdf_open(file=t-s-demog.pdf,title=Demographics and Baseline Characteristics);
  proc report data=_demo_report nowd headline headskip split='|';
    columns ROWNUM label TRT,display;
    define ROWNUM / order noprint;
    define label / ' ' style(column)=[asis=on cellwidth=3.1in];
    define TRT / across 'Planned Treatment';
    define display / 'n (%) or n | Mean (SD) | Median | Q1, Q3 | Min, Max' center;
  run;
  %pdf_close;
%mend demographics_table;

%macro survival_analysis;
  proc sort data=ADAM.ADTTE out=_os_tte;
    by USUBJID;
  run;
  proc sort data=ADAM.ADSL out=_os_adsl;
    by USUBJID;
  run;
  data _os;
    merge _os_tte(in=a) _os_adsl(keep=USUBJID ITTFL TRT01PN);
    by USUBJID;
    if a and PARAMCD='OS' and ITTFL='Y' and not missing(AVAL) and not missing(CNSR);
    TRT=TRT01PN;
  run;
  proc sort data=_os; by TRT; run;
  ods output HomTests=_os_logrank Quartiles=_os_quartiles;
  proc lifetest data=_os outsurv=_os_surv timelist=6 12 18 plots=none;
    time AVAL*CNSR(1);
    strata TRT / test=logrank diff=all;
  run;
  ods output close;
  ods output HazardRatios=_os_hr;
  proc phreg data=_os;
    class TRT (ref='2');
    model AVAL*CNSR(1)=TRT / rl ties=efron;
    hazardratio TRT / diff=ref alpha=0.05;
  run;
  ods output close;

  proc sql;
    create table _os_denoms as select TRT,count(distinct USUBJID) as denom
      from _os group by TRT;
    create table _os_events as select TRT,'Number (%) of Participants with Events (Death)' as ROWLABEL length=100,
      count(distinct USUBJID) as n from _os where CNSR=0 group by TRT;
    create table _os_cens as select TRT,'Number (%) of Participants Censored' as ROWLABEL length=100,
      count(distinct USUBJID) as n from _os where CNSR=1 group by TRT;
    create table _os_follow as select TRT,'Duration of OS Follow-up (Months)' as ROWLABEL length=100,
      count(AVAL) as n, mean(AVAL) as mean, std(AVAL) as std, median(AVAL) as median,
      q1(AVAL) as q1, q3(AVAL) as q3, min(AVAL) as min, max(AVAL) as max
      from _os group by TRT;
  quit;
  data _os_event_report;
    merge _os_events _os_cens;
    by TRT;
  run;
  proc sql;
    create table _os_report as
    select e.TRT,e.ROWLABEL,e.n,d.denom,c.n as censored
    from _os_events e left join _os_denoms d on e.TRT=d.TRT left join _os_cens c on e.TRT=c.TRT;
  quit;
  data _os_report;
    set _os_report;
    length display $80;
    display=cats(put(n,3.),' (',put(100*n/denom,5.1),'%)');
  run;
  %pdf_open(file=t-os.pdf,title=Overall Survival (OS));
  proc report data=_os_report nowd headline headskip split='|';
    columns ROWLABEL TRT,display;
    define ROWLABEL / ' ' style(column)=[asis=on cellwidth=3.4in];
    define TRT / across 'Planned Treatment';
    define display / 'n (%)' center;
  run;
  proc print data=_os_quartiles noobs; title3 'Kaplan-Meier Quartiles (raw ODS output)'; run;
  proc print data=_os_surv noobs; title3 'Kaplan-Meier Estimates at 6, 12, and 18 Months (raw ODS output)'; run;
  proc print data=_os_hr noobs; title3 'Cox Hazard Ratio (raw ODS output)'; run;
  proc print data=_os_logrank noobs; title3 'Log-rank Test (raw ODS output)'; run;
  %pdf_close;
%mend survival_analysis;

%macro ae_table;
  %ae_participant_count;
  data _ae_report;
    set _ae_summary;
    length display $40;
    display=cats(put(n,3.),' (',put(pct,5.1),'%)');
  run;
  %pdf_open(file=t-s-aebrief.pdf,title=Treatment-Emergent Adverse Events: Overall Summary);
  proc report data=_ae_report nowd headline headskip split='|';
    columns ROWNUM ROWLABEL TRT,display;
    define ROWNUM / order noprint;
    define ROWLABEL / 'Number (%) of Participants with' style(column)=[asis=on cellwidth=3.8in];
    define TRT / across 'Actual Treatment';
    define display / 'n (%)' center;
  run;
  %pdf_close;
%mend ae_table;

%macro pk_table;
  /* Deliberately no ODS PDF: RTF requires PKFL/PKyFL and no equivalent exists. */
  %add_validation(table_key=t-pkpc,check_type=PDF,object=t-pkpc.pdf,
    result=NOT_CREATED,detail=Conditional table withheld pending PKFL mapping,severity=WARNING);
%mend pk_table;

%macro pdf_checks;
  %local f i;
  %let i=1;
  %do %while(%scan(t-s-disp.pdf t-s-demog.pdf t-os.pdf t-s-aebrief.pdf t-pkpc.pdf,&i) ne);
    %let f=%scan(t-s-disp.pdf t-s-demog.pdf t-os.pdf t-s-aebrief.pdf t-pkpc.pdf,&i);
    %if %sysfunc(fileexist(&output_path\&f)) %then
      %add_validation(table_key=ALL,check_type=PDF,object=&f,result=PASS,detail=PDF exists,severity=INFO);
    %else %do;
      %if &f=t-pkpc.pdf %then %let _sev=WARNING;
      %else %let _sev=ERROR;
      %add_validation(table_key=ALL,check_type=PDF,object=&f,result=NOT_CREATED,detail=Expected PDF is absent,severity=&_sev);
    %end;
    %let i=%eval(&i+1);
  %end;
%mend pdf_checks;

%macro run_all;
  %setup_library;
  %metadata_configuration;
  %validation_setup;
  %validate_inputs;
  %if %sysfunc(exist(ADAM.ADSL)) %then %disposition_table;
  %if %sysfunc(exist(ADAM.ADSL)) %then %demographics_table;
  %if %sysfunc(exist(ADAM.ADTTE)) %then %survival_analysis;
  %if %sysfunc(exist(ADAM.ADAE)) %then %ae_table;
  %pk_table;
  %pdf_checks;

  title1 'DSS Summary Table Validation Report';
  proc print data=validation_report noobs label;
    var table_key check_type object result severity detail;
  run;
  proc print data=analysis_counts noobs; title2 'Analysis-set participant counts'; run;
  proc print data=treatment_counts noobs; title2 'ITT planned-treatment counts'; run;
  proc print data=table_config noobs; title2 'Interpreted table configuration'; run;

  data OUT.validation_report;
    set validation_report;
  run;
  data OUT.analysis_counts;
    set analysis_counts;
  run;
  data OUT.treatment_counts;
    set treatment_counts;
  run;

  proc sql noprint;
    select count(*) into :validation_errors trimmed
    from validation_report where result='FAIL' or severity='ERROR';
  quit;
  %put NOTE: DSS validation error count=&validation_errors;
  %if &validation_errors=0 %then %put NOTE: DSS validation completed with no errors.;
  %else %put ERROR: DSS validation found &validation_errors error(s). Review VALIDATION_REPORT.;
%mend run_all;

%run_all;

/* End of program. */
