# nagios-windows-plugins
This project is meant to be a call to the official Nagios Plugins Project. Not to compete, but to provide a base set of plugins to monitor Windows systems.

In the end, I aim to have a set of plugins that can be executed over SSH or WinRM.


# The notes so far!

For the moment, I've settled on just creating Powershell plugins. I'll need a basic set of plugins to get started. That will include:
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
	- Ratio reads to writes
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
