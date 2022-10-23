#!/usr/bin/env python3

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
                     type=str,
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

args = parser.parse_args(argv[1:])

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

command = winrmsession.run_ps(pscommand)

if (command.std_out != b''):
    print(command.std_out.decode('utf-8').rstrip('\n'))
# what if standard out is empty?

exit(command.status_code)
