/* start of header *********************************************************************************
Program Name:      val_report.sas
Program Author:    GitHub Copilot (copilot)
Program Purpose:   Phase 2 - render the consolidated cross-table validation report at
                    tools/val_report.out from the shared TOOLS.VAL_REPORT dataset that each
                    <titlekey>.sas program appends to via PROC APPEND.

*********************************************************************************** end of header */

/*----------------------------------------------------------------------------------------------
  Run this program AFTER any subset of t-disp.sas / t-demog.sas / t-aebrief.sas / t-os.sas /
  t-pkpc.sas have executed. It only READS tools.val_report (never overwrites it) and produces a
  plain-text listing at tools/val_report.out - the deliverable path requested for Phase 2.
  Re-running this program is always safe: it regenerates the .out listing from whatever rows
  are currently present in the shared dataset, it does not mutate tools.val_report itself.
----------------------------------------------------------------------------------------------*/

options missing='';

%let tools = ../tools;
libname tools "&tools";

%macro main;

%if %sysfunc(exist(tools.val_report))=0 %then %do;
   %put %str(ER)ROR: [USER] tools.val_report does not exist yet - run at least one table program first.;
   %goto endprogram;
%end;

proc sort data=tools.val_report out=_val_sorted;
   by titlekey rundttm;
run;

ods listing close;
ods pdf close;
proc printto print="&tools/val_report.out" new;
run;

options linesize=200 pagesize=60 nodate nonumber;

title1 "Consolidated TFL Validation Report";
title2 "Generated %sysfunc(datetime(), datetime20.)";

proc report data=_val_sorted nowd;
   column titlekey dsname varname check expected actual status message;
   define titlekey / order   "Titlekey"     width=10;
   define dsname   / display "Dataset(s)"   width=12;
   define varname  / display "Variable(s)"  width=16;
   define check    / display "Validation Check" width=24;
   define expected / display "Expected"     width=22;
   define actual   / display "Actual"       width=22;
   define status   / display "Status"       width=8;
   define message  / display "Message"      width=60 flow;
run;

title; footnote;
proc printto;
run;
ods listing;

%put NOTE: [USER] Consolidated validation report written to &tools/val_report.out;

%endprogram:

%mend main;

%main;
