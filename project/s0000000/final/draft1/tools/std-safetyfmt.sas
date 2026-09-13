/* start of header *********************************************************************************
Program Name:      std-safetyfmt.sas
Program Author:    First Last (userid)
Program Purpose:   Create task/release level STARS formats

Change History:
    2023-04-14 psern   remove "  "='' lines  in proc format, note: not used: ftoxgr34_, ftoxgr345_, frange (only sb), $randfl,...
    2024-03-26 phamilton1        Update to STARS v1.3
    2024-09-09 Caroline Pearson  Updates for v1.4
    2024-11-06 kdaughtry01 Added nrdosint, $reas_int, nreas_dd, reas_dd, nndosint, nndelay, nnumnotad, 
    nninfint, nndosred, $any_ndosint, $any_ndelay, $any_numnotad, $any_ninfint, $any_ndosred
    2024-12-03 kdaughtry01 Added $pstat format
    2024-12-13 bliu        Added t-s-prancr formats
    2025-03-19 kdaughtry01 Added t-s-lbliver formats
    2025-06-03 kdaughtry01 Added formats for l-s-lbliver (astalt_cat, bili_cate, bili_cat, alp_cat)
    2025-06-04 kdaughtry01 Changed $frange format to set "NORMAL" to " ", instead of "N"
    2025-09-09 kdaughtry01 1) Changed the following formats to remove the underscore since SAS Viya has "_c" and "_n" as reserved keys:
                           $dthcls_c, dthcls_n, fsex_c, fsex_n, frace_c, frace_n, fethnic_c, fethnic_n, fiecat_n
                           2) Changed genidentn to use new values from GCDS and propcase them
                           3) Updated genidentc to change "Gender Non-Conforming" to "Gender Fluid"
    2025-11-11 kdaughtry01 1) Updated bili_cate and bili_cat to include 1.5
                           2) Updated alp_cat to include 2, 
                           3) Updated astalt_cat, bili_cate, bili_cat and alp_cat to include "x" before "ULN"
   
*********************************************************************************** end of header */

   invalue fsexc
      'M' = 1
      'F' = 2
      'U' = 3;
   value fsexn
      1 = 'Male'
      2 = 'Female'
      3 = 'Unknown';
   value $sex
      'F' = 'Female'
      'M' = 'Male';
   value $ frace
               'AMERICAN INDIAN OR ALASKA NATIVE' = 'AI'
                                          'ASIAN' = 'AS'
                      'BLACK OR AFRICAN AMERICAN' = 'BL'
      'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' = 'PI'
                                          'WHITE' = 'WH'
                                          'OTHER' = 'OT'
                                   'NOT REPORTED',
                                  'NOT PERMITTED' = 'NP';
   value $ fethnic
          'HISPANIC OR LATINO' = 'H'
      'NOT HISPANIC OR LATINO' = 'NH'
                'NOT REPORTED',
               'NOT PERMITTED' = 'NP';
   invalue fracec
               'AMERICAN INDIAN OR ALASKA NATIVE' = 1
                                          'ASIAN' = 2
                      'BLACK OR AFRICAN AMERICAN' = 3
      'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' = 4
                                          'WHITE' = 5
                                          'OTHER' = 6
                                   'NOT REPORTED',
                                  'NOT PERMITTED' = 7;
   value fracen
      1 = 'American Indian or Alaska Native'
      2 = 'Asian'
      3 = 'Black or African American'
      4 = 'Native Hawaiian or Other Pacific Islander'
      5 = 'White'
      6 = 'Other'
      7 = 'Not Permitted';
   invalue fethnicc
          'HISPANIC OR LATINO' = 2
      'NOT HISPANIC OR LATINO' = 1
                'NOT REPORTED',
               'NOT PERMITTED' = 3;
   value fethnicn
      1 = 'Not Hispanic or Latino'
      2 = 'Hispanic or Latino'
      3 = 'Not Permitted';
   value ftoxgr
      1 = 'Grade 1'
      2 = 'Grade 2'
      3 = 'Grade 3'
      4 = 'Grade 4'
      5 = 'Grade 5';
   value ftoxgr34_
      3 = 'Grade 3'
      4 = 'Grade 4';
   value ftoxgr345_
      3 = 'Grade 3'
      4 = 'Grade 4'
      5 = 'Grade 5';
   value $ ftoxgr_l
      '0' = 'G0'
      '1' = 'G1'
      '2' = 'G2'
      '3' = 'G3'
      '4' = 'G4';
   value $ frange
      'HIGH'   = 'H'
      'LOW'    = 'L'
      'NORMAL' = ' ';
   value fsevgr
      1 = 'Mild'
      2 = 'Moderate'
      3 = 'Severe';
   value $_yn_
         'RELATED', 'Y' = 'Yes'
      'NOT RELATED','N' = 'No';
   value $_ynm_
      'Y' = 'Yes'
      ' ',
      'N' = 'No';
   value $screen
      'Y' = 'Screened';
   value $enrlfl
      'Y'  = 'All Enrolled Analysis Set';
   value $randfl
      'Y' = 'All Randomized Analysis Set';
   value $ittfl
      'Y' = 'ITT Analysis Set';
   value $saffl
      'Y'  = 'Safety Analysis Set';
   value $pprotfl
      'Y'  = 'Per-Protocol Analysis Set';
   value total
      1 = 'Total';
   value compstud
      1 = 'Continuing Study'
      2 = 'Completed Study'
      3 = 'Prematurely Discontinued Study';
   value comptrt
      1 = 'Continuing Study Drug'
      2 = 'Completed Study Drug'
      3 = 'Prematurely Discontinued Study Drug';
   value fiecatn
      1 = 'Inclusion Criteria'
      2 = 'Exclusion Criteria';
   value $disc
      'Y' = 'No'
      'N' = 'Yes';

  value $radtype
	'PRIOR RADIOTHERAPY' = 'Prior'
	'ON STUDY RADIOTHERAPY' = 'On Study';

  value $surgtype
    'PRIOR SURGERIES AND PROCEDURES' = 'Prior'
	'ON STUDY SURGERIES AND PROCEDURES' = 'On Study'
	'POST END OF TREATMENT SURGERIES AND PROCEDURES'='Post End of Treatment';

  value dthclsn
	    1='Progressive Disease'
		2='Adverse Event'
		3='Other';

  value $dthclsc
         'ADVERSE EVENT' = 'Adverse Event'
   'PROGRESSIVE DISEASE' = 'Progressive Disease'
               'OTHER' = 'Other';

    invalue sexorc 
      "STRAIGHT/HETEROSEXUAL" = 1
	  "GAY" 				  = 2
	  "LESBIAN" 			  = 3
	  "BISEXUAL" 			  = 4
	  "QUEER" 				  = 5
	  "PANSEXUAL" 			  = 6
	  "ASEXUAL" 			  = 7
	  "OTHER" 				  = 8
	  "NOT REPORTED" 		  = 9; 

     value sexorn 
      1 = "Straight/Heterosexual"
	  2 = "Gay"
	  3 = "Lesbian"
	  4 = "Bisexual"
	  5 = "Queer"
	  6 = "Pansexual"
	  7 = "Asexual"
	  8 = "Other"
	  9 = "Not Reported";

	 invalue genidentc
      "Woman"					= 1
	  "Man"						= 2
	  "Transgender Woman"		= 3
	  "Transgender Man"			= 4
      "Gender Nonbinary"		= 5
      /*"Gender Non-Conforming"	= 6*/
      "Gender Fluid"       =6
      "Other"					= 7
      "Not Reported"			= 8;

