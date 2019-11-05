"""
@file

@brief This library contains sas-appfitter Flat File Emulation functions for Python
@details
    The sas-appfitter project (github.com/TeMeta/sas-appfitter) defines a common interface
    for connecting SAS components to other parts of the application.
    There are implementations for multiple languages and connection types to create a
    unified framework for SAS Application Development and to facilitate creation of prototypes
"""

from os import path
import pandas as pd
import json
import time
#from pandas.io.json import json_normalize
import subprocess
from IPython.display import display

STREAMPATH = ".\\"
DATASTOREPATH = ".\\"
SASPROCESSPATH = ".\\"
SASEXEFILE = "C:\\Program Files\\SASHome\\SASFoundation\\9.4\\sas.exe"
SASCFGFILE = "C:\\Program Files\\SASHome\\SASFoundation\\9.4\\nls\\u8\\sasv9.cfg"
SUCCESSSTRING = "Response Received"
DATASTOREPATHS = {}
REFRESHPERIODSECS = 1
TIMEOUTSECS = 10


"""
@brief Gets depth of a dictionary
@param d dictionary to get depth of
@return 0 if empty or not a dictionary, number of levels otherwise
"""
def depth(d):
    if (not isinstance(d, dict) or not d):
        return 0
    else:
        return max(depth(v) for k, v in d.items()) + 1


"""
@brief reads DataFrame from SAS Dataset stream
@param obj object name as string 
@return DataFrame containing object contents
"""
def get_stream_dset(obj):
    if obj and path.exists(path.join(STREAMPATH, 'fromsas.json')):
        with open(path.join(STREAMPATH, 'fromsas.json')) as json_file:
            json_dict = json.load(json_file)
            print('JSON file loaded depth={}'.format(depth(json_dict)))
            if obj in json_dict:
                return pd.io.json.json_normalize(json_dict[obj])
            else:
                print("Object " + obj + " not found in stream")
                return pd.DataFrame()
    else:
        print("Did not find stream from SAS and/or no object defined")
        return pd.DataFrame()


"""
@brief Write DataFrame to SAS Dataset stream 
@param obj object name as string
@param indset DataFrame containing object contents
@return None
"""
def set_stream_dset(obj, indset):
    if obj and isinstance(indset, pd.DataFrame):
        if indset.empty:
            list_of_dicts = []
        else:
            list_of_dicts = indset.to_dict(orient='records')

        with open('data.txt', 'w') as outfile:
            json.dump({obj: list_of_dicts}, outfile)
    return None


"""
@brief Load named datastore into environment
@param name datastore name as string
@param targ description of target location
@return None
"""
def setup_datastore(name, targ):
    if name in DATASTOREPATHS:
        print("Datastore " + name + " was replaced")
        DATASTOREPATHS.pop(name)
    DATASTOREPATHS[name] = path.join(DATASTOREPATH, targ + '.json')
    return None


"""
@brief Unload named datastore from environment
@param name datastore name as string
@return None
"""
def teardown_datastore(name):
    if name in DATASTOREPATHS:
        DATASTOREPATHS.pop(name)
    else:
        print("Datastore " + name + " was not found by teardown_datastore")
    return None


"""
@brief Retrieve dataset from datastore
@param name datastore name as string
@param obj object/table name as string
@return DataFrame containing object
"""
def get_datastore_dset(name, obj):
    if name in DATASTOREPATHS:
        print(DATASTOREPATHS[name])
        if obj and path.exists(DATASTOREPATHS[name]):
            with open(DATASTOREPATHS[name]) as json_file:
                json_dict = json.load(json_file)
                print('JSON file loaded depth={}'.format(depth(json_dict)))
                if obj in json_dict:
                    return pd.io.json.json_normalize(json_dict[obj])
                else:
                    print("Object " + obj + " not found in datastore " + name)
                    return pd.DataFrame()
        else:
            print("Did not find datastore and/or no object defined")
            return pd.DataFrame()
    else:
        print(name + ' not found in registered datastores')
        return pd.DataFrame()


"""
@brief Write dataset to datastore
@param name datastore name as string
@param obj object/table name as string
@param indset Dataframe of content to write
@return None
"""
def set_datastore_dset(name, obj, indset):
    if name in DATASTOREPATHS:
        if path.exists(DATASTOREPATHS[name]):
            with open(DATASTOREPATHS[name]) as json_file:
                json_dict = json.load(json_file)
        else:
            json_dict = {}

        if obj and isinstance(indset, pd.DataFrame):
            if indset.empty:
                json_dict[obj] = []
            else:
                json_dict[obj] = indset.to_dict(orient='records')
            with open(DATASTOREPATHS[name], 'w') as outfile:
                json.dump(json_dict, outfile)
    else:
        print(name + ' not found in registered datastores')

    return None


"""
@brief Run named SAS process
@param name SAS process name
@return None
"""
def run_sas_process(name):
    with open(path.join(SASPROCESSPATH, name + '.bat'), 'w') as f:
        f.writelines([(
            '"{0}" -config "{1}"'.format(SASEXEFILE, SASCFGFILE) +
            ' -sysin "{0}"'.format(path.join(SASPROCESSPATH, name + '.sas')) +
            ' -log "{0}" -nologo'.format(path.join(SASPROCESSPATH, name + '.log'))
        )])

    submit_time = time.time()
    p = subprocess.Popen(path.join(SASPROCESSPATH, name + '.bat'), stdout=subprocess.PIPE)
    print('Running batch file')
    (output, err) = p.communicate()
    print('Batch file executed')

    return None


"""
@brief Wait until SAS process has updated expected table
@param submit_time time when process was submitted
@return True if response received, False if no response received
"""
def wait_for_stream_response(submit_time):
    if path.exists(path.join(STREAMPATH, 'fromsas.json')):
        # Loop until date modified or timeout
        while ((path.getmtime(path.join(STREAMPATH, 'fromsas.json')) < submit_time)
               and time.time() - submit_time <= TIMEOUTSECS):
            time.sleep(REFRESHPERIODSECS)
    else:
        # Loop until created or timeout
        while (not path.exists(path.join(STREAMPATH, 'fromsas.json'))
             and time.time() - submit_time <= TIMEOUTSECS):
            time.sleep(REFRESHPERIODSECS)

    if time.time() - submit_time <= TIMEOUTSECS:
        return True
    else:
        return False
