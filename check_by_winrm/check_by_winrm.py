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
    parser = argparse.ArgumentParser(description='check_by_winrm.py executes a Nagios or Nagios compatible plugin on a remote, Windows-based system. It is assumed that the plugin you wish to execute already exists on the Windows system.')
    parser.add_argument('-H', '--host', required=True, type=str, help='IP address or host name of the Windows system.')
    parser.add_argument('-u', '--user', required=True, type=str, help='Username for connecting to the Windows system.')
    parser.add_argument('-a', '--auth', required=True, type=str, choices=['cert', 'kerberos', 'credssp', 'basic-http', 'basic-https'], help='Authentication mechanism for the Windows system. Strongly recommended you avoid basic-http.')
    parser.add_argument('-p', '--password', required=False, type=str, help='Optionally, you can present the password as a command line argument.')
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

if args.password is not None:
    password = args.password

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
        authentication = 'credssp'

    elif args.auth == 'basic-http':
        # Use basic-http Authentication
        authentication = 'basic'

    elif args.auth == 'basic-https':
        # Use basic-https Authentication
        authentication = 'ssl'

    # Create a WinRM session with the provided host, user, password, and authentication method
    winrmsession = winrm.Session(args.host, auth=(args.user, password), transport=authentication)

    # Run the specified plugin command on the remote Windows system
    command = winrmsession.run_ps(args.plugin + ' ' + args.args)

    if not args.silent:
        if command.std_out != b'':
            # Print the standard output of the command if not in silent mode
            print(command.std_out.decode('utf-8').rstrip('\n'))

    service_state = 3

    # Need to parse the output to find the command's status code as PyWinrm or WinRM in general just returns 0 or 1.
    if "CRITICAL" in command.std_out.decode('utf-8'):
        service_state = 2

    elif "WARNING" in command.std_out.decode('utf-8'):
        service_state = 1

    elif "UNKNOWN" in command.std_out.decode('utf-8'):
        service_state = 3

    else:
        service_state = 0

    # Exit with the command's status code
    exit(service_state)

except winrm.exceptions.WinRMTransportError as e:
    logger.error(f"WinRM transport error: {str(e)}")
    exit(1)
except Exception as e:
    logger.error(f"An error occurred during WinRM session setup or command execution: {str(e)}")
    exit(1)
