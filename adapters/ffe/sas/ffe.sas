/**
@file
@brief Local, dependency-free functions that emulate a stream/datastore connection
@details
Flat File Emulator is an adapter implementing the sas-appfitter interface

Uses local json files to emulate
  - Stream (e.g. simulate SAS Stored Processes on server)
  - Datastore (e.g. simulate an abstract database)

Useful for developing prototype apps that can run locally on your machine
It is possible but not recommended to have more than one user

Counterpart FFE functions for other platforms, as well as other connection types,
can be found at https://github.com/TeMeta/sas-appfitter

@version SAS 9.4m4
@license Apache 2.0
@author Jeremy Teoh
**/

/* 
This path holds files serving as the data stream between SAS and the rest of the application
Its directory must share read and write access with other components
Include the trailing slash
Dataset into SAS is from tosas.json, dataset out of SAS is fromsas.json
*/
%global streampath;
%let streampath = ..\adapters\ffe\sas\;



/**
@brief Returns number of levels of nesting in JSON file
@param file identifies which json file to check
@returns number of levels
@returns 0 if empty file
@returns -1 if file does not exist
**/
%macro getJsonDepth(file=);
  %local rc result;
  
  %if %sysfunc(fileexist(&file)) eq 0 %then %let result = -1;
  
  %else %let rc = %sysfunc(dosubl(%str(
      filename tempfile "%qsysfunc(dequote(&file.))";
      libname templib json fileref=tempfile;
      
      proc sql noprint;
        select coalesce(max(p),0) into :result
        from templib.alldata;
      quit;
  )));
 
 &result.
%mend;

/*
@brief Deserialises JSON input from application into SAS dataset
@details streamfile macro variable determines JSON file used for stream emulation

@param obj name of retrieved object from JSON file
@param outdset name of dataset created from retrieved object
**/
%macro getStreamDset(obj=, outdset=);
  %local jsonlev;
  
  %let jsonlev = %getJsonDepth(file="&streampath.tosas.json");
  %put &=jsonlev;
   
 /* If stream file does not exist, create empty dataset */
  %if &jsonlev eq -1 %then %do;
    %put %str(E)RROR: JSON file does not exist;
  %end;
  
  %else %if &jsonlev eq 1 %then %do;
    %put %str(E)RROR: JSON file needs to be format datasetName : [{flatDatasetContent}];
  %end;
  
  %else %if &jsonlev gt 2 %then %do;
    %put %str(E)RROR: JSON file has too much nesting.
 It needs to be format datasetName : [{flatDatasetContent}];
  %end;
  
  %else %if &jsonlev eq 2 %then %do;
    filename intoSAS "&streampath.\from";
  
    %if %sysfunc(fexist(intoSAS)) eq 0 %then %do;
      %put %str(E)RROR: &SYSMACRONAME.: Stream into SAS not found;
    %end;
  
    %else %do;       
      %if %sysfunc(exist(intoSAS.&obj)) %then %do; /* Create dataset */
        data &outdset;
          set intoSAS.&obj;
          drop ordinal_:;
        run;
      %end;
      %else %do;
        data &outdset;
          stop;
        run;
        %put %str(E)RROR: &SYSMACRONAME.: Object not found &=obj;
      %end;
  %end;
  %end;
%mend;

/**
@brief Serialises output SAS dataset into a JSON file to feed to application
@details streampath macro variable determines path of JSON file used for stream emulation

@param obj name of object added/amended into output stream
@param indset dataset to write output stream
**/
%macro setStreamDset(obj=, indset=);
%if %sysfunc(exist(&indset)) eq 0 %then %do;
  %put %str(E)RROR: &SYSMACRONAME.: Dataset not found &=indset;
  %return;
%end;

proc json
  out="&streampath.fromsas.json" 
  pretty nosastags nokeys;
  write open object;
    write value "%superq(obj)";
    export &indset / keys;
  write close;
run;

%mend;


