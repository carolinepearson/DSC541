/* start of header *********************************************************************************

Program Name:      taskfmt.sas
Program Author:    Caroline Pearson (cpearson)
Program Purpose:   Create task/release level format catalog formats.sas7bcat

*********************************************************************************** end of header */

libname tasktool ".";

proc datasets nolist lib=tasktool;
   delete formats / memtype=catalog;
run;
quit;

/* Programmer: add a value statement for each format to the proc below */

proc format library=tasktool;

   /* include STARS formats as needed */
   %include 'std-safetyfmt.sas';

  value trtfmt
    1="Drug A"
    2="Drug B"
	;
  value agegrfmt
    1="< 65"
    2=">= 65"
	;

run;
