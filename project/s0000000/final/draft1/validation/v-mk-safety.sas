/* start of header *********************************************************************************

Program Name:      v-mk-safety.sas
Program Author:    First Last (userid)
Program Purpose:   Verify Safety programs not modified after being created by STARS tool

*********************************************************************************** end of header */

x "cd &progpath; md5sum ../prog/l-s-*.sas > ../validation/temp.dat";
x "cd &progpath; md5sum ../prog/t-s-*.sas >> ../validation/temp.dat";

data val (drop=text); 
   infile "./temp.dat" lrecl=1000 pad;
   input @1 text $1000.;
   checksum=scan(text,1,'');
   file=scan(text,2,'');
run;

data safety (drop=text); 
   infile "../tools/m-safety-checksum.out" lrecl=1000 pad;
   input @1 text $1000.;
   checksum=scan(text,1,'');
   file=scan(text,2,'');
run;

%printset(outname=v-mk-safety)

title3 "Safety Programs Checksum Validation";
title4 "Source Checksum File: ../tools/m-safety-checksum.out";

proc compare base=safety comp=val outbase outdif outcomp out=dif listall outnoequal;
run;

proc print data=dif;
run;

x "cd &progpath; rm ../validation/temp.dat";

%pageset(outname=v-mk-safety, wantpdf=N)

%let __vrsn = %scan("&progpath", -2, '/');
%let __task = %scan("&progpath", -3, '/');

x "cp &progpath/v-mk-safety.out /biometrics/global/specstore/msafetystore/v-mk-safety_&__task._&__vrsn..out";

