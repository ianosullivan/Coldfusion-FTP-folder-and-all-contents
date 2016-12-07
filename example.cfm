<cfset local_path = "d:\path\to\folder\ftp-this-folder">

<!--- Standard FTP --->
<!--- Note that 'debug_mode' is not an argument of the function 'SFTPFolder()' but it is actually a component variable --->
<cfset ftp = $.sftp.SFTPFolder(
	username = 'username',
	password = 'your-password',
	server = '192.168.1.1',
	local_path = local_path
)>
