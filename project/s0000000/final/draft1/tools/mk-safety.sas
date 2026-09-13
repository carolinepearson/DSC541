/* start of header *********************************************************************************

Program Name:      mk-safety.sas
Program Author:    First Last (userid)
Program Purpose:   Driver program for creating Safety TFLs (Version 1.5)

*********************************************************************************** end of header */

%m_safety(metafile=../docs/m_safety.xlsx,                     /* Specify program metadata XLSX file */
          version=%str(v1.5),                                 /* Specify version */
          templdir=/biometrics/global/template/stars/v1.5);   /* Specify the template program directory for a specified version */

