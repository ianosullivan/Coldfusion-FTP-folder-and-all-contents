Use this component to FTP or SFTP a folder and all it's contents (including subdirectories and subdirectory contents). 

This works for FTP, SFTP and public key authentication. The default function call assumes basic 'FTP'.

This is a recursive function so it will continue to find and transfer subdirectories until there are no more.

There are multiple optional paramaters;
* secure - SFTP (yes) or FTP (no)
* remote_path - Optionally don't use the default FTP location.
* fingerprint - Only required for SFTP
* public_key - Does this server use the putty - public key authentication. Note: Lucee does not support authentication by public key.
* port - Only required if the default port is different
* timeout - Extend the timeout period

To turn on 'debug_mode' set debug_mode = true at the top of the component.
