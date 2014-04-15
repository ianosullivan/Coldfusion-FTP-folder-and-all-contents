<cfcomponent>


	<cffunction name="SFTPFolder" description="Create an SFTP Connection and then call function to SFTP the FOLDER and all it's contents to a remote location. Remote sub folders are created if necessary"
			hint="This is only for SFTP" returntype="boolean">
		<cfargument name="username" required="true" type="string">
		<cfargument name="password" required="true" type="string">
		<cfargument name="server" required="true" type="string">
		<cfargument name="fingerprint" required="true" type="string">
		<cfargument name="timeout" required="true" type="numeric" default="300">
		<cfargument name="local_path" required="true" type="string" default="">
		<cfargument name="remote_path" required="true" type="string" default="">
		<cfargument name="create_remote_folder" required="true" type="string" default="">

		<!--- Open an SFTP connection --->
		<cfftp action = "open"
			connection = "MyConnection"
			username = "#username#"
			password = "#password#"
			fingerprint = "#fingerprint#"
			server = "#server#"
			timeout = "#timeout#"
			secure = "yes"
			stopOnError = "No">

		<!--- If an SFTP connection has been made --->
		<cfif cfftp.Succeeded EQ "YES">

			<!--- SFTP folder contents --->
			<cfset application.cfcs.sftp.SFTPFolderContents(
				local_path = "#local_path#",
				remote_path = "#remote_path#",
				create_remote_folder = "#create_remote_folder#"
			)>

			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>

	</cffunction>


	<cffunction name="SFTPFolderContents" description="SFTP a FOLDER and all it's contents to a remote location. Remote folders are created if necessary" hint="This is only for SFTP">
		<cfargument name="local_path" required="true" type="string" default="">
		<cfargument name="remote_path" required="true" type="string" default="">
		<cfargument name="create_remote_folder" required="true" type="string" default="">

		<!--- Add slash to end of local path if necessary --->
		<cfif Right(local_path, 1) NEQ "\">
			<cfset local_path = local_path & "\">
		</cfif>

		<!--- Add slash to end of remote path if necessary --->
		<cfif Right(remote_path, 1) NEQ "/">
			<cfset remote_path = remote_path & "/">
		</cfif>

		<!--- Get the local directory contents --->
		<cfdirectory directory="#local_path#" name="local_dir_contents" action="list">

		<!--- Check if create_remote_folder exists --->
		<cfftp action="existsDir"
			 connection="MyConnection"
			 directory="#remote_path##create_remote_folder#"
			 stopOnError = "No">

		<!--- If it doesn't exist create it --->
		<cfif cfftp.succeeded NEQ "YES">
			<!--- Create directory --->
			<cfftp action="createDir"
				 connection="MyConnection"
				 directory="#remote_path##create_remote_folder#"
				 stopOnError = "No">
		</cfif>

		<!--- Loop through contents and put the file on the SFTP server --->
		<cfloop query="local_dir_contents">

			<cfif local_dir_contents.type EQ "File">
				<!--- Put the file on the server --->
				<cfftp action="putFile"
					 connection="MyConnection"
					 localFile="#local_path##local_dir_contents.name#"
					 remoteFile="#remote_path##create_remote_folder#/#local_dir_contents.name#">
			<cfelse>
				<!--- Recursively call THIS function with the new directory --->
				<!--- Recursively call THIS function with the new directory --->
				<cfset SFTPFolderContents(
					local_path = "#local_path#\#local_dir_contents.name#\",
					remote_path = "#remote_path#/#create_remote_folder#",
					create_remote_folder = "/#local_dir_contents.name#"
				)>
				<!--- Recursively call THIS function with the new directory --->
				<!--- Recursively call THIS function with the new directory --->
			</cfif>

		</cfloop>

	</cffunction>


</cfcomponent>