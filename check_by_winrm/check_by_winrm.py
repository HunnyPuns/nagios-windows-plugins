#!/usr/bin/env python3

import winrm
import argparse
import getpass
import os
import keyring
import logging
from sys import argv

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

try:
    # Parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-H', '--host', required=True, type=str, help='IP address or host name of the Windows system.')
    parser.add_argument('-u', '--user', required=True, type=str, help='Username for connecting to the Windows system.')
    parser.add_argument('-a', '--auth', required=True, type=str, choices=['cert', 'kerberos', 'credssp'], help='Authentication mechanism for the Windows system.')
    parser.add_argument('-P', '--plugin', required=True, type=str, help='Full path to plugin on the Windows system. (e.g. C:\plugins\check_memory.py)')
    parser.add_argument('-A', '--args', required=False, type=str, help='Additional arguments for the specified plugin. (e.g. -outputtype GB -metric Used -warning 12 -critical 14)')
    parser.add_argument('-s', '--silent', action='store_true', help='Silent mode without printing to stdout.')

    args = parser.parse_args(argv[1:])
except argparse.ArgumentError as e:
    logger.error(f"Argument error: {str(e)}")
    exit(1)
except Exception as e:
    logger.error(f"An error occurred during argument parsing: {str(e)}")
    exit(1)

if not any(vars(args).values()):
    parser.print_help()
    exit(1)

password = None

if not password:
    # Prompt for password input securely
    password = getpass.getpass('Password: ')

if not password:
    # Check if password is provided as an environment variable
    password = os.environ.get('WINRM_PASSWORD')

if not password:
    # Retrieve password from keyring if available
    password = keyring.get_password('your_application', 'your_username')

if not password:
    logger.error("Password not provided. Exiting...")
    exit(1)

try:
    authentication = None

    if args.auth == 'cert':
        # Use Certificate Authentication (TLS transport with SSL enabled)
        authentication = winrm.transport.TlsTransport(ssl=True)

    elif args.auth == 'kerberos':
        # Use Kerberos Authentication
        authentication = winrm.transport.KerberosTransport()

    elif args.auth == 'credssp':
        # Use CredSSP Authentication
        authentication = winrm.transport.CredSSPTransport()

    # Create a WinRM session with the provided host, user, password, and authentication method
    winrmsession = winrm.Session(args.host, auth=(args.user, password), transport=authentication)

    # Run the specified plugin command on the remote Windows system
    command = winrmsession.run_ps(args.plugin + ' ' + args.args)

    if not args.silent:
        if command.std_out != b'':
            # Print the standard output of the command if not in silent mode
            print(command.std_out.decode('utf-8').rstrip('\n'))

    # Exit with the command's status code
    exit(command.status_code)

except winrm.exceptions.WinRMTransportError as e:
    logger.error(f"WinRM transport error: {str(e)}")
    exit(1)
except Exception as e:
    logger.error(f"An error occurred during WinRM session setup or command execution: {str(e)}")
    exit(1)
