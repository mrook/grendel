The Grendel Project - Win32 MUD Server            (c) 2000,2001 by Michiel Rook



= Last minute information =====================================================


1. Introduction

Development is going great, here's 0.3.5 already!

The biggest changes since 0.3.4:
  - some additions were made to the OLC system by Xenon,
    namely an overhead map display and a number of bug fixes
  - spamming/auto-login now works correctly
  - new affects system, very generic, very spiffy,
    supports about everything but toasting your
    morning sandwhich
  - added some nice drunken speech code provided by Nemesis
  - restructured the cleaning & timing threads - code
    is where it belongs now, and the cleaning thread
    is now acting as a watchdog for the timer & client
    threads - should the timer thread blow up, it'll
    try to repair things and restart it, should a client thread
    crash, the clean thread will disconnect the player
    and kill the offending thread.
    Testing shows that this feature increases stability
    and uptime greatly, something we all want in a server.
  - support for ITEM_LIGHT was added, as well as a 'holylight'
  - added dynamic prompts, users can define their own prompt now
  - changed the internal representation of skills quite a bit,
    the fixed array indexing is completely gone.
  - numerous bugfixes: re-enabled host lookups (only for ipv4
    for the time being), fixed a number of crash bugs, fixed 
    the lack of kill xp, some fixes to freeze/silence, and a number 
    of other small things.
  - a noteboard system by Nemesis, check the files in boards\,
    the 'board' and the 'note' command.
  - a hideously cool namegenerator by Xenon; it creates a list of
    names through a number of phonetic templates. Check 'namegen'.
  - a version of the popular 'AT' command (again by Xenon)

A small note about the directory structure:

WinZip doesn't save empty directories, so to have your server run
correctly, you'll need to create two directores: "backup" and "logs".
As of this release, a standard immortal character, 'Grendel', is included
which can be used as a starting point for your own immortal(s).


2. The new affects system

Release 0.3.5 sports an exciting new affects handling system, for
spells, skills, objects (heck, and maybe even more if I can find
the imagination).

An affect consists of an apply type, a modifier, and a duration.

At the moment, the following apply types are supported:

  APPLY_NONE, APPLY_STR, APPLY_DEX, APPLY_INT, APPLY_WIS, APPLY_CON,
  APPLY_HP, APPLY_MAX_HP, APPLY_MV, APPLY_MAX_MV, APPLY_MANA, APPLY_MAX_MANA,
  APPLY_AC, APPLY_APB, APPLY_AFFECT, APPLY_REMOVE,
  APPLY_STRIPSPELL, APPLY_FULL, APPLY_THIRST, APPLY_DRUNK, APPLY_CAFFEINE

The modifier is specific to the apply type used, for example, when you use
APPLY_INT, the modifier reflects the amount of intelligence gained (or lost)
through this affect, whereas with APPLY_AFFECT, the modifier is one of the
AFF_ flags found in constants.pas (or the manual).

For spells/skills, the syntax is "affects: <apply type> <modifier> <duration>",
for objects, the syntax is "A <apply type> <modifier> <duration>".

Check the areas and system\skills.dat for examples on objects and spells,
respectively.


3. Features

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
  - OLC support: design and builds your area without leaving the MUD!


4. The team

Oscar Martin has temporarily left us, due to personal reasons.

  Michiel Rook                (Grimlord)		manager, website, code
  Hemko de Visser	      (Nemesis)			code, field testing
  Roeland van Houte           (Xenon)			code
  Jeremiah Davis              (Woodstock)  		documentation
  Oscar Martin (inactive)     (Jago)			code


5. Compiling & running

The executable comes with the zipfile, but if you wish to (re)compile grendel.exe,
use the compile.bat file, located in the root dir. You can ofcourse also use
the Delphi IDE.

After that, simply type 'grendel' and hit ENTER. Grendel defaults to port 4444,
so get a telnet client and connect.


6. Copyover

Grendel sports a neat copyover system, which I think is relatively uncommon on
Win32 servers. The copyover procedure also supports copying a new grendel executable
into the dir and starting that (hence the name :P).

This only works if you start grendel from the base directory and compile new
executables in a bin\ subdirectory. This is already done in the compile.bat and
other scripts in the distribution, so your best shot would be to keep it that way.

The copyover system is very itchy, which means that if *anything* goes wrong,
it immediately dumps everything and starts a normal reboot instead - there shouldn't
be any endless loops.


7. Known problems

It's relatively safe to say that 100% of the old functionality is back,
on top of the shitloads of new features that already are in there.
Should you see anything missing, do not hesitate to mail me.

Again, there were a lot of stability fixes, and the server has become even more
skilled at fixing its own problems, so uptime should have been increased greatly.
However, I'm sure there are still some things left that could bring the server
down to its knees. If you find such a thing, notify me about it, and I'll get
on it ASAP.

You will very likely need Delphi 5 to (re)compile the source. Delphi 4 might
work, but then again, it just might not. Delphi2/3 are seriously obsolete
and should be removed from your harddisk anyway.


8. Contact information

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
