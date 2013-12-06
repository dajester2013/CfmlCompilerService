/* The MIT License (MIT)
 * 
 * Copyright (c) 2013 dajester2013
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/**
 * Compiler
 * 
 * @license MIT
 * @author jesse.shaffer
 * @date 11/13/13
 **/
component accessors=true output=false {

	property string		SourceDir		;
	property string		DestDir			;
	property string		Includes		;
	property string		Excludes		;
	property any		AuxMappings		;
	property boolean	AsArchive		default=false;
	property string		FileName		default="rcs-compiled-#gettickcount()#.ra";
	property boolean	CompileInPlace	default=false;
	property boolean	Verbose			default=true;
	property boolean	CompileInPlace	default=false;
	property boolean	IncludeCFML		default=false;
	property boolean	IncludeStatic	default=false;
	
	private function instructions() {
		println("failed.");
		println();		
		println("Usage:");
		println();
		println("Example: http://localhost:8080/rcs/?SourceDir=/opt/cfml/apps/railo/MyProject&DestDir=/opt/cfml/apps/railo/MyProject/build/compiled");
		println();
		println("Required URL parameters:");
		println("------------------------");
		println(" * SourceDir (String)            -> The source code directory");
		println();
		println("   and one of the following (mutually exclusive):")
		println(" * DestDir (String)              -> The destination directory to place the compiled files");
		println(" * CompileInPlace (Boolean)      -> The source code directory");
		println();
		println("Optional URL parameters:");
		println("------------------------");
		println(" * AsArchive (Boolean=false)     -> Whether or not to export compile the source directory into an archive.");
		println("                                    The default is to export all files in SourceDir to DestDir, compiling the templates in the process.");
		println("                                    NOTE: When using this option, the Includes/Excludes options are ignored.");
		println(" * AuxMappings (JSON="""")         -> A JSON-encoded array of auxiliary mappings, ex. [{""virtual"":""/framework"",""physical"":""/opt/cfml/framework""}]");
		println("                                    NOTE: Builds requiring auxiliary mappings are limited to one at a time. Builds not requiring auxiliary mappings always execute immediately.");
		println(" * Verbose (Boolean=true)        -> Print a verbose log.");
		println();
		println("Parameters when AsArchive=false:");
		println("--------------------------------");
		println(" * Includes (String="""")          -> A mask similar to Ant's fileset includes, ex. src/"&"**");//
		println(" * Excludes (String="""")          -> A mask similar to Ant's fileset excludes, ex. build/"&"**");
		println();
		println("Parameters when AsArchive=true:");
		println("-------------------------------");
		println(" * FileName (String="""")          -> The name of the archive file to export.  Ignored if AsArchive is false.");
		println(" * IncludeCFML (Boolean=false)   -> The name of the archive file to export.  Ignored if AsArchive is false.");
		println(" * IncludeStatic (Boolean=false) -> The name of the archive file to export.  Ignored if AsArchive is false.");
		
		print("</pre>");/**/
		abort;
	}
	
	/**
	 * Checks preconditions.  Prints instructions when conditions are not met.
	 **/
	private function checkPreconditions() {
		if (!structKeyExists(server,"railo") || val(server.railo.version) < 4.1) {
			instructions(); //throw("Expected to run on Railo server version 4.1+");
		}
		
		if (isNull(this.getSourceDir()))
			instructions(); //throw("SourceDir was not passed. Please supply source directory as ""SourceDir"".");

		if (isNull(this.getDestDir()) && !this.getCompileInPlace())
			instructions(); //throw("DestDir was not passed. Please supply destination directory as ""DestDir"".");
		else if (this.getCompileInPlace())
			this.setDestDir(this.getSourceDir());

		if(!isNull(this.getAuxMappings()))
			this.setAuxMappings(DeserializeJSON(this.getAuxMappings()));
		else
			this.setAuxMappings([]);
		
		if(!isNull(this.getIncludes())) {
			this.setIncludes(this.getIncludes().replaceAll("\.","\.").replaceAll("\s+|,","|").replaceAll("\*\*",".*").replaceAll("(?<!\.)\*","[^\\/]").replaceAll("(?<!\/)(\.\*\/)","$1?"));
		}
		if(!isNull(this.getExcludes())) {
			this.setExcludes(this.getExcludes().replaceAll("\.","\.").replaceAll("\s+|,","|").replaceAll("\*\*",".*").replaceAll("(?<!\.)\*","[^\\/]").replaceAll("(?<!\/)(\.\*\/)","$1?"));
		}
		
		if (right(this.getSourceDir(),1) != server.separator.file)
			this.setSourceDir(this.getSourceDir() & server.separator.file);
		if (right(this.getDestDir(),1) != server.separator.file)
			this.setDestDir(this.getDestDir() & server.separator.file);
		
	}

	/**
	 * Determines whether or not a lock is necessary to 
	 **/
	package function compile() {
		print("<pre>");/**/
		println("--------------------------------------------------------------------------------");
		println("- Railo Source Compiler V1.0                                                   -");
		println("--------------------------------------------------------------------------------");
		
		println();
		
		print("Checking preconditions...");
			checkPreconditions();
		println("pass.");
		
		println();
		println("Running with the following options:");
		println("-----------------------------------");
		for (p in getmetadata(this).properties) {
			print(p.name);
			for (var i=len(p.name); i<=19; i++) print(" ");
			print(" = ");
			print(serializeJson(isNull(variables[p.name]) ? "" : variables[p.name]));
			println();
			
			//println("#p.name# = #serializejson(isNull(variables[p.name]) ? '' : variables[p.name])#");
		}
		println();
		
		setting requesttimeout=10000;
		
		if (this.getAsArchive())
			if (arraylen(this.getAuxMappings()))
				lock name="RCS-COMPILE" timeout=10000 { _archive(); }
			else
				_archive();
		else
			if (arraylen(this.getAuxMappings()))
				lock name="RCS-COMPILE" timeout=10000 { _compile(); }
			else
				_compile();
	}
	
	private function _setup() {
		variables.started	= gettickcount();
		variables.compileId	= "RCOMP-" & CreateUUID();
		variables.mapping	= "/" & compileId;
		
		print("Creating temporary mapping...");
			createMapping(virtual=mapping,physical=this.getSourceDir());
		println("done.");
		
		if (arraylen(this.getAuxMappings())) {
			println("Creating auxiliary mappings...");
				for (var auxmap in this.getAuxMappings()) {
					println(" * " & auxmap.virtual & " = " & auxmap.physical);
					createMapping(argumentCollection=auxmap);
				}
			println("done.");
		}
	}
	
	private function _cleanup() {
		if (arraylen(this.getAuxMappings())) {
			print("Cleanup auxiliary mappings...");
				for (var auxmap in this.getAuxMappings())
					removeMapping(virtual=auxmap.virtual);
			println("done.");
		}
		
		print("Cleanup temporary mapping...");
			removeMapping(virtual=mapping);
		println("done.");
		
		println();
		if (!this.getVerbose())
			return 0;
		else
			print("Finished in #(gettickcount()-started)/1000# seconds.</pre>");/**/
	}
	
	private function _compile() {
		_setup();
		
		var srcListing		= DirectoryList(this.getSourceDir(),true);
		var tmpdir			= GetTempDirectory() & mapping;
		var cdir			= tmpdir & "/compiled";
		
		try {
			println();
			print("Compiling mapping...");
				DirectoryCreate(tmpdir);
				compileMapping(virtual=mapping);
				
				for (var mappingdir in DirectoryList("/WEB-INF/railo/cfclasses/",false,"array")) {
					if (mappingdir.startsWith(expandpath("/WEB-INF/railo/cfclasses/") & "CF" & expandpath(mapping).replaceAll("[^A-Za-z0-9]","_"))) {
						cdir = mappingdir;
						break;
					}
				}
			println("done.");
			println();
			
			if (!DirectoryExists(this.getDestDir())) {
				println("Creating destination directory #this.getDestDir()#.");
				DirectoryCreate(this.getDestDir());
			}
			
			println("Copying files...");
			var fileCt = 0;
			for (var file in srcListing) {
				var subpath = file.replace(this.getSourceDir(),"").replaceAll("\\","/");
				var destpath = this.getDestDir() & subpath;
				var destfile = GetFileFromPath(destpath);
				var destdir = GetDirectoryFromPath(destpath);
				
				if (	(!isNull(this.getExcludes()) && (subpath).matches(this.getExcludes()))
					or	(!isNull(this.getIncludes()) && !(subpath).matches(this.getIncludes())))
					continue;
				
				if (!DirectoryExists(destdir)) {
					println(" / " & destdir);
					DirectoryCreate(destdir);
				}
				
				if (DirectoryExists(file)) {
					println(" / " & subpath);
					if (!DirectoryExists(destdir))
						DirectoryCreate(destdir);
				} else if (FileExists(file)) {
					//var cfile = GetDirectoryFromPath(subpath) & lcase(destfile).replaceAll("\.(cf(c|ml?|r))","_$1\$cf.class");
					var cfile = getpagecontext().getpagesource(mapping & "/" & subpath).getjavaname() & ".class";
					
					if (FileExists(cdir & cfile)) {
						println(" - " & subpath);
						FileCopy(cdir & cfile,destpath);
					} else {
						println(" - " & subpath);
						FileCopy(file,destpath);
					}
					fileCt++;
				}
			}
			
			// TODO : copy noncfml files
			
			print("Cleanup temporary files...");
			println("done.");
			print("Compiled/copied ");print(fileCt);print(" files in ");print((gettickcount()-started)/1000);println(" seconds or #filect/((gettickcount()-started)/1000)# files/second.");
			println();
		} catch(any e) {
			println("error.");
			writedump(var=e,format="text");
			GetPageContext().getResponse().setStatus(500);
		}
		
		DirectoryDelete(tmpdir,true);
		println("done.");
		
		_cleanup();
	}
	
	private function _archive() {
		_setup();
		
		println();
		
		print("Creating archive #this.getDestDir() & this.getFileName()#...");
		createArchive(virtual=mapping,file=this.getDestDir() & this.getFileName(),addCFMLFiles=this.getIncludeCFML(),secured=true,addNonCFMLFiles=this.getIncludeStatic(),append=false);
		println("done.");
	
		println();
		
		_cleanup();
	}
	
	private query function listMappings() {
		return doAdminTask(action="getMappings",expectReturn=true);
	}
	
	private function createMapping(string archive="",primary="",toplevel=true) {
		arguments.action = "updateMapping";
		doAdminTask(argumentCollection=arguments);
	}
	
	private function removeMapping() {
		arguments.action = "removeMapping";
		doAdminTask(argumentCollection=arguments);
	}
	
	private function createArchive() {
		arguments.action = "createArchive";
		arguments.stopOnError = "false";

		doAdminTask(argumentCollection=arguments);
	}
	
	private function compileMapping() {
		arguments.action = "compileMapping";
		arguments.stopOnError = "false";

		doAdminTask(argumentCollection=arguments);
	}
	
	private any function doAdminTask(boolean expectReturn=false) {
		var getrv = arguments.expectReturn;
		var retval = "";

		if (getrv)
			arguments.returnvariable="retval";

		arguments.type = "web";
		arguments.password = application.railopw;
		structDelete(arguments,"expectReturn");

		admin attributeCollection=arguments;

		if (getrv)
			return retval;
	}
	
	private void function print(msg="") {
		if (this.getVerbose()) {
			writeoutput(toString(msg));
			flush;
		}
	}
	private void function println(msg="") {
		print(msg);
		print("<br />");/**/	
	}
	
}
