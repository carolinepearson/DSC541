/* start of header *********************************************************************************

Program Name:      tnfconvert.sas
Program Author:    First Last (userid)
Program Purpose:   Read titles and footnotes information and create tools/tnf.inc file

*********************************************************************************** end of header */
   
%m_tnfconv( in      = &docs/tnf.xlsx,  /* Path and filename of titles file     */
            tnf     = &tools/tnf.inc,  /* Path and filename of output tnf file */
            outname = &jobname)        /* Report name                          */



/* End of tnfconvert.sas             */

