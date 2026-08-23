libname adam "";

data adam.adsl;
    length
        STUDYID USUBJID $20
        SUBJID SITEID $10
        RANDFL SAFFL ITTFL $1
        AGEU SEX RACE ETHNIC $40
        ARM TRT01P TRT01A $20
        EOSSTT EOTSTT $20
        DCSREAS DCTREAS DTHCAUS $100;

    format TRTSDT TRTEDT EOSDT RFICDT RANDDT
           LSTALVDT DTHDT date9.;

    do SubjectNumber = 1 to 100;
        STUDYID = "STUDY001";
        SUBJID = put(SubjectNumber, z3.);
        SITEID = put(100 + mod(SubjectNumber - 1, 5), z3.);
        USUBJID = cats(STUDYID, "-", SUBJID);

        RANDFL = "Y";
        SAFFL = "Y";
        ITTFL = "Y";

        AGE = 18 + mod(SubjectNumber * 3, 60);
        AGEU = "YEARS";
        if mod(SubjectNumber, 2) = 0 then SEX = "M";
        else SEX = "F";

        select (mod(SubjectNumber, 4));
            when (0) RACE = "WHITE";
            when (1) RACE = "BLACK OR AFRICAN AMERICAN";
            when (2) RACE = "ASIAN";
            otherwise RACE = "OTHER";
        end;

        if mod(SubjectNumber, 3) = 0 then ETHNIC = "HISPANIC OR LATINO";
        else ETHNIC = "NOT HISPANIC OR LATINO";

        select (mod(SubjectNumber, 2));
            when (0) do;
                ARM = "Drug A";
                TRT01P = "Drug A";
                TRT01PN = 1;
                TRT01A = "Drug A";
                TRT01AN = 1;
            end;
            otherwise do;
                ARM = "Drug B";
                TRT01P = "Drug B";
                TRT01PN = 2;
                TRT01A = "Drug B";
                TRT01AN = 2;
            end;
        end;

        RFICDT = "15DEC2025"d + mod(SubjectNumber - 1, 10);
        RANDDT = "01JAN2026"d + SubjectNumber - 1;
        TRTSDT = RANDDT;
        TRTEDT = TRTSDT + 27;

        if SubjectNumber > 90 then do;
            DTHDT = TRTSDT + 10;
            TRTEDT = DTHDT;
            EOSSTT = "DISCONTINUED";
            EOSDT = DTHDT;
            DCSREAS = "DEATH";
            EOTSTT = "DISCONTINUED";
            DCTREAS = "DEATH";
            LSTALVDT = DTHDT;
            select (mod(SubjectNumber, 3));
                when (0) DTHCAUS = "Cardiac event";
                when (1) DTHCAUS = "Respiratory failure";
                otherwise DTHCAUS = "Underlying disease";
            end;
        end;
        else do;
            EOSSTT = "COMPLETED";
            EOSDT = TRTEDT;
            DCSREAS = "";
            EOTSTT = "COMPLETED";
            DCTREAS = "";
            LSTALVDT = EOSDT;
            DTHDT = .;
            DTHCAUS = "";
        end;

        output;
    end;

    drop SubjectNumber;
run;

proc contents data=adam.adsl;
run;

proc print data=adam.adsl(obs=10);
run;
