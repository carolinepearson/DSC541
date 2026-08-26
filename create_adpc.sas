libname adam "~/DSC541/adam";

data adam.adpc;
    set adam.adsl;

    retain STUDYID USUBJID SUBJID SITEID RANDFL SAFFL ITTFL SCRNFL
           COMTFL COMSFL AGE AGEU AGEGR1 AGEGR1N SEX RACE ETHNIC
           BLWT BLHT BLBMI ARM TRT01P TRT01PN TRT01A TRT01AN TRTSDT
           TRTEDT EOSSTT EOSDT DCSREAS EOTSTT DCTREAS RFICDT RANDDT
           LSTALVDT DTHDT DTHCAUS;

    if _N_ = 1 then call streaminit(20260823);

    length
        PARAMCD $8
        PARAM $60
        AVALU $20
        ATPT AVISIT $40
        ATPTREF $20
        ATMU $20
        PCELTM PCELTMU $20
        PCTESTCD $8
        PCTEST $60
        PCORRES PCORRESU $20
        PCSTRESC PCSTRESU $20
        PCDTC $25
        ANL01FL $1;

    format ADT date9. ADTM datetime20. AVAL ATTM 8.2;

    PARAMCD = "PC";
    PARAM = "Plasma Drug Concentration";
    AVALU = "ng/mL";
    PCTESTCD = "DRUGCONC";
    PCTEST = "Drug Concentration";
    PCORRESU = "ng/mL";
    PCSTRESU = "ng/mL";
    PCELTMU = "hours";
    ATMU = "hours";
    ATPTREF = "TRTSDT";
    AVALU = "ng/mL";
    ANL01FL = "Y";

    do RecordNumber = 1 to 9;
        select (RecordNumber);
            when (1) do;
                ATPT = "Pre-dose";
                ATPTN = 0;
                PCELTM = "PT0H";
                PCELTMN = 0;
            end;
            when (2) do;
                ATPT = "1 Hour";
                ATPTN = 1;
                PCELTM = "PT1H";
                PCELTMN = 1;
            end;
            when (3) do;
                ATPT = "2 Hours";
                ATPTN = 2;
                PCELTM = "PT2H";
                PCELTMN = 2;
            end;
            when (4) do;
                ATPT = "4 Hours";
                ATPTN = 4;
                PCELTM = "PT4H";
                PCELTMN = 4;
            end;
            when (5) do;
                ATPT = "8 Hours";
                ATPTN = 8;
                PCELTM = "PT8H";
                PCELTMN = 8;
            end;
            when (6) do;
                ATPT = "12 Hours";
                ATPTN = 12;
                PCELTM = "PT12H";
                PCELTMN = 12;
            end;
            when (7) do;
                ATPT = "16 Hours";
                ATPTN = 16;
                PCELTM = "PT16H";
                PCELTMN = 16;
            end;
            when (8) do;
                ATPT = "18 Hours";
                ATPTN = 18;
                PCELTM = "PT18H";
                PCELTMN = 18;
            end;
            otherwise do;
                ATPT = "24 Hours";
                ATPTN = 24;
                PCELTM = "PT24H";
                PCELTMN = 24;
            end;
        end;

        if PCELTMN = 0 then
            PCSTRESN = round(5.01 + rand("uniform") * 2, 0.01);
        else
            PCSTRESN = round(120 * exp(-0.08 * PCELTMN) *
                             (0.75 + rand("uniform") * 0.5), 0.01);
        if rand("uniform") < 0.10 then do;
            PCORRES = "BLQ";
            PCSTRESC = "BLQ";
            PCSTRESN = .;
        end;
        else do;
            PCORRES = strip(put(PCSTRESN, 8.2));
            PCSTRESC = PCORRES;
        end;
        AVAL = PCSTRESN;
        ATTM = PCELTMN;
        ADTM = dhms(TRTSDT, PCELTMN, 0, 0);
        ADT = datepart(ADTM);
        if PCELTMN < 24 then do;
            AVISIT = "Day 1";
            AVISITN = 1;
        end;
        else do;
            AVISIT = "Day 2";
            AVISITN = 2;
        end;
        PCDTC = put(ADTM, e8601dt25.);
        PCDY = ADT - TRTSDT + 1;
        output;
    end;

    drop RecordNumber;
run;

proc contents data=adam.adpc;
run;

proc print data=adam.adpc(obs=12);
    var STUDYID USUBJID PARAMCD PARAM ATPT ATPTN AVISIT AVISITN
        ATPTREF ATTM ATMU PCORRES PCORRESU PCSTRESN PCSTRESU
        AVAL AVALU ADT ADTM PCDTC PCELTM PCELTMN ANL01FL;
run;
