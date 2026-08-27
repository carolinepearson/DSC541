libname adam "~/DSC541/adam";

data adam.adtte;
    set adam.adsl;

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
    AVALU = "MONTHS";
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
        AVAL = intck("month", STARTDT, ADT, "continuous");
        ADY = ADT - STARTDT + 1;
    end;
    else do;
        AVAL = .;
        ADY = .;
    end;

    SRCSEQ = .;
run;

proc contents data=adam.adtte;
run;

proc print data=adam.adtte(obs=10);
    var STUDYID USUBJID PARAMCD PARAM STARTDT ADT AVAL AVALU CNSR
        EVNTDESC SRCDOM SRCVAR;
run;
