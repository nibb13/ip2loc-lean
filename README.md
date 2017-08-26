# ip2loc-lean

POSIX-compliant shell implementation of [ip2location lite](https://lite.ip2location.com) database search.

v 1.0.0

## Features

* Portable.
* As lean as possible (no database engine required, works directly on CSV file downloaded from https://lite.ip2location.com).
* Fast (see [benchmark results](#benchmarks)).
* Smart. Tries different approaches prior to giving up.
* Agile. Supports different DB's (from DB1LITE to DB11LITE) and configurable output fields.
* IPv4 (done) and IPv6 (in testing) support.
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
* bc for IPv6 conversions (optional, but increases speed in comparison with built-in awk code)

### for auto-update feature

* mkdir
* grep
* curl or wget
* crontab
* unzip

## Installation

### Auto-mode

`chmod +x *.sh`  
`./setupScript.sh -v`

Don't forget to set ip2location account info in config.

### Interactive mode

`chmod +x *.sh`  
`./setupScript.sh -iv`

then place ip2loc-lean.sh into dir listed in $PATH (or add ip2loc-lean dir to $PATH)

## Usage

ip2loc-lean.sh [-scrClztuh] IP_ADDRESS [OUT_FORMAT]

### IP_ADDRESS

* Valid (no check in script) IPv4 addresses like "8.8.8.8"
* Valid (no check in script) IPv6 addresses like "2404:6800:4001:805::1006" or "::1"

Currently script tries to guess which address is supplied.

### OUT_FORMAT

empty (default) - fields delimited by ::  
csv - fields delimited by , and embraced by "

### Options

**default is -c**

-s	Two-character country code based on ISO 3166 (i.e. US)  
-c	Country name based on ISO 3166 (i.e. United States)  
-r	Region or state name (i.e. Arizona)  
-C	City name (i.e. Tucson)  
-l	Location, lat & lon (i.e. 32.242850 -110.946248)  
-z	Zip/Postal code (i.e. 85719)  
-t	UTC time zone (with DST supported) (i.e. -07:00)  
-u	Update DB just now. Used internally via cronjob, but you can use it as well.  
-h	Usage help

## Troubleshooting & caveats

* If you aren't happy with storing database in your home dir just use symlinks.

* Login & password for ip2location database automatic downloads are stored in config as plain text. For now config file should have 600 (-rw---------) access rights when account is stored there for preventing leaks. In future config and account data will be separated.

* IPv6 is currently not ~~supported~~ widely tested.

* Automatic update downloads new zip file, uncompress it, creates new indices and only after all that rewrites previous DB. So, you need 2 * \<selected base CSV size> + \<zip size> free space to make successful auto-updates. And even worse - script doesn't check for space availability at auto-update beginning!

* More data precision = more storage space & more computing time. So, if you need only country by IP - don't use anything more than DB1LITE. Keep it as lean as possible, as do I.

* ~~Output is not parseable because of ambiguent spaces. Will be fixed by using custom delimiter.~~ Bug [#1](https://github.com/nibb13/ip2loc-lean/issues/1), closed in [c529b2b](https://github.com/nibb13/ip2loc-lean/commit/c529b2ba9954f3139df785bb08a02c48255a4c92).

* This code can do something unexpected. I.e. burn your house, put your `head` under your `tail` or even `fsck` your dog. Don't blame me for that (as stated in LICENSE), just send me a postcard with funny photo of casualty attached.

## Benchmarks

Spoiler: [Puppy Linux on Pentium 4](#pc-puppy-linux-boot-from-usb-stick) is fastest so far.

### D-Link DIR-620 (SOHO router)

* CPU: MIPS 74K V4.9, 248.83 BogoMIPS
* 32 Mb RAM.

**IPv4**

**DB1LITE**, creating index: 0m 15.42s  
Total time: 4m 28.22s (268.22s) per 1000 queries, Average value: **0.27s**, Median value: **0.27s** per query  

**DB3LITE**, creating index: 7m 8.37s  
Total time: 5m 12.69s (312.69s) per 1000 queries, Average value: **0.31s**, Median value: **0.31s** per query  

**DB5LITE**, creating index: 8m 50.92s  
Total time: 5m 15.19s (315.19s) per 1000 queries, Average value: **0.32s**, Median value: **0.31s** per query  

**DB9LITE**, creating index: 9m 16.20s  
Total time: 5m 35.07s (335.07s) per 1000 queries, Average value: **0.34s**, Median value: **0.31s** per query  

**DB11LITE**, creating index: 13m 21.88s  
Total time: 6m 22.76s (382.76s) per 1000 queries, Average value: **0.38s**, Median value: **0.34s** per query  

**IPv6**

**DB1LITEIPV6**, creating index: 0m 31.44s  
	(With bc) Total time: 5m 37.44s (337.44s) per 1000 queries, Average value: **0.34s**, Median value: **0.35s** per query  
	(Without bc) Total time: 8m 42.38s (522.38s) per 1000 queries, Average value: **0.52s**, Median value: **0.46s** per query  

**DB3LITEIPV6**, creating index: 8m 35.45s  
	(With bc) Total time: 5m 45.71s (345.71s) per 1000 queries, Average value: **0.35s**, Median value: **0.33s** per query  
	(Without bc) Total time: 9m 46.96s (586.96s) per 1000 queries, Average value: **0.59s**, Median value: **0.50s** per query  

**DB5LITEIPV6**, creating index: 10m 22.65s  
	(With bc) Total time: 6m 0.73s (360.73s) per 1000 queries, Average value: **0.36s**, Median value: **0.34s** per query  
	(Without bc) Total time: 9m 20.82s (560.82s) per 1000 queries, Average value: **0.56s**, Median value: **0.49s** per query  

**DB9LITEIPV6**, creating index: 11m 16.40s  
	(With bc) Total time: 7m 13.09s (433.09s) per 1000 queries, Average value: **0.43s**, Median value: **0.41s** per query  
	(Without bc) Total time: 13m 36.28s (816.28s) per 1000 queries, Average value: **0.82s**, Median value: **0.70s** per query  

**DB11LITEIPV6**, creating index: 17m 53.45s  
	(With bc) Total time: 10m 14.88s (614.88s) per 1000 queries, Average value: **0.62s**, Median value: **0.59s** per query  
	(Without bc) Total time: 14m 24.67s (864.67s) per 1000 queries, Average value: **0.87s**, Median value: **0.73s** per query  

### Asus Transformer TF101 (Android tablet)

* CPU: ARMv7 Processor rev 0 (v7l), 1987.37 BogoMIPS @ 2 cores
* 1Gb RAM.

**DB1LITE**, creating index: 0m 2.34s  
Total time: 1m 14.80s (74.80s) per 1000 queries, Average value: **0.08s**, Median value: **0.07s** per query  

**DB3LITE**, creating index: 1m 24.18s  
Total time: 1m 54.57s (114.57s) per 1000 queries, Average value: **0.12s**, Median value: **0.10s** per query  

**DB5LITE**, creating index: 1m 44.31s  
Total time: 2m 27.41s (147.41s) per 1000 queries, Average value: **0.15s**, Median value: **0.13s** per query  

**DB9LITE**, creating index: 1m 54.59s  
Total time: 2m 38.98s (158.98s) per 1000 queries, Average value: **0.16s**, Median value: **0.14s** per query  

**DB11LITE**, creating index: 2m 3.62s  
Total time: 2m 51.69s (171.69s) per 1000 queries, Average value: **0.17s**, Median value: **0.16s** per query  

### PC (Puppy Linux boot from USB stick)
* CPU: Intel(R) Pentium(R) 4 CPU 3.00Ghz, 5985.22 BogoMIPS
* 4Gb RAM.

**DB1LITE**, creating index: 0m 1.183s  
Total time: 1m 23.36s (83.36s) per 1000 queries, Average value: **0.08s**, Median value: **0.08s** per query  

**DB3LITE**, creating index: 0m 39.886s  
Total time: 1m 37.21s (97.21s) per 1000 queries, Average value: **0.10s**, Median value: **0.1s** per query  

**DB5LITE**, creating index: 0m 50.301s  
Total time: 1m 50.85s (110.85s) per 1000 queries, Average value: **0.11s**, Median value: **0.11s** per query  

**DB9LITE**, creating index: 0m 54.275s  
Total time: 1m 56.88s (116.88s) per 1000 queries, Average value: **0.12s**, Median value: **0.12s** per query  

**DB11LITE**, creating index: 1m 0.580s  
Total time: 2m 4.27s (124.27s) per 1000 queries, Average value: **0.12s**, Median value: **0.12s** per query  

### Just for fun

### PC (Linux Mint 13 under VirtualBox, host: Windows XP SP3)

* CPU: Intel(R) Pentium(R) 4 CPU 3.00GHz, 2060.28 BogoMIPS
* 512 Mb RAM.

**DB1LITE**, creating index: 0m 3.669s  
Total time: 6m 51.36s (411.36s) per 1000 queries, Average value: **0.41s**, Median value: **0.39s** per query  

**DB3LITE**, creating index: 1m 18.10s  
Total time: 8m 49.33s (529.33s) per 1000 queries, Average value: **0.53s**, Median value: **0.51s** per query  

**DB5LITE**, creating index: 1m 33.48s  
Total time: 10m 29.28s (629.28s) per 1000 queries, Average value: **0.63s**, Median value: **0.61s** per query  

**DB9LITE**, creating index: 1m 38.98s  
Total time: 10m 42.33s (642.33s) per 1000 queries, Average value: **0.64s**, Median value: **0.62s** per query  

**DB11LITE**, creating index: 1m 49.92s  
Total time: 11m 57.38s (717.38s) per 1000 queries, Average value: **0.72s**, Median value: **0.71s** per query  

### PC (Cygwin under Windows XP SP3)

* CPU: Intel(R) Pentium(R) 4 CPU 3.00GHz, 2060.28 BogoMIPS
* 3 Gb RAM.

**DB1LITE**, creating index: 0m 4.57s  
Total time: 27m 55.76s (1675.76s) per 1000 queries, Average value: **1.68s**, Median value: **1.45s** per query  

**DB3LITE**, creating index: 2m 22.34s  
Total time: 5h 52m 54.88s (21174.88s) per 628 queries, Average value: **33.72s**, Median value: **37.00s** per query  
^C  
*OK, enough. Cygwin is a pain.*

*...to be filled further*

## Help wanted

Any mentions, suggestions, pull-requests, bug reports, usage reports etc. are welcome and appreciated. Really. I mean it.

## Thanks

[Ip2location staff](https://ip2location.com) for provided databases.  
[D-Link](http://dlink.com) for outstanding hardware.

## Contacts

<nibble@list.ru>  
https://facebook.com/Ip2loclean  
https://vk.com/ip2loc_lean

Last update: 26.08.2017
