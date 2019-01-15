#!/usr/bin/env python
'''
This ansible fact module gathers information about the slapd online config.
Returns a JSON file that describes several task critical values of the config.
'''
from subprocess import Popen, PIPE
import json
import sys
import shlex


# ------------------------------------------------ #
# Helper to handle SSHA passwords used by OpenDLAP #
# ------------------------------------------------ #

import hashlib
import os
from base64 import urlsafe_b64encode as encode
from base64 import urlsafe_b64decode as decode

def checkpassword(challenge_password, password):
    """
    :param challenge_passwd: The SSHA string to match.
    :type challenge_passwd: str
    :param password: The password to match.
    :type password: str
    :returns: Whether the password matches the SSHA of not.
    :rtype: boolean
    """
    challenge_bytes = decode(challenge_password[6:])
    digest = challenge_bytes[:20]
    salt = challenge_bytes[20:]
    hr = hashlib.sha1(password)
    hr.update(salt)
    return digest == hr.digest()
 
 
# --------------- #
# Doing the magic #
# --------------- #

# Getting arguments passed by ansible
arguments = shlex.split(file(sys.argv[1]).read())

# Parsing script parameters
params = {}
for arg in arguments:
    (key, value) = arg.split('=', 1)
    params[key] = value

# The json that will contain the information gathered
jayout = {}
jayout['params'] = params

# Gathering configuration
p = Popen("ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config",
          stdout=PIPE, shell=True)
# Parsing results
(stdout, stderr) = p.communicate()

# If search query didn't succeed
if stderr != None:
    # Saving error output
    jayout['search_succeeded'] = False
    jayout['search_error_msg'] = stderr
    # Printing JSON output to playbook
    print json.dumps(jayout)
    # Exiting
    exit(0)

# Registering query as successful
jayout['search_succeeded'] = True

# ---------------------------------- #
# Converting search output into json #
# ---------------------------------- #
# Initializing variables
config = {}
inblock = False
currentblock = None
currentattr = None

# Parsing each line of the output
for line in stdout.splitlines():
    #print('debug: %s' % line)
    # We're not in a block
    if not inblock:
        
        # Checking the line isn't empty
        if line == '':
            print('WRONG OUTPUT FORMAT, WTF HAPPENED?')
            exit(1)
        
        # The line isn't empty: we reached a new block
        inblock = True
        
        # Splitting DN from its value
        dn, val = line.split(':', 1)
        # Trimming edges
        dn = dn.strip()
        val = val.strip()
        
        # Registering block name
        currentblock = val
        
        # Reseting attribute index
        
        # Registering DN and creating new block
        config[currentblock] = []
        
    # We're in a block
    else:
        
        # The line is empty: we reached the end of the current block
        if line == '':
            # Not in a block anymore
            inblock = False
            currentblock = None
        
        # The line starts with a space: it's the continuation of the previous line
        elif line.startswith(' '):
            # Concatenating current line with previous value
            config[currentblock][-1][1] += line
            
        # The line isn't empty and doesn't start with a space:
        # it's an attribute for the current block
        else:
            # Splitting attribute from its value
            attr, val = line.split(':', 1)
            attr = attr.strip()
            val = val.strip()
            
            # Storing attribute and its value in the current block
            config[currentblock].append([attr, val])

# We're done parsing the search output


# ---------------------------------- #
# Checking slapd configuration facts #
# ---------------------------------- #

def get_attribute_value(dn, attr):
    """
    Returns a list of the values for the given attribute and the given DN 
    in the config dump.
    """
    i = 0
    values = []
   
    while i < len(config[dn]):
        #print config[dn][i]
        if config[dn][i][0] == attr:
            values.append(config[dn][i][1]) # Grabing values
        
        i = i +1
    
    return values

# Is the admin user set properly?
if(params['admin_olcRootDN'] in 
   get_attribute_value('olcDatabase={1}hdb,cn=config', 'olcRootDN')):
    jayout['is_admin_olcRootDN_set'] = True
else:
    jayout['is_admin_olcRootDN_set'] = False

# Is the admin user password set properly?
res = get_attribute_value('olcDatabase={1}hdb,cn=config',
                          'olcRootPW')
if(res == []): # Nothing is set
    jayout['is_admin_olcRootPW_set'] = False
elif(checkpassword(res[0], params['admin_olcRootPW'])): # OK
    jayout['is_admin_olcRootPW_set'] = True
else: # Wrong value set
    jayout['is_admin_olcRootPW_set'] = False

# Is the config user DN set properly?
if(params['config_olcRootDN'] in
   get_attribute_value('olcDatabase={0}config,cn=config', 'olcRootDN')):
    jayout['is_config_olcRootDN_set'] = True
else:
    jayout['is_config_olcRootDN_set'] = False
    
# Is the config user password set properly?
res = get_attribute_value('olcDatabase={0}config,cn=config',
                          'olcRootPW')
if(res == []): # Nothing is set
    jayout['is_config_olcRootPW_set'] = False
elif(checkpassword(res[0], params['config_olcRootPW'])): # OK
    jayout['is_config_olcRootPW_set'] = True
else:  # Wrong value set
    jayout['is_config_olcRootPW_set'] = False

# Pretty printing the config (DEBUG)
# def pretty(d, indent=0):
#     for key, value in d.iteritems():
#       print '\t' * indent + str(key)
#       if isinstance(value, dict):
#          pretty(value, indent+1)
#       else:
#          print '\t' * (indent+1) + str(value)
#            
#            
# pretty(config)    
# print '\n\n\n\n XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \n\n\n\n'
# jayout['slapd_facts']['config'] = config

# Printing JSON output to playbook
print json.dumps(jayout)
