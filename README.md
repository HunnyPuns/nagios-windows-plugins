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
