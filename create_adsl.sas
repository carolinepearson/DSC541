libname adam "~/DSC541/adam";

data adam.adsl;
    call streaminit(20260823);

    length
        STUDYID USUBJID $20
        SUBJID SITEID $10
        RANDFL SAFFL ITTFL $1
        SCRNFL COMTFL COMSFL $1
        AGEU SEX RACE ETHNIC $40
        AGEGR1 $20
        ARM TRT01P TRT01A $20
        EOSSTT EOTSTT $20
        DCSREAS DCTREAS DTHCAUS $100;

    length AGEGR1N BLWT BLHT BLBMI 8;

    label
        SCRNFL = "Screened Population Flag"
        COMTFL = "Completed Study Treatment Flag"
        COMSFL = "Completed Study Flag"
        AGEGR1 = "Age Group 1"
        AGEGR1N = "Age Group 1 Numeric"
        BLWT = "Baseline Weight"
        BLHT = "Baseline Height"
        BLBMI = "Baseline Body Mass Index";

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
        TreatmentDays = rand("integer", 10, 100);
        TRTEDT = TRTSDT + TreatmentDays;

        if SubjectNumber > 90 then do;
            TreatmentDiscontinue = 1;
            StudyDiscontinue = 1;
            DTHDT = TRTSDT + TreatmentDays;
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
            StudyDiscontinue = (rand("uniform") < 0.15);
            TreatmentDiscontinue = (rand("uniform") < 0.20);

            if StudyDiscontinue then
                TreatmentDiscontinue = 1;

            if TreatmentDiscontinue then do;
                EOTSTT = "DISCONTINUED";
                DCTREAS = "LACK OF EFFICACY";
            end;
            else do;
                EOTSTT = "COMPLETED";
                DCTREAS = "";
            end;

            if StudyDiscontinue then do;
                EOSSTT = "DISCONTINUED";
                EOSDT = TRTEDT + rand("integer", 1, 14);
                DCSREAS = "WITHDRAWAL BY SUBJECT";
            end;
            else do;
                EOSSTT = "COMPLETED";
                EOSDT = TRTEDT;
                DCSREAS = "";
            end;

            LSTALVDT = EOSDT;
            DTHDT = .;
            DTHCAUS = "";
        end;

        SCRNFL = "Y";
        if EOTSTT = "COMPLETED" then
            COMTFL = "Y";
        else
            COMTFL = "N";

        if EOSSTT = "COMPLETED" then
            COMSFL = "Y";
        else
            COMSFL = "N";

        if AGE < 65 then do;
            AGEGR1 = "< 65";
            AGEGR1N = 1;
        end;
        else do;
            AGEGR1 = ">= 65";
            AGEGR1N = 2;
        end;

        BLWT = round(55 + mod(SubjectNumber * 7, 35) + rand("uniform"), 0.1);
        BLHT = round(150 + mod(SubjectNumber * 5, 35) + rand("uniform"), 0.1);
        BLBMI = round(BLWT / ((BLHT / 100) ** 2), 0.1);

        output;
    end;

    drop SubjectNumber TreatmentDays TreatmentDiscontinue StudyDiscontinue;
run;

proc contents data=adam.adsl;
run;

proc print data=adam.adsl(obs=10);
run;
