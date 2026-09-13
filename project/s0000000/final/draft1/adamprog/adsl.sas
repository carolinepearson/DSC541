/* start of header *********************************************************************************
 
Program Name:      adsl.sas
Program Author:    Caroline Pearson (cpearson)
Program Purpose:   Create ADSL dummy records for 100 participants
 
*********************************************************************************** end of header */

data adamdata.adsl;
    call streaminit(20260823);
retain STUDYID USUBJID SUBJID SITEID RFICDT RANDDT SCRNFL RANDFL SAFFL ITTFL COMT01FL COMSFL PKFL 
        SEX RACE ETHNIC AGE AGEU AGEGR1 AGEGR1N ARM TRTSDT TRTEDT TRT01P TRT01PN TRT01A TRT01AN 
        EOTSTT DCT01RS EOSDT EOSSTT DCSREAS DTHFL DTHDT DTHCAUS LSTALVDT BWT BHT BBMI;
    length
        STUDYID USUBJID $20
        SUBJID SITEID $10
        RANDFL SAFFL ITTFL 
        SCRNFL COMT01FL COMSFL PKFL DTHFL $1
        SEX RACE ETHNIC $40
        AGEU AGEGR1 $20
        ARM TRT01P TRT01A $20
        EOSSTT EOTSTT $20
        DCSREAS DCT01RS DTHCAUS $100;

    length AGEGR1N BWT BHT BBMI 8;

    label
        SCRNFL = "Screened Population Flag"
        COMT01FL = "Completed Study Treatment Flag"
        COMSFL = "Completed Study Flag"
        PKFL = "Pharmacokinetic Population Flag"
        AGEGR1 = "Age Group 1"
        AGEGR1N = "Age Group 1 Numeric"
        BWT = "Baseline Weight"
        BHT = "Baseline Height"
        BBMI = "Baseline Body Mass Index";

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
        if AGE < 65 then do;
            AGEGR1 = "< 65";
            AGEGR1N = 1;
        end;
        else do;
            AGEGR1 = ">= 65";
            AGEGR1N = 2;
        end;
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

        RFICDT = "15DEC2016"d + mod(SubjectNumber - 1, 10);
        RANDDT = "01JAN2016"d + SubjectNumber - 1;
        TRTSDT = RANDDT;
        *TreatmentDays = rand("integer", 10, 100);
        *TRTEDT = TRTSDT + TreatmentDays;

        if SubjectNumber > 49 then do;
            TreatmentDiscontinue = 1;
            StudyDiscontinue = 1;
        	TreatmentMonths = rand("integer", 4, 16);
        	DTHDT = intnx("month", TRTSDT, TreatmentMonths, "same");
           	*DTHDT = TRTSDT + TreatmentDays;
			DTHFL = "Y";
            TRTEDT = DTHDT;
            EOSSTT = "DISCONTINUED";
            EOSDT = DTHDT;
            DCSREAS = "DEATH";
            EOTSTT = "DISCONTINUED";
            DCT01RS = "ADVERSE EVENT";
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
                DCT01RS = "LACK OF EFFICACY";
            end;
            else do;
                EOTSTT = "COMPLETED";
                DCT01RS = "";
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
        PKFL = "Y";
        if EOTSTT = "COMPLETED" then
            COMT01FL = "Y";
        else
            COMT01FL = "N";

        if COMT01FL = "N" then do;
            TreatmentMonths = rand("integer", 2, 16);
            TRTEDT = intnx("month", TRTSDT, TreatmentMonths, "same");
            if not missing(DTHDT) then do;
                DTHDT = TRTEDT;
                EOSDT = DTHDT;
                LSTALVDT = DTHDT;
            end;
            else if StudyDiscontinue then do;
                EOSDT = TRTEDT + rand("integer", 1, 14);
                LSTALVDT = EOSDT;
            end;
            else do;
                EOSDT = TRTEDT;
                LSTALVDT = EOSDT;
            end;
        end;
        else do;
            TreatmentMonths = rand("integer", 17, 19);
            TRTEDT = intnx("month", TRTSDT, TreatmentMonths, "same");
            EOSDT = TRTEDT;
            LSTALVDT = EOSDT;
        end;

        if EOSSTT = "COMPLETED" then
            COMSFL = "Y";
        else
            COMSFL = "N";

        BWT = round(55 + mod(SubjectNumber * 7, 35) + rand("uniform"), 0.1);
        BHT = round(150 + mod(SubjectNumber * 5, 35) + rand("uniform"), 0.1);
        BBMI = round(BWT / ((BHT / 100) ** 2), 0.1);

        output;
    end;

        drop SubjectNumber /*TreatmentDays*/ TreatmentMonths
            TreatmentDiscontinue StudyDiscontinue;
run;
/*
proc contents data=adamdata.adsl;
run;

proc print data=adamdata.adsl(obs=10);
run;
*/
