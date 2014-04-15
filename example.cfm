<cfset success = application.cfcs.sftp.SFTPFolder(
	username = "************",
	password = "************",
	fingerprint = "**:**:**:**:**:**:**:**:**:**:**:**:**:**:**:**",
	server = "********",
	local_path = "C:\Users\ian.osullivan\Desktop\temp\",
	remote_path = "/cygdrive/d/Domains/_temp/",
	create_remote_folder = "remote_folder_123456789"
)>

<cfdump var="#success#">