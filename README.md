# sas-appfitter


## What is sas-appfitter?
A collection of adapters that use a generic interface to allow SAS® programs to pass datasets (flat tables of strings and numerics) to and retrieve them from other environments, data sources and languages.

The idea is to simplify SAS-powered app prototype development by providing interfaces and architecture up-front for a variety of languages, connections types and datastores. Appfitter was inspired by [H54S from Boemska](https://github.com/Boemska/h54s) and builds on the concept by extending it into a collection of compatible connectors

All adapters in the collection implement a generic interface to provide flexibility for your application prototype. Database type, API connections, and even the entire front-end can be swapped out without having to modify other components. Simply change the adapter for one that fits the new connection type. When requirements change, your application can too without any rewriting. 

This library is intended to reduce the cost of development and migration on your app as well as make it easier to build prototypes. Anyone who needs to make a modification or build a new connection is welcomed to contribute it back to the collection.

## Finding your way around the adaptors

The folder structure organises them first by connection type, then by language (the below is for illustrative purposes)

```
.
├── ...
├── adapters              # All interface adapters
│   ├── ffe                 # Connection using Flat File Emulation
│   │   ├── sas               # Adapters for the SAS environment
│   │   ├── javascript
│   │   ├── python          
│   │   ├── vba
│   │   ├── ...             
│   ├── h54s               # Connection using Boemska HTML5 Adapter for SAS
│   │   ├── sas
│   │   ├── javascript
│   │   ├── ...
│   ├── flask              # Connection using Flask
│   │   ├── sas
│   │   ├── python          
│   │   ├── ...
│   ├── spotfire           # Connection using Spotfire
│   │   ├── sas
│   │   ├── ironpython
│   │   ├── javascript
│   │   ├── ...
│   ├── qlik               # Connection using Qlik Sense
│   │   ├── sas
│   │   ├── ...
│   ├── viya               # Connection using SAS Viya
│   │   ├── sas
│   │   ├── ...
│   ├── mysql              # Datastore Connection using MySQL
│   │   ├── sas
│   │   ├── ...
│   ├── postgresql         # Datastore Connection using PostgreSQL
│   │   ├── sas
│   │   ├── ...
│   ├── ...  
```


## Flat File Emulation (FFE)
This repository introduces Flat File Emulation, a standalone local prototyping environment. 
FFE allows you to develop application prototypes free of dependencies on IT and various software licenses, while using the same sas-appfitter generic interface functions so that any code you write will be portable to other environments when the time comes to scale up.


The 'flat files' are SAS datasets serialised to, and deserialised from, JSON files stored locally. 
Variations are used for emulating a client-server connection (inspired by [H54S](https://github.com/Boemska/h54s)) and writing to a persistent datastore (inspired by [Pickle](https://github.com/python/cpython/blob/3.7/Lib/pickle.py))


Select the ffe family of adapters if you are developing a prototype
1. No dependencies on SAS licenses beyond SAS BASE 9.4
2. No need to set up a server or database - uses local files instead to simulate the same functionality
3. Uses the appfitter interface so that other functionality can easily be plugged in later 



## Generic Interface Methods

The use of generic interface methods allows the same programs to connect with any number of different component connections

These are shown in the form of SAS macros since this project started with SAS adapters. The same principle can also apply to functions/methods in other languages.

SAS adapters receive datasets that have been passed from other components in the application that were built using a non-SAS platform. What they all have in common is the protocol of passing flat tables rather than parameters. If parameters need to be passed they can be packed into rows or columns instead.

```sas
%macro getStreamDset(obj=, outdset=);
```
Deserialise the application's input to the SAS procedure into a SAS dataset. `obj` is the name of the object (e.g. if the input is in the form of multiple JSON tables, the name of the table). `outdset` is the dataset created from the content.

```sas
%macro setStreamDset(obj=, indset=);
```
Take the dataset `indset` that was generated in the SAS process, serialise it to object named `obj`, and feed it back to the application.

```sas
%macro setupDatastore(name=, targ=);
```
Establish a datastore connection. `name` is the reference (up to 8 letters) given to the created datastore and `targ` is a string (e.g. a name or query) describing which target in the datastore is selected. 

```sas
%macro teardownDatastore(name=);
```
This cleans up and closes the named datastore connection as necessary.

```sas
%macro getDatastoreDset(name=, obj=, outdset=);
```
Read table `obj` from the named datastore `name` and put its contents into a dataset `outdset`

```sas
%macro setDatastoreDset(name=, obj=, indset=);
```
Take dataset `indset` and write it to table `obj` in the named datastore `name`

## Links to available adapters

[FFE]
[H54S]

## Licensing

__Please take care to check the licenses of any other projects that you need to import and apply them to your project. 
sas-appfitter may include adapters that have dependencies on other packages, and takes no responsibility for these packages or the actions of users that download them__


This project is under the Apache v2.0 license.

In the spirit of open-source, you are encouraged to use this code provided that you share modifications and improvements back to this repository. 

If you can't find one of the adapters you need, develop a new adapter and plug in to the appfitter ecosystem. 
The better the collection of adapters here, the easier it will make it to develop applications with SAS

