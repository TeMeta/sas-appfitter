/**
@file
@brief Connects SAS stored processes to webapp using Boemska HTML5 Adapter for SAS
@details
A thin wrapper for the Boemska H54S adapter to implement the sas-appfitter interface

The input and output datasets from sas-appfitter interface are fed to H54S adapter. 
No additional processing is needed because sas-appfitter is based on the H54S framework.

Latest instructions, license and download link for the Boemska HTML5 Adapter for SAS:
https://github.com/Boemska/h54s

@version SAS 9.2
@license Apache 2.0 (sas-appfitter only. H54S has separate license)
@author Jeremy Teoh
**/

%include 'h54s.sas'; /* Point this to the path of H54S macros */

/*
@brief Deserialises input from application into SAS dataset
@param obj name of retrieved object from stream
@param outdset name of dataset created from retrieved object
**/
%macro getStreamDset(obj=, outdset=);
  %hfsGetDataset(&obj,&outdset);
  %hfsErrorCheck;
%mend;

/**
@brief Serialises output SAS dataset and feeds it into application
@param obj name of object added/amended into output stream
@param indset dataset to write output stream
**/
%macro setStreamDset(obj=, indset=);
  %local lib;
  %if %sysfunc(countw(&indset,.)) eq 1 %then %let lib = work;
  %else %let lib = %scan(&indset,1,.);
    
  %hfsHeader;
  %hfsOutDataset(&obj, &lib, %scan(&indset,-1,.));
  %hfsFooter;
%mend;