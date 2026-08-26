libname adam "~/DSC541/adam";

data adam.adae;
    set adam.adsl;

    retain STUDYID USUBJID SUBJID SITEID RANDFL SAFFL ITTFL SCRNFL
           COMTFL COMSFL AGE AGEU AGEGR1 AGEGR1N SEX RACE ETHNIC
           BLWT BLHT BLBMI ARM TRT01P TRT01PN TRT01A TRT01AN TRTSDT
           TRTEDT EOSSTT EOSDT DCSREAS EOTSTT DCTREAS RFICDT RANDDT
           LSTALVDT DTHDT DTHCAUS;

    if _N_ = 1 then call streaminit(20260824);

    length
        AETERM AESOC AEBODSYS AEDECOD AESTDTC AEENDTC AETOXGR
        AEREL AREL AESER AEACN AEOUT AEPATT EPOCH
        AEACNOTH AOCCFL TRTEMFL AESCONG AESDISAB AESDTH AESHOSP
        AESLIFE AESMIE SRCDOM SRCVAR $100;

    length
        AESEQ AESTDY ASTDY AEENDY AENDY AETOXGRN ARELN
        AEOUTN 8;

    format AESTDT AEENDT date9.;

    SubjectNumber = input(Subjid, best.);
    RecordCount = 1 + mod(SubjectNumber - 1, 10);
    EventStart = rand("integer", 1, 11);

    do AESEQ = 1 to RecordCount;
        if not missing(DTHDT) and AESEQ = 1 then
            EventCode = 12;
        else
            EventCode = mod(EventStart + AESEQ - 2, 11) + 1;

        select (EventCode);
            when (1) do;
                AETERM = "Headache";
                AEDECOD = "Headache";
                AESOC = "Nervous system disorders";
                AEBODSYS = "Nervous system disorders";
                AETOXGRN = 1;
                AEREL = "RELATED";
                AREL = "RELATED";
                ARELN = 1;
                AESER = "N";
                AEACN = "DOSE NOT CHANGED";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            when (2) do;
                AETERM = "Nausea";
                AEDECOD = "Nausea";
                AESOC = "Gastrointestinal disorders";
                AEBODSYS = "Gastrointestinal disorders";
                AETOXGRN = 2;
                AEREL = "RELATED";
                AREL = "RELATED";
                ARELN = 1;
                AESER = "N";
                AEACN = "NONE";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            when (3) do;
                AETERM = "Rash";
                AEDECOD = "Rash";
                AESOC = "Skin and subcutaneous tissue disorders";
                AEBODSYS = "Skin and subcutaneous tissue disorders";
                AETOXGRN = 2;
                AEREL = "NOT RELATED";
                AREL = "NOT RELATED";
                ARELN = 2;
                AESER = "N";
                AEACN = "DOSE NOT CHANGED";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            when (4) do;
                AETERM = "Cough";
                AEDECOD = "Cough";
                AESOC = "Respiratory, thoracic and mediastinal disorders";
                AEBODSYS = "Respiratory disorders";
                AETOXGRN = 1;
                AEREL = "NOT RELATED";
                AREL = "NOT RELATED";
                ARELN = 2;
                AESER = "N";
                AEACN = "NONE";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            when (5) do;
                AETERM = "Back pain";
                AEDECOD = "Back pain";
                AESOC = "Musculoskeletal and connective tissue disorders";
                AEBODSYS = "Musculoskeletal disorders";
                AETOXGRN = 2;
                AEREL = "RELATED";
                AREL = "RELATED";
                ARELN = 1;
                AESER = "N";
                AEACN = "DOSE NOT CHANGED";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            when (6) do;
                AETERM = "Fatigue";
                AEDECOD = "Fatigue";
                AESOC = "General disorders and administration site conditions";
                AEBODSYS = "General disorders";
                AETOXGRN = 1;
                AEREL = "RELATED";
                AREL = "RELATED";
                ARELN = 1;
                AESER = "N";
                AEACN = "NONE";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            when (7) do;
                AETERM = "Elevated liver enzymes";
                AEDECOD = "Alanine aminotransferase increased";
                AESOC = "Investigations";
                AEBODSYS = "Investigations";
                AETOXGRN = 3;
                AEREL = "RELATED";
                AREL = "RELATED";
                ARELN = 1;
                AESER = "Y";
                AEACN = "DOSE INTERRUPTED";
                AEOUT = "RECOVERING/RESOLVING";
                AEOUTN = 2;
            end;
            when (8) do;
                AETERM = "Dizziness";
                AEDECOD = "Dizziness";
                AESOC = "Nervous system disorders";
                AEBODSYS = "Nervous system disorders";
                AETOXGRN = 2;
                AEREL = "RELATED";
                AREL = "RELATED";
                ARELN = 1;
                AESER = "N";
                AEACN = "DOSE NOT CHANGED";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            when (9) do;
                AETERM = "Diarrhea";
                AEDECOD = "Diarrhoea";
                AESOC = "Gastrointestinal disorders";
                AEBODSYS = "Gastrointestinal disorders";
                AETOXGRN = 3;
                AEREL = "RELATED";
                AREL = "RELATED";
                ARELN = 1;
                AESER = "N";
                AEACN = "DOSE INTERRUPTED";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            when (10) do;
                AETERM = "Injection site reaction";
                AEDECOD = "Injection site reaction";
                AESOC = "General disorders and administration site conditions";
                AEBODSYS = "General disorders";
                AETOXGRN = 4;
                AEREL = "RELATED";
                AREL = "RELATED";
                ARELN = 1;
                AESER = "N";
                AEACN = "DOSE REDUCED";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            when (11) do;
                AETERM = "Increased blood pressure";
                AEDECOD = "Hypertension";
                AESOC = "Vascular disorders";
                AEBODSYS = "Vascular disorders";
                AETOXGRN = 3;
                AEREL = "NOT RELATED";
                AREL = "NOT RELATED";
                ARELN = 2;
                AESER = "N";
                AEACN = "NONE";
                AEOUT = "RECOVERED/RESOLVED";
                AEOUTN = 1;
            end;
            otherwise do;
                select (DTHCAUS);
                    when ("Cardiac event") do;
                        AETERM = "Fatal cardiac event";
                        AEDECOD = "Cardiac arrest";
                        AESOC = "Cardiac disorders";
                        AEBODSYS = "Cardiac disorders";
                    end;
                    when ("Respiratory failure") do;
                        AETERM = "Fatal respiratory failure";
                        AEDECOD = "Respiratory failure";
                        AESOC = "Respiratory, thoracic and mediastinal disorders";
                        AEBODSYS = "Respiratory disorders";
                    end;
                    otherwise do;
                        AETERM = "Fatal underlying disease";
                        AEDECOD = "Disease progression";
                        AESOC = "General disorders and administration site conditions";
                        AEBODSYS = "General disorders";
                    end;
                end;
                AETOXGRN = 5;
                AEREL = "RELATED";
                AREL = "RELATED";
                ARELN = 1;
                AESER = "Y";
                AEACN = "DRUG WITHDRAWN";
                AEOUT = "FATAL";
                AEOUTN = 3;
            end;
        end;

        AETOXGR = put(AETOXGRN, 1.);
        AESTDT = TRTSDT + mod(SubjectNumber + AESEQ + EventCode, 8) + 1;
        AEENDT = AESTDT + mod(SubjectNumber + EventCode, 5) + 1;

        if EventCode = 8 then do;
            AESTDT = DTHDT;
            AEENDT = .;
        end;

        if not missing(DTHDT) and AEENDT > DTHDT then
            AEENDT = DTHDT;

        if not missing(AEENDT) and AEENDT < AESTDT then
            AEENDT = AESTDT;

        AESTDTC = put(AESTDT, e8601da10.);
        if missing(AEENDT) then
            AEENDTC = "";
        else
            AEENDTC = put(AEENDT, e8601da10.);
        AESTDY = AESTDT - TRTSDT + 1;
        ASTDY = AESTDY;
        AEENDY = AEENDT - TRTSDT + 1;
        AENDY = AEENDY;
        TRTEMFL = "Y";
        EPOCH = "TREATMENT";
        AEPATT = "CONTINUOUS";
        AESCONG = "N";
        AESDISAB = "N";
        if EventCode = 8 then
            AESDTH = "Y";
        else
            AESDTH = "N";
        AESHOSP = "N";
        AESLIFE = "N";
        AESMIE = "N";
        AOCCFL = "Y";
        if index(upcase(DCSREAS), "WITHDRAW") > 0 then
            AEACNOTH = "4";
        else
            AEACNOTH = "";
        SRCDOM = "ADSL";
        SRCVAR = "TRTSDT";
        SRCSEQ = AESEQ;
        output;
    end;

    drop SubjectNumber RecordCount EventStart EventCode;
run;

proc contents data=adam.adae;
run;

proc print data=adam.adae(obs=12);
    var STUDYID USUBJID AESEQ AETERM AESOC AEBODSYS AEDECOD TRTEMFL
        AESTDT AESTDTC AEENDT AEENDTC AESTDY ASTDY AEENDY AENDY
        AETOXGR AETOXGRN AEREL AREL ARELN AESER;
run;
