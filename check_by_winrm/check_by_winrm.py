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
                     choices=['basic', 'cert', 'kerberos', 'credssp'],
                     help='Authentication mechanism for the Windows system. Right now we can do basic. :|')
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

args = parser.parse_args(argv[1:])

winrmsession = winrm.Session(args.host, auth=(args.user, args.password))

command = winrmsession.run_ps(args.plugin + ' ' + args.args)

if (command.std_out != b''):
    print(command.std_out.decode('utf-8').rstrip('\n'))
# what if standard out is empty?

exit(command.status_code)
