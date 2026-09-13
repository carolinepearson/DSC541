/* start of header *********************************************************************************
 
Program Name:      adtte.sas
Program Author:    Caroline Pearson (cpearson)
Program Purpose:   Create ADTTE dummy records for 100 participants
 
*********************************************************************************** end of header */

data adamdata.adtte;
    set adamdata.adsl;

    length
        PARAMCD $8
        PARAM $40
        AVALU $20
        EVNTDESC $40
        SRCDOM $8
        SRCVAR $32;

    format STARTDT ADT date9.;

    PARAMCD = "OS";
    PARAM = "Overall Survival";
    AVALU = "DAYS";
    STARTDT = RANDDT;
    SRCDOM = "ADSL";

    if not missing(DTHDT) then do;
        ADT = DTHDT;
        CNSR = 0;
        EVNTDESC = "DEATH";
        SRCVAR = "DTHDT";
    end;
    else do;
        ADT = LSTALVDT;
        CNSR = 1;
        EVNTDESC = "CENSORED";
        SRCVAR = "LSTALVDT";
    end;

    if not missing(STARTDT) and not missing(ADT) then do;
        AVAL = ADT - STARTDT + 1;
        ADY = ADT - STARTDT + 1;
    end;
    else do;
        AVAL = .;
        ADY = .;
    end;

    SRCSEQ = .;
run;
/*
proc contents data=adamdata.adtte;
run;

proc print data=adamdata.adtte(obs=10);
    var STUDYID USUBJID PARAMCD PARAM STARTDT ADT AVAL AVALU CNSR
        EVNTDESC SRCDOM SRCVAR;
run;
*/
