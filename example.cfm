<cfset folder = "d:\path\to\folder\ftp-this-folder-the-server">

<!--- Standard FTP --->
<cfset ftp = application.cfcs.sftp.SFTPFolder(
	username = 'username',
	password = 'your-password',
	server = 'insert.destination.server.address.here',
	local_path = folder
)>
