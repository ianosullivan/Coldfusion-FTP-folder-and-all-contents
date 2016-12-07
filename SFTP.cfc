<cfcomponent>

	<!--- For debugging output set this to true --->
	<cfset debug_mode = false> <!--- This variable can be overwritten by passing it in via the calling function SFTPFolder(). This is why it not place in the 'this' scope --->
	<cfset this.stop_on_error = "No"> <!--- Needs to be NO so that code will not fail during FTP 'existsDir' FTP operation on line 195. I think this may be a CF bug - http://stackoverflow.com/questions/25872961/in-coldfusion-cfftp-existsdir-generate-error-if-dir-doesnt-exist --->


	<cffunction name="SFTPFolder" description="Create an SFTP Connection and then call function to SFTP the FOLDER and all it's contents to a remote location. Remote sub folders are created if necessary"
			hint="This is for both SFTP and FTP" returntype="any">
		<cfargument name="username" required="true" type="string">
		<cfargument name="password" required="true" type="string">
		<cfargument name="server" required="true" type="string">
		<cfargument name="local_path" required="true" type="string" default="">
		<cfargument name="timeout" required="false" type="numeric" default="3600" hint="1 hour">
		<cfargument name="secure" required="false" type="string" default="false" hint="SFTP (yes) or FTP (no)">
		<cfargument name="remote_path" required="false" type="string" default="/" hunt="Optionally don't use the default FTP location.">
		<cfargument name="fingerprint" required="false" type="string" hint="Only required for SFTP">
		<cfargument name="public_key" required="false" type="boolean" default="false" hint="Does this server use the putty - public key authentication. Note: Lucee does not support authentication by public key.">
		<cfargument name="port" required="false" type="numeric" default="21" hint="Only required if the default port is different">

		<cftry>

			<!--- Check that the local directory exists --->
			<cfif directoryExists(local_path)>

				<cfset local.return_struct.success = true> <!--- Assume everything will work --->
				<cfset local.return_struct.message = ''> <!--- No message --->

				<!--- Add a slash to end of remote_path if necessary --->
				<cfif right(remote_path, 1) NEQ "/">
					<cfset remote_path &= "/">
				</cfif>

				<cfif debug_mode>
					<cfoutput>
						<br />local_path="#local_path#"
						<br />remote_path="#remote_path#"
					</cfoutput>
				</cfif>

				<!--- Assuming this store does not use public key --->
				<cfif public_key>
					<!--- This store uses putty / public key --->
					<cfftp action = "open"
						connection = "ftp_connection"
						server = "#server#"
						username = "#username#"
						key = "#application.putty.key_location#"
						passphrase = "#application.putty.pass_phrase#"
						secure ="yes"
						timeout = "#timeout#"
						port = "#port#"
						stoponerror="#this.stop_on_error#">

				<cfelse> <!--- Putty not used --->

					<!--- If SFTP --->
					<cfif secure EQ 'yes'>

						<!--- Open an SFTP connection --->
						<cfftp action = "open"
							connection = "ftp_connection"
							username = "#username#"
							password = "#password#"
							fingerprint = "#fingerprint#"
							secure = "yes"
							server = "#server#"
							timeout = "#timeout#"
							port = "#port#"
							stoponerror="#this.stop_on_error#">

					<cfelse> <!--- FTP (not 'secure') --->

						<!--- Open an FTP connection (without a fingerprint as only SFTP uses fingerprint) --->
						<cfftp action = "open"
							connection = "ftp_connection"
							username = "#username#"
							password = "#password#"
							secure = "no"
							server = "#server#"
							timeout = "#timeout#"
							port = "#port#"

							passive="true"

							stoponerror="#this.stop_on_error#">
					</cfif>
				</cfif>

				<cfif debug_mode>
					<br />cfftp.Succeeded:<cfoutput>#cfftp.Succeeded#</cfoutput>
				</cfif>

				<!--- If an SFTP connection has been made --->
				<cfif cfftp.Succeeded EQ "YES">

					<cfif debug_mode>
						<br />Calling SFTPFolderContents()
					</cfif>

					<!--- SFTP folder contents --->
					<cfset local.ftp_folder = SFTPFolderContents(
						local_path = "#local_path#",
						remote_path = "#remote_path#",
						timeout = "#timeout#",
						debug_mode = debug_mode
					)>

					<!--- Check SFTPFolderContents() was a success --->
					<cfif local.ftp_folder.success>
						<cfftp action="close" connection="ftp_connection">
					<cfelse>
						<cfreturn local.ftp_folder>
					</cfif>

				</cfif>
				<!--- FTP has completed so we can now try to delete the locally created store-specific package directory so as to free up space --->
				<!--- <cftry>
					<cfset directoryDelete(local_path, true)>
					<cfcatch type="any"></cfcatch>
				</cftry> --->

				<cfreturn local.return_struct>

			<cfelse> <!--- Local directory does not exist --->
				<cfset local.return_struct.success = false>
				<cfset local.return_struct.message = 'Local directory does not exist'>

				<cfreturn local.return_struct>

			</cfif>	<!--- END // Test if local directory exists --->


		<cfcatch type="any" name="e"> <!--- Catch any error --->
			<cfset local.return_struct.success = false>
			<cfset local.return_struct.message = e.message>

			<cfreturn local.return_struct>
		</cfcatch>
		</cftry>

	</cffunction>


	<cffunction name="SFTPFolderContents" description="SFTP a FOLDER and all it's contents to a remote location. Remote folders are created if necessary" returntype="struct">
		<cfargument name="local_path" required="true" type="string" default="">
		<cfargument name="remote_path" required="true" type="string" default="">
		<cfargument name="timeout" required="true" type="numeric" default="1800" hint="1800 seconds / 30 minutes">

		<cftry>
			<cfset local.return_struct.success = true> <!--- Assume everything works --->
			<cfset local.return_struct.message = ''> <!--- No message --->

			<cfset local.localFile = '' /> <!--- Made up of the local path + the file name --->
			<cfset local.remoteFile	= '' />
			<cfset local.local_dir_contents	= '' /> <!--- This is the local path directory contents --->

			<cfif debug_mode>
				<br /><br />* * * * * * * * * * * * * * * * In SFTPFolderContents() * * * * * * * * * * * * * * * *
			</cfif>

			<!--- Append current local directory to the remote path --->
			<cfset remote_path &= ListLast(local_path, "\") & "/">
			<!--- Add slash to end of local path if necessary --->
			<cfif Right(local_path, 1) NEQ "\">
				<cfset local_path &= "\">
			</cfif>

			<cfif debug_mode>
				<br />local_path: <cfoutput>#local_path#</cfoutput>
				<br />ListLast: <cfdump var="#ListLast(local_path, '\')#">
				<br />remote_path: <cfoutput>#remote_path#</cfoutput>
			</cfif>

			<!--- Check if remote_dir exists. If it doesn't then we need to create it --->
			<cfftp action="existsDir"
				 connection="ftp_connection"
				 directory="#remote_path#"
				 stoponerror="#this.stop_on_error#">

			<cfif debug_mode>
				<br />remote_path already exists: <cfoutput>#cfftp.Succeeded#</cfoutput>
			</cfif>

			<!--- If it doesn't exist create it --->
			<cfif cfftp.succeeded NEQ "YES">

				<cfif debug_mode>
					<br />Starting createDir
				</cfif>

				<!--- Create directory --->
				<cfftp action="createDir"
					 connection="ftp_connection"
					 directory="#remote_path#"
					 stoponerror="#this.stop_on_error#">
			</cfif>

			<!--- Get the local directory contents --->
			<cfdirectory directory="#local_path#" name="local_dir_contents" action="list">

			<cfif debug_mode>
				<cfdump var="#local_dir_contents#" label="local_dir_contents">
			</cfif>

			<!--- Loop through contents and put the file on the (S)FTP server --->
			<cfloop query="local_dir_contents">

				<cfif debug_mode>55555555<br /></cfif>

				<!--- Are we processing a file or directory? --->
				<cfif local_dir_contents.type EQ "File">

					<cfset localFile="#local_path##local_dir_contents.name#">
					<cfset remoteFile="#remote_path##local_dir_contents.name#">

					<cfif debug_mode>
						66666666<br />
						localFile: <cfdump var="#localFile#"><br />
						remoteFile: <cfdump var="#remoteFile#"><br />
						remote_path:<cfdump var="#remote_path#"><br />
						timeout: <cfdump var="#timeout#"><br />
					</cfif>

					<!--- Put the file on the server. --->
					<cfftp action="putFile"
						 connection="ftp_connection"
						 localFile="#localFile#"
						 remoteFile="#remoteFile#"
						 timeout="#timeout#"
						 passive="true">

				<cfelse> <!--- It's a directory --->

					<cfif debug_mode>
						77777777<br />
						local_path: <cfdump var="#local_path##local_dir_contents.name#"><br />
						remote_path: <cfdump var="#remote_path##local_dir_contents.name#"><br />
						<br /><br />* * * * * * * * * * * * * * * * Recursivlely calling SFTPFolderContents() * * * * * * * * * * * * * * * *<br />
					</cfif>

					<!--- Recursively call THIS function with the new directory --->
					<cfset local.ftp_folder = SFTPFolderContents(
						local_path = "#local_path##local_dir_contents.name#",
						remote_path = "#remote_path#",
						timeout = "#timeout#"
					)>

					<!--- Check SFTPFolderContents() was a success --->
					<cfif !local.ftp_folder.success>
						<cfreturn local.ftp_folder>
					</cfif>

				</cfif>

			</cfloop>

			<cfif debug_mode>
				<br />* * * * * * * * * * * * * * * * Leaving SFTPFolderContents() * * * * * * * * * * * * * * * *<br />
			</cfif>

			<cfreturn local.return_struct>

		<cfcatch type="any" name="e"> <!--- Catch any error --->
			<cfset local.return_struct.success = false>
			<cfset local.return_struct.message = e.message>

			<cfreturn local.return_struct>
		</cfcatch>
		</cftry>
	</cffunction>


</cfcomponent>
