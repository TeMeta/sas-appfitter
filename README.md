# What is sas-appfitter?
Adapters that use a generic interface to allow SAS programs to pass datasets to and from other environments, data sources and languages.

The idea is to simplify SAS-powered app prototype development by providing interfaces and architecture up-front for a variety of languages, connections types and datastores.

When the requirements of your application change, the adapters can be switched without having to modify the existing programs. 

Database type, API connections and even the entire front-end can be swapped out. Adapters to the generic interface provide flexibility for your application/prototype, which should in turn significantly reduce the cost of development and migration on your app.


The folder structure organises them first by the language, then by connection type

```
.
├── ...
├── adapters                # All interface adapters
│   ├── sas                 # Adapters for the SAS environment
│   │   ├── ffs             # Connection using Flat File Simulation
│   │   ├── h54s            # Connection using Boemska HTML5 Adapter for SAS
│   │   ├── viya            # Connection using SAS Viya
│   │   ├── ...             
│   ├── javascript
│   │   ├── ffs
│   │   ├── h54s
│   │   ├── ...    
│   ├── python
│   │   ├── ffs
│   │   ├── ...
│   ├── vba
│   │   ├── ffs
│   │   ├── ...
│   ├── mysql
│   │   ├── ffs
│   │   ├── ...
│   ├── postgresql
│   │   ├── ffs
│   │   ├── ...
│   ├── ...  
```


## Flat File Simulation (ffs)
This repository introduces Flat File Simulation, a standalone local prototyping environment. 
FFS allows you to develop application prototypes free of dependencies on IT and various software licenses, while using the same sas-appfitter generic interface functions so that any code you write will be portable to other environments when the time comes to scale up.


The 'flat files' are SAS datasets serialised to, and deserialised from, JSON files stored locally. 
Variations are used for simulating a client-server connection (inspired by [H54S](https://github.com/Boemska/h54s)) and writing to a persistent datastore (inspired by [Pickle](https://github.com/python/cpython/blob/3.7/Lib/pickle.py))


Select the ffs family of adapters if you are developing a prototype
1. No dependencies on SAS licenses beyond SAS BASE 9.4
2. No need to set up a webserver or database - uses local files instead to simulate the same functionality
3. Uses the appfitter interface so that other functionality can easily be plugged in later 


## Licensing

__Please take care to check the licenses of any other projects that you need to import and apply them to your project. 
sas-appfitter may include adapters that have dependencies on other packages, and takes no responsibility for these packages or the actions of users that download them__


This project is under the Apache v2.0 license.

In the spirit of open-source, you are encouraged to use this code provided that you share modifications and improvements back to this repository. 

If you can't find one of the adapters you need, develop a new adapter and plug in to the appfitter ecosystem. 
The better the collection of adapters here, the easier it will make it to develop applications with SAS
