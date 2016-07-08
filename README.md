# ip2loc-lean
POSIX-compliant shell implementation of [ip2location lite](https://ip2location.com) database search.

## Features

* Portable.
* As lean as possible (no database engine required, works directly on CSV file downloaded from https://ip2location.com).
* Fast (see benchmark results).
* Smart. Tries different approaches prior to giving up.
* Agile. Supports different DB's (from DB1LITE to DB11LITE) and configurable output fields.
* IPv4 (done) and IPv6 (to be done) support.
* Comes with handy setup script.

## Requirements

### basic

* POSIX shell (tested on busybox/ash & dash)
 * output redirection & piping support
 * getopts
 * printf or echo (w/ -e & -n options)
 * test, if-then-else, do-while, case, break, true
 * functions () {}
 * subshell execution via $()
 * exit
 * command -v
* awk (awk / gawk / mawk)
* stat or ls -l
* dd

### for auto-update feature

* mkdir
* grep
* curl or wget
* crontab
* unzip

##Installation

### Auto-mode

`chmod +x *.sh`  
`./setupScript.sh -v`

### Interactive mode

`chmod +x *.sh`  
`./setupScript.sh -iv`

then place ip2loc-lean.sh into dir listed in $PATH (or add ip2loc-lean dir to $PATH)

## Usage

ip2loc-lean.sh [-scrClzthu] IP_ADDRESS

### IP_ADDRESS

Currently only valid (no check in script) IPv4 addresses like 8.8.8.8

### Options

**default is -c**

-s	Two-character country code based on ISO 3166 (i.e. US)  
-c	Country name based on ISO 3166 (i.e. United States)  
-r	Region or state name (i.e. Arizona)  
-C	City name (i.e. Tucson)  
-l	Location, lat & lon (i.e. 32.242850 -110.946248)  
-z	Zip/Postal code (i.e. 85719)  
-t	UTC time zone (with DST supported) (i.e. -07:00)  
-h	Usage help  
-u	Update DB just now. Used internally via cronjob, but you can use it as well.

## Troubleshooting & caveats

* If you aren't happy with storing database in your home dir just use symlinks.

* Login & password for ip2location database automatic downloads are stored in config as plain text. For now config file should have 600 (-rw---------) access rights when account is stored there for preventing leaks. In future config and account data will be separated.

* IPv6 is currently not supported.

* Automatic update downloads new zip file, uncompress it, creates new indices and only after all that rewrites previous DB. So, you need 2 * <selected base CSV size> + <zip size> free space to make successful auto-updates. And even worse - script doesn't check for space availability at auto-update beginning!

* More data precision = more storage space & more computing time. So, if you need only country by IP - don't use anything more than DB1LITE. Keep it as lean as possible, as do I.

* Output is not parseable because of ambiguent spaces. Will be fixed by using custom delimiter.

* This code can do something unexpected. I.e. burn your house, put your `head` under your `tail` or even `fsck` your dog. Don't blame me for that (as stated in LICENSE), just send me a postcard with funny photo of casualty attached.

## Benchmarks

*...to be filled*

## Help wanted

Any mentions, suggestions, pull-requests, bug reports, usage reports etc. are welcome and appreciated. Really. I mean it.

## Thanks

[Ip2location staff](https://ip2location.com) for provided databases.  
[D-Link](http://dlink.com) for outstanding hardware.

## Contacts

[nibble@list.ru](nibble@list.ru)  
https://facebook.com/Ip2loclean

Last update: 08.07.2016