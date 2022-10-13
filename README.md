# nagios-windows-plugins
This project is meant to be a call to the official Nagios Plugins Project. Not to compete, but to provide a base set of plugins to monitor Windows systems.

In the end, I aim to have a set of plugins that can be executed over SSH or WinRM.

# Agentless Execution
## SSH
The original goal for these plugins was to be executed via SSH. Microsoft ported OpenSSH to Windows back in like 2018, so I'm calling it agentless. I didn't need to create a way to use these plugins via SSH, because the base Nagios Plugins Project comes with check_by_ssh, which works with Windows. (Pro-tip: Don't use ssh-copy-id from a Linux machine to a Windows box. If you do, the authorized_keys file will be half-created, and using some weird format, making you change it back to UTF-8 before you can use keys.)

## WinRM
I've created check_by_winrm.py. This works, barely. It only uses basic authentication right now, and there is no error handling. :(

# Testing
I would definitely appreciate any help with testing the plugins or the WinRM checker thingey. Feedback in the form of bug reports and/or pull requests is always appreciated! <3

# Installation
## Windows Side
The Windows side of the configuration is going to be pretty easy. Create a directory where you want your plugins to live, and put the .ps1 scripts there. For the purposes of this walkthrough, let's call that directory `C:\Plugins`

### WinRM Configuration
It strikes me that people are going to be eager to get something running over WinRM rightthefscknow. Okay, I am providing a way to do that. But please, please, please understand that what I am about to propose is *absolutely not secure* and I would never recommend it be done in a production environment, and I would actively fight against it being done on any internet-facing server.

But for *testing purposes*, here's how we can configure WinRM, so we can execute Nagios plugins via WinRM.
On your Windows system, in a Powershell terminal, run the following commands:
`winrm set winrm/config/service @{Basic="true"}`
`winrm set winrm/config/service/auth @{Basic="true"}`

What have we done here? The transport is going to be basic HTTP, and the authentication is going to be plaintext. Technically it's base64 encoded, but for those not in the know, you run a password through a base64 encoder, you get the base64 string. You run a base64 string through a base64 encoder, you get the password. No tricks, no keys, no hashes, no gods, no masters. Please do not do this in production.

## Nagios Side
The very first thing you'll want to do is put the check_by_winrm.py script in the directory where the rest of your Nagios plugins live. Usually `/usr/local/nagios/libexec/` . Make sure that the script is owned by nagios:nagios, and that it is chmod 754.

#### Create A Command
First we create a command in the command configuration file. Typically this is located at `/usr/local/nagios/etc/command.cfg` . We'll create a command for the `check_by_winrm.py` script, which is what will be doing the heavy lifting.

```
define command {
	command_name	check-by-winrm
	command_line	$USER1$/check_by_winrm.py -H $HOSTADDRESS$ -u $ARG1$ -p $ARG2$ -a $ARG3$ -P $ARG4$ -A $ARG5$
}
```

#### Create A Service Check
This is where things can take a turn, because people often have their own way of laying out their host and service configuration files. Let's create an example CPU usage check.

```
define service {
	host_name		your-host
	service_description	CPU Usage
	use		generic_service
	check_command	check-by-winrm!'administrator'!'Temp1234'!'basic'!'C:\Plugins\check_cpu.ps1'!'-warning 80 -critical 90'
}
```


# Things I Want To Add
- CPU
	- Top N Processes
- Volume
	- Check status of mounts
- Disk
	- Disk operation latency
	- People seem to want a plugin that just checks all disks, without specifying each one... Like, wut? Okay, I'll put it on the list.
- Patch Status


# The Plugins So Far
- CPU
	- Used PCT
- Memory
	- Physical
	- Virtual
	- Total Available
		- MB/GB/TB
		- PCT
	- Total Used
		- MB/GB/TB
		- PCT
- Disk
	- Read I/O
	- Write I/O
- Volume
	- Used
		- MB/GB/TB/PB
		- PCT
	- Free
		- MB/GB/TB/PB
		- PCT
- User
	- Count
	- List
- Process
	- Count
	- Memory
	- CPU
- Service
	- Running/Stopped
- Files
	- Exists/ShouldNotExist
	- Size
	- Number of files
