The Grendel Project - Win32 MUD Server            (c) 2000,2001 by Michiel Rook



= Last minute information =====================================================


1. Introduction

It has been two weeks since the 0.3.2 release, and already the 0.3.3 is
out! This one is mostly bugfixes and a few new features.

Biggest changes since 0.3.2 are the inclusion of a smaug area convertor
(still in beta stage), password encryption in playerfiles using MD5
(backward compatible with older pfiles), door resets, backing up of
pfiles when deleting/destroying, more help files, better exit handling,
new ban code (with hostmasks), etc. etc.
For more details, check the ChangeLog file.

A small note on changes with exits:
  
  You can now enclose your exit keywords in single quotes (') to keep
  them together, e.g. like this:

  D 100 1 0 0 'oaken door' 'wooden door'

  The first argument will used when interacting with a door, using the
  new $d argument in act().


2. Features

Grendel requires Winsock2 to be installed. Windows 98, Me, NT4 and 2000
all come with this preinstalled, Windows 95 users will have to download
an update from the Microsoft site.

  - Copyover system: Grendel can respawn itself without dumping all the
    connections, e.g. users stay online during the reboot process,
    more info below
  - IPv6 support: Grendel natively supports the new internet protocol,
    however, only on NT4/2000 machines that have the MSRIPv6 preview
    from Microsoft installed. Don't worry if you don't have this,
    Grendel will auto-detect your settings and use them appropiately
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


3. The team

One new member has been added to the team since the 0.3.2 release,
which makes it a 4 man team, with currently on board:

  Michiel Rook											manager, code
  Hemko de Visser										code, field testing
  Oscar Martin											code
  Jeremiah Davis (*new member*)			documentation


4. Compiling & running

The executable comes with the zipfile, but if you wish to (re)compile grendel.exe,
use the compile.bat file, located in the root dir. You can ofcourse also use
the Delphi IDE.

After that, simply type 'grendel' and hit ENTER. Grendel defaults to port 4444,
so get a telnet client and connect.


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


6. Known problems

Most of the OLC commands are left out at the moment, they will be re-implemented
ASAP. It could be that there still are other things not re-implemented from the 
original source, afaik everything is back in there, but if you see anything
missing, contact me about it.

The stability of the server has been greatly increased since the last version(s),
but I'm sure there are still some things left that could bring the server
down to its knees. If you find such a thing, notify me about it, and I'll get
on it ASAP.

You will very likely need Delphi 5 to (re)compile the source. Delphi 4 might
work, but then again, it just might not. Delphi2/3 are seriously obsolete
and should be removed from your harddisk anyway.


7. Contact information

Announcements on new versions etc. will be made available to:
	grendel-announce@egroups.com

For general questions, please refer to the mailinglist: 
	grendel-mudserver@egroups.com

Please use this mailinglist as much as possible, as I do not
have the time to respond personally to each and every message.


However, for personal contact (and postcards!) use:

	***REMOVED***@takeover.nl, or:

	Michiel Rook
	***REMOVED***
	***REMOVED***
	The Netherlands
