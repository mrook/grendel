The Grendel Project - A Windows/Linux MUD Server    (c) 2000-2004 by Michiel Rook



= Last minute information =======================================================


1. Introduction

It's time for a new Grendel release, this one is focused on fixing
a few licensing issues, kindly pointed out by KaVir (kavir@kavir.org).

Check the file "ChangeLog" for the details.

Enjoy!

  Michiel


2. Features

Grendel requires Winsock2 to be installed. Windows 98, Me, NT4 and 2000
all come with this preinstalled, Windows 95 users will have to download
this update from the Microsoft site:

  http://www.microsoft.com/windows/downloads/bin/W95ws2setup.exe

  - GMC, or Grendel MUD C, is a replacement for the original (limited)
    mobprogs. It's a fully functional language based on C, which
    runs in Grendel using virtual machinecode - very speedy & flexible
  - Modularized mud: most functionality has been placed inside seperate
    modules which can be loaded/unloaded at will - this opens up
    the possibility of arbitrary code that can be loaded even
    while your server is running!
  - Linux support: Grendel now runs on Linux, using the new Kylix
    compiler from Borland (the Linux version of Delphi). 
    Note: this is entirely experimental, some features are missing
    (like copyover, and the graphical goodies), and we will not provide 
    any binaries
  - Copyover system: Grendel can respawn itself without dumping all the
    connections, e.g. users stay online during the reboot process,
    more info below
  - IPv6 support: Grendel natively supports the new internet protocol,
    on all Linux machines with an IPv6 enabled kernel, and on 
    NT4/2000 machines that have the MSRIPv6 preview from Microsoft 
    installed. Don't worry if you don't have this, Grendel will auto-detect 
    your settings and use them accordingly
  - Way better OOP design: greatly increases stability, looks better,
    works better
  - Old code removed: no more pchars, thus no more buffer overflows,
    no more wicked crashes, no more strange things - lot clearer,
    lot better
  - Tracking system: not totally finished, but tracking people
    already works pretty nice
  - New immortal commands
  - Hashing of important tables: commands/socials tables are
    searched faster, and use less memory
  - Smaug area convertor: converts most information from a smaug
    .are file to the Grendel format
  - Password encryption: player passwords are encrypted using
    the MD5 Message Digest Algorithm
  - OLC support: design and builds your area without leaving the MUD!


3. Documentation

Documentation has never been the strongest point during the development
of The Grendel Project, but the tide is slowly turning.

In the directory 'text' you will find a few plain-text documents
describing various parts of the server. These are Modules.txt (for
info on how to best code a module), Scripting.txt (info about
the GMC syntax & structure) and Coding.txt (guidelines on
coding conventions and tips on which units to use).


4. Compiling & running

Normally, you'd download the binary distribution (grendel-....-bin.zip), but
if you wish to modify and/or (re)compile the sources, you will need the
source distribution (grendel-....-src.zip).

When installed, the sources can be compiled by running (in the root dir)

  'make -f makefile.w32' on the Windows platform, or
  
  'make -f makefile.lnx' on the Linux platform
  
You can ofcourse also use the Delphi IDE, but this is not recommended.

When you have a binary (either by downloading it, or compiling it), you
can start it by typing 'grendel' <ENTER> in the Grendel root directory.

The default port is 4444, so get hold of a telnet client, and connect
to the server.


5. Copyover

Grendel sports a neat copyover system, which I think is relatively uncommon on
Win32 servers. The copyover procedure also supports copying a new grendel executable
into the dir and starting that (hence the name :P).

This only works if you start grendel from the base directory and compile new
executables in a bin\ subdirectory. This is already done in the compile.bat and
other scripts in the distribution, so your best shot would be to keep it that way.

The copyover system is very itchy, which means that if *anything* goes wrong,
it immediately dumps everything and starts a normal reboot instead - there shouldn't
be any endless loops.


6. The new affects system

0.3.5 saw the addition of a brand new affects system, which looked promising,
but had a few defects. Those have now been fixed (finally, hopefully).

An affect consists of a name, a wear-off message, a duration and a number 
of modifier/apply-type combinations.

At the moment, the following apply types are supported:

  APPLY_NONE, APPLY_STR, APPLY_DEX, APPLY_INT, APPLY_WIS, APPLY_CON,
  APPLY_HP, APPLY_MAX_HP, APPLY_MV, APPLY_MAX_MV, APPLY_MANA, APPLY_MAX_MANA,
  APPLY_AC, APPLY_APB, APPLY_AFFECT, APPLY_REMOVE,
  APPLY_STRIPNAME, APPLY_FULL, APPLY_THIRST, APPLY_DRUNK, APPLY_CAFFEINE

The modifier is specific to the apply type used, for example, when you use
APPLY_INT, the modifier reflects the amount of intelligence gained (or lost)
through this affect, whereas with APPLY_AFFECT, the modifier is one of the
AFF_ flags found in constants.pas (or the manual).

For spells/skills, the syntax is:

  "affects: <affect name> <wear-off message> <duration> { <apply type> <modifier> } { ... }", 
  
for objects, the syntax is:
  "A <affect name> <wear-off message> <duration> { <apply type> <modifier> } { ... }".

Check the areas and system\skills.dat for examples on objects and spells,
respectively.


7. Known problems

The server has never been this stable. Roughly 90% of the active code has been
guarded by exception handling and debugging code, enabling developers to track 
down bugs and keeping uptime at a maximum.

However, there are probably pieces we've missed, so if you run across one,
please mail everything you did, so we can reproduce the error and help you out.

You will need either Delphi 5 or Kylix 1 to compile the Grendel sources,
earlier versions are not supported.


8. Contact information

Below you will find a few important email addresses, for
support, info, list communication or personal contact.


General e-mail addresses:

  info@grendelproject.nl    - Requests for info about the project/site
  support@grendelproject.nl - Requests for support on serious errors
  
Developers:

  Michiel Rook          (michiel@grendelproject.nl)     manager, website, code
  Hemko de Visser       (nemesis@grendelproject.nl)     code, field testing
  Roeland van Houte     (xenon@grendelproject.nl)       code
  Oscar Martin          (jago@grendelproject.nl)        code, field testing
  Jeremiah Davis        (woodstock@grendelproject.nl)   documentation

Forum / website:
  http://www.grendelproject.nl/

Postcards:
  
  If you use and like Grendel, I'd very much appreciate it if you
  send a postcard to me:

  Michiel Rook
  ***REMOVED***
  ***REMOVED***
  The Netherlands
