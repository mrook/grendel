  The Grendel Project - A Windows/Linux MUD Server    
  Copyright (C) 2000-2004 by Michiel Rook <michiel@grendelproject.nl>
    
  Please observe the file "documentation\License.txt" before using this 
  software.

  Redistribution and use in source and binary forms, with or without 
  modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer. 

  * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution. 
  
  Neither the name of The Grendel Project nor the names of its contributors 
  may be used to endorse or promote products derived from this software 
  without specific prior written permission. 

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
  ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR 
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  
          
  -------------------------------------------------------------------------
    
   
  * Introduction:
    
  The Grendel Project is an attempt at creating a solid, fast, and 
  stable MUD server codebase, that runs natively on Windows and Linux. 


  * Changes in this release:

  For the list of changes, see the included ChangeLog file.


  * Requirements

    Windows:

    Grendel requires Winsock2 to be installed. Windows 98/Me/NT4/2000/XP
    are shipped with Winsock2, users of Windows 95 will have to download 
    the following update:

    http://www.microsoft.com/windows/downloads/bin/W95ws2setup.exe

    Linux:

    Glibc version 2.2 or higher and a recent kernel (2.2+) are required.
 
    Grendel does not require you to install the software as root, unless
    you configure the software to open a priviliged (< 1024) port.


  * Features

    - GMC, or Grendel MUD C, is a replacement for the original (limited)
      mobprogs. It's a fully functional language based on C, which
      is compiled and executed in a virtual stackmachine

    - Plugin architecture: code can be grouped and modularized in plugin
      modules, which can be loaded/unloaded during runtime

    - Copyover system a.k.a. hot reboot, more info below
 
    - IPv6 support: Grendel auto-detects and natively supports the new 
      internet protocol, on all Linux machines with an IPv6 enabled kernel, 
      and on NT4/2000/XP machines with the proper software installed
 
    
  * Installation:
    
  The archive you have downloaded, which contains this README file,
  also contains prebuilt binaries for the target operating system.
  The target operating system can be identified by the extension
  of the archive; .zip => Windows, .tar.gz => Linux.
    
  You can install the software in any location you deem useful.
    
    
  * Compilation:
    
  If you want to recompile the binaries, you need the following ingredients:
    
    Linux:
      * Borland Kylix 3
      * GNU make (usually pre-installed on your system)
    		
    Windows:
      * Borland Delphi 6 or higher
      * GNU make (available at 
        http://www.grendelproject.nl/dls/gnumake-win32.zip)  

  If these ingredients are present, you can run 'make' in the directory
  where you've installed Grendel.


  * Running
  
  Starting Grendel is simple. Windows users can click on the 'grendel.exe' 
  icon, or open a console window and start the grendel.exe file manually.
  
  Linux users can either start the executable 'grendel' from an automated 
  script or manually from a terminal. 
  Note: under Linux forks to the background by default, to override this 
  and let Grendel write to stdout run 'grendel -f' instead.
  
  If all is well, you should be able to connect to Grendel by using
  a telnet client to connect to localhost, port 4444. 
  
  
  * Creating immortals
  
  Grendel comes shipped without any users, so you'll have to create your own.
  
  After connecting to Grendel, you should see a brief introductory message,
  and a prompt. Here you can create a new user and explore the example world.
  
  Once you've created a new user, navigate to the 'players' directory,
  and edit the file <your new user>.usr. To 'immortalize' this user,
  change the number on the line with 'Level:' in the range 990-1000, where
  990 is the lowest ranking Immortal, and 1000 the highest.
  
  
  * Using the copyover system
  
  Grendel features a copyover (a.k.a. hot reboot) system similar to that
  of other MUD codebases. It is present in both the Linux and the Windows
  builds, with one difference: the Windows system has the ability to "copy over"
  (hence the name) a new version of the grendel.exe file.

  To achieve this, place the new grendel.exe (and/or core.bpl) in the "bin"
  directory, and start copyover.
  
  
  * Using the service (Windows NT/2000/XP only)
  
  Users of Windows NT/2000/XP have the ability to run Grendel as a background
  service. The advantage of this is that Grendel can start when the computer
  boots, instead of when a user logs in and runs it.
  
  To enable the service, enter 'grendelservice /install', then open
  the Service Control Manager through the menus Programs -> 
  Administrative Tools -> Services. Right-click on the 'Grendel MUD Server'
  service, and select 'start'.  
  
  To uninstall the service, enter 'grendelservice /uninstall'.
  
    
  * Bug reporting:
    
  If you think you have discovered a bug in the code, please use the 
  online bug tracking system available at:
    
    http://www.grendelproject.nl/bt/


  * Documentation

  The manual and other documentation can be found in the "documentation"
  directory.
    
    
  * Contact:
    
  E-Mail: info@grendelproject.nl
  Website: http://www.grendelproject.nl/
    
    
  * Credits:
    
  Michiel Rook (founder/website/code):       michiel@grendelproject.nl
  Hemko de Visser (code/testing):            nemesis@grendelproject.nl
    
  Roeland van Houte (code/inactive):         xenon@grendelproject.nl
  Oscar Martin (code/testing/inactive):      jago@grendelproject.nl
  Jeremiah Davis (documentation/inactive):   N/A
        


  
  If you use and like Grendel, I'd very much appreciate it if you
  send a postcard to me:

  Michiel Rook
  ***REMOVED***
  ***REMOVED***
  The Netherlands
    		
    
  -------------------------------------------------------------------------

  $Id: Readme.txt,v 1.4 2004/04/08 21:28:50 ***REMOVED*** Exp $
