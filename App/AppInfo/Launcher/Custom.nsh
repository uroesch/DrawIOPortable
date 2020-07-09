; -----------------------------------------------------------------------------
; Custom Java Locator with a preference on OpenJDK as it generally works
; great with DBeaver
; Author: Urs Roesch <github@bun.ch>
; Disclaimer: I fudged myself through this not fully understanding every
;   NSIS concept.
;   Large parts of the code are copied verbatim from the Java/Init segment tho.
; -----------------------------------------------------------------------------

${SegmentFile}

${SegmentInit}
	; If [Activate]:Java=find|require, search for Java in the following
	; locations (in order):
	;
	;  - PortableApps.com CommonFiles (..\CommonFiles\{Java,JDK,JRE})
	;  - Registry (HKLM\Software\JavaSoft\Java Runtime Environment)
	;  - %JAVA_HOME%
	;  - Anywhere in %PATH% (with SearchPath)
	;  - %WINDIR%\Java (from Windows 98, probably obsolete now we don't it)
	;
	; If it's in none of those, give up. [Activate]:Java=require will then
	; abort, [Activate]:Java=find will set it to the non-existent CommonFiles
	; location. %JAVA_HOME% is then set to the location.
	
	ClearErrors
	${If} $Bits != 64
		MessageBox MB_OK|MB_ICONSTOP "This version of draw.io requires a 64bit runtime environment."
		Quit
	${EndIf}
!macroend