/**
@brief Establish a datastore connection
@details This implementation uses flat JSON files to emulate a datastore
  Depending on your application, you may want to set  targ= to some default

@param name datastore ID for future reference (up to 8 letters)
@param targ path of flat file
**/
%macro setupDatastore(name=, targ=);
  %local jsonlev;
  
  %if %length(&name) eq 0 or %length(&name) gt 8 %then %do;
    %put %str(E)RROR: &SYSMACRONAME: NAME must be 1 to 8 letters long;
    %return;
  %end;
  
  %let targ = %qsysfunc(dequote(&targ));
  
  filename &name "&targ";
  
  %let jsonlev = %getJsonDepth(file="&targ");
  %put &=jsonlev;
   
 /* If datastore does not exist, create it */
  %if &jsonlev eq -1 %then %do;
    data _null_;
      file &name;
    run;
  %end;
  
  %if &jsonlev eq 1 %then %do;
    %put %str(E)RROR: JSON file needs to be format datasetName : {flatDatasetContent};
  %end;
  
  %if &jsonlev gt 2 %then %do;
    %put %str(E)RROR: JSON file has too much nesting.
 It needs to be format datasetName : {flatDatasetContent};
  %end;
  
%mend;

/**
@brief Clean up and close named datastore connection
@param name datastore to be closed
**/
%macro teardownDatastore(name=);
  %if %sysfunc(fileref(&name)) gt 0 %then %do;
    %put %str(E)RROR: &SYSMACRONAME: file reference not found [&name];
    %return;
  %end;
  
  filename &name clear;
%mend;


/**
@brief Extract object from datastore into dataset
@param name datastore name
@param obj name of object to extract from datastore
@param outdset dataset created from extraction
**/
%macro getDatastoreDset(name=, obj=, outdset=); 
  %local rc;
  
  %if %sysfunc(fexist(&name)) eq 0 %then %do;
    %put %str(E)RROR: &SYSMACRONAME.: Datastore not found &=name;
  %end;
  
  %else %do;
    libname &name json fileref=&name;
       
    %if %sysfunc(exist(&name..&obj)) %then %do; /* Create dataset */
      data &outdset;
        set &name..&obj;
        drop ordinal_:;
      run;
    %end;
    %else %do;
      %put %str(E)RROR: &SYSMACRONAME.: Object not found &=obj;
    %end;
  %end;
%mend;

/**
@brief Write dataset content to datastore
@param name datastore ID
@param obj object ID being written
@param indset dataset to write to datastore object
**/
%macro setDatastoreDset(name=, obj=, indset=);
  %local _alldsets _i _this;

  %if %sysfunc(fexist(&name)) eq 0 %then %do;
    %put %str(E)RROR: &SYSMACRONAME.: Datastore not found &=name;
    %return;
  %end;

  %if %sysfunc(exist(&indset)) eq 0 %then %do;
    %put %str(E)RROR: &SYSMACRONAME.: Dataset not found &=indset;
    %return;
  %end;

  libname &name json fileref=&name;

  /* Get list of objects in the datastore */
  proc sql noprint;
  select memname
    into :_alldsets separated by '#'
  from dictionary.tables 
  where libname eq upcase("&name");
  quit;

  proc json 
    out="%sysfunc(pathname(&name))" 
    pretty nosastags nokeys;
    write open object;
  
      write value "%upcase(&obj)";
      write open array;
        export &indset / keys; /* Add new dataset to top */
    write close;
  
  %do _i = 1 %to %sysfunc(countw(&_alldsets,#));
    %let _this =%scan(&_alldsets,&_i,#);
    %if &_this ne %upcase(&obj)
      and &_this ne ALLDATA %then %do;
    
        /* Rebuild other datasets in datastore */
        write value "&_this";
        write open array;
          export &name..&_this(drop=ordinal_:) / keys;
        write close;
  
    %end;  
  %end;

    write close;
  run;

%mend;
