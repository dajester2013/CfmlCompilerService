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
 * Application
 * 
 * @license MIT
 * @author jesse.shaffer
 * @date 11/6/13
 **/
component accessors=true output=false persistent=false {
	
	this.name = "CfmlPackager";
	this.sessionManagement = false;
	this.clientManagement = false;
	
	public function onApplicationStart() {
		if (FileExists("./webadmin.pw")) {
			application.webadminpw = FileRead("./webadmin.pw");
		} else {
			application.webadminpw = CreateUUID();
			FileWrite("./webadmin.pw",application.webadminpw);
			admin action="updatePassword" newPassword=application.webadminpw type="web";
		}
	}
	
	public function onRequest() {
		var input = {};
		
		StructAppend(input,url);
		StructAppend(input,form);
		
		var compiler = new Compiler(input);
		
		compiler.compile();
	}
	
	public function onCfcRequest() {
		throw(message="No direct access.");
	}

}
