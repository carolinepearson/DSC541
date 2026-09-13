/* start of header *********************************************************************************

Program Name:      init.inc
Program Author:    First Last (userid)
Program Purpose:   initialization file	                                                    
                   - creates macro variables used by global macros                                                 
                   - automatically copied into tools directory & localized by FAB when new tools
                     folders are created                                                                                   
                   - Programmer needs to provide data transfer date &dataver and last 4 digits of
                     &sno (as applicable)                     
                   - can be further customized by Programmer                                                                                                                  
                   - template location: \\gsasdata\global\biostat\v4.19.01\folder_templates 
                                                                                                                                    
*********************************************************************************** end of header */

&debug %put Begin "init.inc" file processing. ;

/* macro variables used by the standard macros */
%let toolver  = v4.19.01;				/* Global Macro Version */ 
%let dataver  = %str(ddmmmyyyy);			/* Data Transfer Date (updated/customized by Programmer) */
%let sno      = 000-0000;            		        /* Study # (partially updated by FAB; Programmer provides last 4 digits) */
%let project  = GS-XXXX;             		        /* GS # (updated by FAB) */
%let protocol = GS-US-000-0000;			        /* Protocol # (updated by FAB) */
%let prtstudy = %str(Study GS-US-000-0000);	      	/* Protocol # for Output Header (updated by FAB, customizable by Programmer) */
%let hdrmode  = R;                   		        /* Header Justification (default & standard is R, can be changed to L) */
%let runmode  = ;             		        /* Run Mode (changed to blank by Programmer if study is open-label/unblinded) */                                        
%let caution  = N;                   		        /* Caution Flag (changed to blank by Programmer when data & programs are final) */
%let _subj_keyvars = subjid;		  		/* Declare the unique key identifier variables for subjects in the study */
%let study_subject_text = Participant;            /* Declare the study subject term for TFLs (Participant or Patient, per Protocol/SAP) */

/* Programmer: create task/release specific macro variables below (an example of common macro variables created for DMCs is
   given - can be modified or deleted as needed) */
%let dmcdtn   = "01JAN2000"d;       		   /* DMC Meeting Date, numeric */
%let dmcdtc   = "01JAN2000";			         /* DMC Meeting Date, character */
%let cutdtn   = "01JAN2000"d;       		   /* DMC Data Snapshot Date, numeric  */

/* set SAS options, overwrite system defaults  */
options mprint source;* source2 symbolgen;
     
&debug %put End "init.inc" file processing. ;
