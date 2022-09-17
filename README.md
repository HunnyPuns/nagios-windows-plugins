# nagios-windows-plugins
This project is meant to be a call to the official Nagios Plugins Project. Not to compete, but to provide a base set of plugins to monitor Windows systems.

In the end, I aim to have a set of plugins that can be executed over SSH or WinRM.

# Things I Want To Add
- CPU
	- Top N Processes
- Volume
	- Check status of mounts
- Disk
	- Disk operation latency
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
