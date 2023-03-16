#!/usr/bin/env python3

import warnings
warnings.simplefilter('ignore')
import winrm
import argparse
from sys import argv

parser = argparse.ArgumentParser()

parser.add_argument( '-H',
                     '--host',
                     required=True,
                     type=str,
                     help='IP address or host name of the Windows system.')
parser.add_argument( '-u',
                     '--user',
                     required=True,
                     type=str,
                     help='Username for connecting to the Windows system.')
parser.add_argument( '-p',
                     '--password',
                     required=True,
                     type=str,
                     help='Password for connecting to the Windows system.')
parser.add_argument( '-a',
                     '--auth',
                     required=True,
                     type=str.lower,
                     choices=['basic-http', 'basic-https'],
                     help='Authentication mechanism for the Windows system. Only supporting basic auth right now. More to come later. NTLM is out because it\'s fucking 30 years old.')
parser.add_argument( '-P',
                     '--plugin',
                     required=True,
                     type=str,
                     help='Full path to plugin on the Windows system. (e.g. C:\plugins\check_memory.py)')
parser.add_argument( '-A',
                     '--args',
                     required=False,
                     type=str,
                     help='Additional arguments for the specified plugin. (e.g. -outputtype GB -metric Used -warning 12 -critical 14)')
parser.add_argument( '-k',
                     '--insecure',
                     required=False,
                     action='store_const',
                     const=1)
parser.add_argument( '-v',
                     '--verbose',
                     required=False,
                     action='store_const',
                     const=1)

args = parser.parse_args(argv[1:])

message = "Nothing changed the return message!"
exitcode = 3
pscommand = ""
validation = ""
transport = ""

if (args.auth == 'basic-http'):
    transport = 'basic'
else:
    transport = 'ssl'

if (args.insecure is not None):
    validation = 'ignore'
else:
    validation = 'validate'


winrmsession = winrm.Session(args.host, auth=(args.user, args.password), transport=transport, server_cert_validation=validation)

if (args.args is not None):
    pscommand = args.plugin + ' ' + args.args
else:
    pscommand = args.plugin

try:
    command = winrmsession.run_ps(pscommand)
except winrm.exceptions.InvalidCredentialsError as Error:
    print("Unable to connect to the specified Windows machine: {0}\nWinRM Error: {1}".format(args.host, Error))
    exit()
except Exception as Error:
    print("Unknown error occurred connecting to the specified Windows machine: {0}\nWinRM Error: {1}".format(args.host, Error))
    exit()

if (args.verbose is 1):
    verboseout = f"""
    *** Verbose Output ***
    \033[{'31;1;4'}m Arguments \033[{'0'}m - {args.__dict__}
    \033[{'31;1;4'}m Session \033[{'0'}m - {winrmsession.__dict__}
    \033[{'31;1;4'}m Command \033[{'0'}m - {command.__dict__}
    """

    print(verboseout)

if (command.std_out != b''):
    message = command.std_out.decode('utf-8').rstrip('\n')
    breakup = message.split(" ")

    if (breakup[0] == "WARNING:"):
        exitcode = 1
    elif (breakup[0] == "CRITICAL:"):
        exitcode = 2
    elif (breakup[0] == "UNKNOWN:"):
        exitcode = 3
    else:
        exitcode = 0

print(message)
exit(exitcode)