/*
     value genidentn
      1 = "WOMAN"
	  2 = "MAN"
	  3 = "TRANSGENDER WOMAN"
	  4 = "TRANSGENDER MAN"
      5 = "GENDER NONBINARY"
      6 = "GENDER NON-CONFORMING"
      7 = "OTHER"
      8 = "NOT REPORTED";
*/
/*
     value genidentn
      1 = "Woman"
	  2 = "Man"
	  3 = "Transgender Woman"
	  4 = "Transgender Man"
      5 = "Gender Nonbinary"
      6 = "Gender Non-Conforming"
      7 = "Other"
      8 = "Not Reported";
*/
     value genidentn
     1 = "Cisgender Woman/Girl"
	  2 = "Cisgender Man/Boy"
	  3 = "Transgender Woman/Girl"
	  4 = "Transgender Man/Boy"
      5 = "Non-Binary"
      6 = "Gender Fluid"
      7 = "Other"
      8 = "Not Reported";
            
   value $country
		"ABW" =	"Aruba"
		"AFG" =	"Afghanistan"
		"AGO" =	"Angola"
		"AIA" =	"Anguilla"
		"ALB" =	"Albania"
		"AND" =	"Andorra"
		"ARE" =	"United Arab Emirates"
		"ARG" =	"Argentina"
		"ARM" =	"Armenia"
		"ASM" =	"American Samoa"
		"ATA" =	"Antarctica"
		"ATF" =	"French Southern and Antarctic Lands"
		"ATG" =	"Antigua and Barbuda"
		"AUS" =	"Australia"
		"AUT" =	"Austria"
		"AZE" =	"Azerbaijan"
		"BDI" =	"Burundi"
		"BEL" =	"Belgium"
		"BEN" =	"Benin"
		"BES" =	"Bonaire, Sint Eustatius and Saba"
		"BFA" =	"Burkina Faso"
		"BGD" =	"Bangladesh"
		"BGR" =	"Bulgaria"
		"BHR" =	"Bahrain"
		"BHS" =	"Bahamas"
		"BIH" =	"Bosnia and Herzegovina"
		"BLM" =	"Saint Barthelemy"
		"BLR" =	"Belarus"
		"BLZ" =	"Belize"
		"BMU" =	"Bermuda"
		"BOL" =	"Plurinational State of Bolivia"
		"BRA" =	"Brazil"
		"BRB" =	"Barbados"
		"BRN" =	"Brunei Darussalam"
		"BTN" =	"Bhutan"
		"BVT" =	"Bouvet Island"
		"BWA" =	"Botswana"
		"CAF" =	"Central African Republic"
		"CAN" =	"Canada"
		"CCK" =	"Cocos (Keeling) Islands"
		"CHE" =	"Switzerland"
		"CHL" =	"Chile"
		"CHN" =	"China"
		"CIV" =	"Cote d'Ivoire"
		"CMR" =	"Cameroon"
		"COD" =	"Democratic Republic of the Congo"
		"COG" =	"Congo"
		"COK" =	"Cook Islands"
		"COL" =	"Colombia"
		"COM" =	"Comoros"
		"CPV" =	"Cape Verde"
		"CRI" =	"Costa Rica"
		"CUB" =	"Cuba"
		"CUW" =	"Curacao"
		"CXR" =	"Christmas Island"
		"CYM" =	"Cayman Islands"
		"CYP" =	"Cyprus"
		"CZE" =	"Czech Republic"
		"DEU" =	"Germany"
		"DJI" =	"Djibouti"
		"DMA" =	"Dominica"
		"DNK" =	"Denmark"
		"DOM" =	"Dominican Republic"
		"DZA" =	"Algeria"
		"ECU" =	"Ecuador"
		"EGY" =	"Egypt"
		"ERI" =	"Eritrea"
		"ESH" =	"Western Sahara"
		"ESP" =	"Spain"
		"EST" =	"Estonia"
		"ETH" =	"Ethiopia"
		"FIN" =	"Finland"
		"FJI" =	"Fiji"
		"FLK" =	"Falkland Islands (Malvinas)"
		"FRA" =	"France"
		"FRO" =	"Faroe Islands"
		"FSM" =	"Federated States of Micronesia"
		"GAB" =	"Gabon"
		"GBR" =	"United Kingdom"
		"GEO" =	"Georgia (Republic)"
		"GGY" =	"Guernsey"
		"GHA" =	"Ghana"
		"GIB" =	"Gibraltar"
		"GIN" =	"Guinea"
		"GLP" =	"Guadeloupe"
		"GMB" =	"The Gambia"
		"GNB" =	"Guinea-Bissau"
		"GNQ" =	"Equatorial Guinea"
		"GRC" =	"Greece"
		"GRD" =	"Grenada"
		"GRL" =	"Greenland"
		"GTM" =	"Guatemala"
		"GUF" =	"French Guiana"
		"GUM" =	"Guam"
		"GUY" =	"Guyana"
		"HKG" =	"Hong Kong"
		"HMD" =	"Heard Island and McDonald Islands"
		"HND" =	"Honduras"
		"HRV" =	"Croatia"
		"HTI" =	"Haiti"
		"HUN" =	"Hungary"
		"IDN" =	"Indonesia"
		"IMN" =	"Isle of Man"
		"IND" =	"India"
		"IOT" =	"British Indian Ocean Territory"
		"IRL" =	"Ireland"
		"IRN" =	"Islamic Republic of Iran"
		"IRQ" =	"Iraq"
		"ISL" =	"Iceland"
		"ISR" =	"Israel"
		"ITA" =	"Italy"
		"JAM" =	"Jamaica"
		"JEY" =	"Jersey"
		"JOR" =	"Jordan"
		"JPN" =	"Japan"
		"KAZ" =	"Kazakhstan"
		"KEN" =	"Kenya"
		"KGZ" =	"Kyrgyzstan"
		"KHM" =	"Cambodia"
		"KIR" =	"Kiribati"
		"KNA" =	"Saint Kitts and Nevis"
		"KOR" =	"Republic of Korea"
		"KWT" =	"Kuwait"
		"LAO" =	"Lao People's Democratic Republic"
		"LBN" =	"Lebanon"
		"LBR" =	"Liberia"
		"LBY" =	"Libya"
		"LCA" =	"Saint Lucia"
		"LIE" =	"Liechtenstein"
		"LKA" =	"Sri Lanka"
		"LSO" =	"Lesotho"
		"LTU" =	"Lithuania"
		"LUX" =	"Luxembourg"
		"LVA" =	"Latvia"
		"MAC" =	"Macau"
		"MAF" =	"Saint Martin (French Part)"
		"MAR" =	"Morocco"
		"MCO" =	"Monaco"
		"MDA" =	"Republic of Moldova"
		"MDG" =	"Madagascar"
		"MDV" =	"Maldives"
		"MEX" =	"Mexico"
		"MHL" =	"Marshall Islands"
		"MKD" =	"Former Yugoslav Republic of Macedonia"
		"MLI" =	"Mali"
		"MLT" =	"Malta"
		"MMR" =	"Myanmar"
		"MNE" =	"Montenegro"
		"MNG" =	"Mongolia"
		"MNP" =	"Northern Mariana Islands"
		"MOZ" =	"Mozambique"
		"MRT" =	"Mauritania"
		"MSR" =	"Montserrat"
		"MTQ" =	"Martinique"
		"MUS" =	"Mauritius"
		"MWI" =	"Malawi"
		"MYS" =	"Malaysia"
		"MYT" =	"Mayotte"
		"NAM" =	"Namibia"
		"NCL" =	"New Caledonia"
		"NER" =	"Niger"
		"NFK" =	"Norfolk Island"
		"NGA" =	"Nigeria"
		"NIC" =	"Nicaragua"
		"NIU" =	"Niue"
		"NLD" =	"Netherlands"
		"NOR" =	"Norway"
		"NPL" =	"Nepal"
		"NRU" =	"Nauru"
		"NZL" =	"New Zealand"
		"OMN" =	"Oman"
		"PAK" =	"Pakistan"
		"PAN" =	"Panama"
		"PCN" =	"Pitcairn"
		"PER" =	"Peru"
		"PHL" =	"Philippines"
		"PLW" =	"Palau"
		"PNG" =	"Papua New Guinea"
		"POL" =	"Poland"
		"PRI" =	"Puerto Rico"
		"PRK" =	"Democratic People's Republic of Korea"
		"PRT" =	"Portugal"
		"PRY" =	"Paraguay"
		"PYF" =	"French Polynesia"
		"QAT" =	"Qatar"
		"REU" =	"Reunion"
		"ROU" =	"Romania"
		"RUS" =	"Russian Federation"
		"RWA" =	"Rwanda"
		"SAU" =	"Saudi Arabia"
		"SDN" =	"Sudan"
		"SEN" =	"Senegal"
		"SGP" =	"Singapore"
		"SGS" =	"South Georgia and the South Sandwich Islands"
		"SHN" =	"Saint Helena, Ascension and Tristan da Cunha"
		"SLB" =	"Solomon Islands"
		"SLE" =	"Sierra Leone"
		"SLV" =	"El Salvador"
		"SMR" =	"San Marino"
		"SOM" =	"Somalia"
		"SPM" =	"Saint Pierre and Miquelon"
		"SRB" =	"Serbia"
		"SSD" =	"South Sudan"
		"STP" =	"Sao Tome and Principe"
		"SUR" =	"Suriname"
		"SVK" =	"Slovakia"
		"SVN" =	"Slovenia"
		"SWE" =	"Sweden"
		"SWZ" =	"Swaziland"
		"SXM" =	"Sint Maarten (Dutch Part)"
		"SYC" =	"Seychelles"
		"SYR" =	"Syrian Arab Republic"
		"TCA" =	"Turks and Caicos Islands"
		"TCD" =	"Chad"
		"TGO" =	"Togo"
		"THA" =	"Thailand"
		"TJK" =	"Tajikistan"
		"TKL" =	"Tokelau"
		"TKM" =	"Turkmenistan"
		"TLS" =	"Timor-Leste"
		"TON" =	"Tonga"
		"TTO" =	"Trinidad and Tobago"
		"TUN" =	"Tunisia"
		"TUR" =	"Turkey"
		"TUV" =	"Tuvalu"
		"TWN" =	"Taiwan"
		"TZA" =	"United Republic of Tanzania"
		"UGA" =	"Uganda"
		"UKR" =	"Ukraine"
		"URY" =	"Uruguay"
		"USA" =	"United States"
		"UZB" =	"Uzbekistan"
		"VAT" =	"Holy See (Vatican City State)"
		"VCT" =	"Saint Vincent and the Grenadines"
		"VEN" =	"Bolivian Republic of Venezuela"
		"VGB" =	"Virgin Islands, British"
		"VIR" =	"Virgin Islands, U.S."
		"VNM" =	"Viet Nam"
		"VUT" =	"Vanuatu"
		"WLF" =	"Wallis and Futuna"
		"WSM" =	"Samoa"
        "YEM" = "Yemen"
        "ZAF"  = "South Africa"
        "ZMB" = "Zambia"
        "ZWE" = "Zimbabwe";

   value nrdosint
   low - 69='< 70%'
   70 - 89='>= 70% to < 90%'
   90 - 109='>= 90% to < 110%'
   110 - high='>= 110%'
   ; 

   value $reas_int
   'Adverse Event'='Adverse Event'
   'Other'='Other'
   ;  
  
   value nreas_dd
   1='Adverse Event'
   2='Subject Decision'
   3='Per Protocol Rest Period'
   4='Other'
   ;  
     
   invalue reas_dd
   'Adverse Event', 'ADVERSE EVENT'=1
   'Subject Decision', 'SUBJECT DECISION'=2
   'Per Protocol Rest Period', 'PER PROTOCOL REST PERIOD'=3
   'Other','OTHER'=4
   ;  

   value nndosint
   1 = '1 Dose Interruption'
   2 = '2 Dose Interruptions'
   3 = '3 Dose Interruptions'
   4 - high='> 3 Dose Interruptions'
   ;           
   
   value nndelay
   1 = '1 Entire Dose Delay'
   2 = '2 Entire Dose Delays'
   3 = '3 Entire Dose Delays'
   4 - high='> 3 Entire Dose Delays'
   ;              
   
   value nnumnotad
   1 = '1 Dose Not Administered'
   2 = '2 Doses Not Administered'
   3 = '3 Doses Not Administered'
   4 - high='> 3 Doses Not Administered'
   ;             
   
   value nninfint
   1 = '1 Infusion Interruption'
   2 = '2 Infusion Interruptions'
   3 = '3 Infusion Interruptions'
   4 - high='> 3 Infusion Interruptions'
   ;             
   
   value nndosred
   1 = '1 Dose Reduction'
   2 = '2 Dose Reductions'
   3 = '3 Dose Reductions'
   4 - high='> 3 Dose Reductions'
   ;                

   value $any_ndosint
   'Y'='Any Dose Interruption'
   ;
   
   value $any_ndelay
   'Y'='Any Entire Dose Delay'
   ;
   
   value $any_numnotad
   'Y'='Any Dose Not Administered'
   ;
   
   value $any_ninfint
   'Y'='Any Infusion Interruption'
   ;
   
   value $any_ndosred
   'Y'='Any Dose Reduction'
   ;   

   value $pstat
   'KPSBL'='Karnofsky'
   'ECOGBL'='ECOG'
   'WHOBL'='WHO'
   'GOGBL'='GOG'
   ;
	Invalue inbrn
		'Complete Response'=1
		'Partial Response'=2
		'Stable Disease'=3
		'Progressive Disease'=4
		'Not Reported / Not Available'=5
		'Not Applicable'=6
	;
	Value bestresp
		1='Complete Response'
		2='Partial Response'
		3='Stable Disease'
		4='Progressive Disease'
		5='Not Reported / Not Available'
		6='Not Applicable'
	;

	Invalue inhiamlf
		'HI-E' =1
		'HI-P' =2
		'HI-N' =3
	;

	value hiamlf
		1='Erythroid Response (HI-E)'
		2='Platelet Response (HI-P)'
		3='Neutrophil Response (HI-N)'
	;
 
	/*NOTE below for AMLBR: 1= 2+3 counts since they are subsections of CR*/
 
	Value AMLBR 
		1='Complete Remission (CR)'
		2='CR without minimal residual disease (CRMRD-)' 
		3='CR with positive or unknown minimal residual disease (CRMRD+/unk)'
		4='CR with incomplete hematologic recovery (CRi)'
		5='CR with partial hematologic recovery (CRh)'
		6='Morphologic Leukemia-Free State (MLFS)'
		7='Partial Remission (PR)'
		8='Stable Disease (SD)'
		9='Progressive Disease (PD)'
		10='Hematologic Relapse'
		11='No Assessment'
	;


	Invalue inYNRANK
		'Yes'=1
		'No'=2
	;

		Value YNRANK
		1='Yes'
		2='No'
	;

   value $altf
   'Y'='ALT'
   ;
   value $astf
   'Y'='AST'
   ;   
   value $altastf
   'Y'='ALT or AST'
   ;   
   value $altast3f
   'Y'='> 3 x ULN'
   ;
   value $altast5f
   'Y'='> 5 x ULN'
   ;
   value $altast10f
   'Y'='> 10 x ULN'
   ;
   value $altast20f
   'Y'='> 20 x ULN'
   ;
   value $tbf
   'Y'='Total Bilirubin'
   ;
   value $tb1f
   'Y'='> 1 x ULN'
   ;
   value $tb15f
   'Y'='> 1.5 x ULN'
   ;
   value $tb2f
   'Y'='> 2 x ULN'
   ;
   value $tb1fe
   'Y'='>= 1 x ULN'
   ;
   value $tb15fe
   'Y'='>= 1.5 x ULN'
   ;
   value $tb2fe
   'Y'='>= 2 x ULN'
   ;
   value $alpf
   'Y'='Alkaline Phosphatase'
   ;
   value $alp15f
   'Y'='> 1.5 x ULN'
   ;
   value $abif
   'Y'='ALT or AST with Total Bilirubin'
   ;
   value $abi15f
   'Y'='ALT or AST > 3 x ULN and Total Bilirubin > 1.5 x ULN'
   ;
   value $abi2f
   'Y'='ALT or AST > 3 x ULN and Total Bilirubin > 2 x ULN'
   ;
   value $abi15fe
   'Y'='ALT or AST > 3 x ULN and Total Bilirubin >= 1.5 x ULN'
   ;
   value $abi2fe
   'Y'='ALT or AST > 3 x ULN and Total Bilirubin >= 2 x ULN'
   ;
   value $abalf
   'Y'='ALT or AST with Total Bilirubin and Alkaline Phosphatase'
   ;
   value $abal2f
   'Y'='ALT or AST > 3 x ULN with Total Bilirubin > 2 x ULN and Alkaline Phosphatase < 2 x ULN'
   ;
   value $abal2fe
   'Y'='ALT or AST > 3 x ULN with Total Bilirubin >= 2 x ULN and Alkaline Phosphatase < 2 x ULN'
   ;

   value astalt_cat
   20='>20xULN'
   10='>10xULN'
   5='>5xULN'
   3='>3xULN'
   0='<=3xULN'
   ;
   
   value bili_cate
   2='>=2xULN'
   1.5='>=1.5xULN'
   0='<2xULN'
   ;
   
   value bili_cat
   2='>2xULN'
   1.5='>1.5xULN'
   0='<=2xULN'
   ;
   
   value alp_cat
   1.5, 2='>1.5xULN'
   0='<=1.5xULN'
   ;
   