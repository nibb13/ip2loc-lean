#!/bin/sh

check_cmd () {

    command -v $1 >/dev/null 2>&1 && echo "1";
    
}

usage () {

    $PRINT "Usage: $0 [-iv]";
    $PRINT;
    $PRINT "Installs ip2loc-lean.";
    $PRINT;
    $PRINT "Options:";
    $PRINT_E "\t-i\tInteractive setup (ask for best options)";
    $PRINT_E "\t-h\tUsage help";
    $PRINT_E "\t-v\tVerbose mode";
    $PRINT;
	
    
}

prompt_n_read () {

    read -p "$1 [$2]: " ANSWER;

    if [ "$ANSWER" ]; then
	$PRINT_N "$ANSWER";
    else
	$PRINT_N "$2";
    fi

}

out_text () {

    if [ "$1" -le "$CONF_VERBOSE_LEVEL" ]; then
	$PRINT_EN "$2";
    fi

}

out_err () {

    if [ "$1" -le "$CONF_VERBOSE_LEVEL" ]; then
	$PRINT_EN "$2" >&2;
    fi

}

lso() {

# Ref.: Adam Courtemanche on http://agileadam.com/2011/02/755-style-permissions-with-ls/
# Eliah Kagan on http://askubuntu.com/a/152005

    ls -l "$@" | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);}';
    
}

CONF_SCRIPT_DIR="ip2loc-lean";

# Can we rely on "command" to check for command existence?
# TODO: add more check options

CONF_COMMAND_PRESENT=$(check_cmd command);

if [ ! "$CONF_COMMAND_PRESENT" ]; then
    echo "Command is not found, exiting!" >&2;
    exit 1;
fi

CONF_AWK_PRESENT=$(check_cmd awk);
CONF_BUSYBOX_PRESENT=$(check_cmd busybox);
CONF_CHMOD_PRESENT=$(check_cmd chmod);
CONF_CRONTAB_PRESENT=$(check_cmd crontab);
CONF_CURL_PRESENT=$(check_cmd curl);
CONF_DATE_PRESENT=$(check_cmd date);
CONF_DD_PRESENT=$(check_cmd dd);
CONF_ECHO_PRESENT=$(check_cmd echo);
CONF_EXPR_PRESENT=$(check_cmd expr);
CONF_GAWK_PRESENT=$(check_cmd gawk);
CONF_GREP_PRESENT=$(check_cmd grep);
CONF_HEAD_PRESENT=$(check_cmd head);
CONF_LENGTH_PRESENT=$(check_cmd length);
CONF_LS_PRESENT=$(check_cmd ls);
CONF_MAWK_PRESENT=$(check_cmd mawk);
CONF_MKDIR_PRESENT=$(check_cmd mkdir);
CONF_PRINTF_PRESENT=$(check_cmd printf);
CONF_SEQ_PRESENT=$(check_cmd seq);
CONF_STAT_PRESENT=$(check_cmd stat);
CONF_TR_PRESENT=$(check_cmd tr);
CONF_UNZIP_PRESENT=$(check_cmd unzip);
CONF_WC_PRESENT=$(check_cmd wc);
CONF_WGET_PRESENT=$(check_cmd wget);

# printf is better due to POSIX compliance:

if [ "$CONF_PRINTF_PRESENT" ]; then
    PRINT="printf %s\n";
    PRINT_E="printf %b\n";
    PRINT_N="printf %s";
    PRINT_EN="printf %b";
elif [ "$CONF_ECHO_PRESENT" ]; then
    PRINT="echo";
    PRINT_E="echo -e";
    PRINT_N="echo -n";
    PRINT_EN="echo -en";
else
    exit 1;
fi

if [ "$CONF_BUSYBOX_PRESENT" ] && [ "$CONF_HEAD_PRESENT" ]; then
    CONF_BUSYBOX_VERSION=$(busybox | head -n 1);
fi

CONF_VERBOSE_LEVEL=1

while getopts "ihv" opt
do
    case $opt in
	v)
	    if [ "$CONF_EXPR_PRESENT" ]; then
		CONF_VERBOSE_LEVEL=$(expr $CONF_VERBOSE_LEVEL + 1);
	    else
		out_err 1 "Cannot increase verbosity level, expr is missing!\nThus setting it to max\n";
		CONF_VERBOSE_LEVEL=2;
	    fi
	    ;;
	i)
	    CONF_INTERACTIVE_SETUP=1;
	    ;;
	h)
	    usage;
	    exit 0;
	    ;;
	*)
	    usage;
	    exit 1;
	    ;;
    esac
done

if [ "$CONF_INTERACTIVE_SETUP" ]; then
    while true; do
	ANSWER=$(prompt_n_read "Use XDG spec to store data? (y[es]/n[o])" "yes");
	case $ANSWER in
	    [Yy]*)
		CONF_USE_XDG=1;
		;;
	    [Nn]*)
		;;
	    *)
		unset ANSWER;
	esac
        test "$ANSWER" && break || out_text 1 "Can't get you, please repeat!\n";
    done
else
    CONF_USE_XDG=1;
fi

if [ "$CONF_USE_XDG" ]; then

    out_text 2 "Using XDG spec (https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) to store data.\n";
    
    # Check for XDG vars

    if [ ! "$XDG_CONFIG_HOME" ]; then
        XDG_CONFIG_HOME=~/.config;
        out_text 2 "No XDG_CONFIG_HOME set, defaulting to: $XDG_CONFIG_HOME\n";
    fi

    if [ ! "$XDG_DATA_HOME" ]; then
        XDG_DATA_HOME=~/.local/share
        out_text 2 "No XDG_DATA_HOME set, defaulting to: $XDG_DATA_HOME\n";
    fi

    # Check for XDG dirs existence
    
    if [ "$CONF_MKDIR_PRESENT" ]; then

        if [ ! -d "$XDG_CONFIG_HOME" ] && [ ! -e "$XDG_CONFIG_HOME" ]; then
            out_text 2 "No XDG_CONFIG_HOME exist, creating one.\n";
            mkdir -p $XDG_CONFIG_HOME;
            if [ "$?" -ne 0 ]; then
        	out_err 2 "Error creating XDG_CONFIG_HOME.\n";
        	unset CONF_USE_XDG;
            fi
        fi
    
        if [ "$CONF_USE_XDG" ] && [ ! -d "$XDG_DATA_HOME" ] && [ ! -e "$XDG_DATA_HOME" ]; then
	    out_text 2 "No XDG_DATA_HOME exist, creating one.\n";
	    mkdir -p $XDG_DATA_HOME;
	    if [ "$?" -ne 0 ]; then
        	out_err 2 "Error creating XDG_DATA_HOME.\n";
        	unset CONF_USE_XDG;
            fi
        fi
        
        if [ "$CONF_USE_XDG" ] && [ ! -d "$XDG_CONFIG_HOME/$CONF_SCRIPT_DIR" ] && [ ! -e "$XDG_CONFIG_HOME/$CONF_SCRIPT_DIR" ]; then
        
    	    out_text 2 "No script config dir exist, creating one.\n";
            mkdir -p $XDG_CONFIG_HOME/$CONF_SCRIPT_DIR;
            if [ "$?" -ne 0 ]; then
        	out_err 2 "Error creating config dir.\n";
    	    fi
    	    
        fi
        
        if [ "$CONF_USE_XDG" ] && [ ! -d "$XDG_DATA_HOME/$CONF_SCRIPT_DIR" ] && [ ! -e "$XDG_DATA_HOME/$CONF_SCRIPT_DIR" ]; then
        
	    out_text 2 "No script data dir exist, creating one.\n";
	    mkdir -p $XDG_DATA_HOME/$CONF_SCRIPT_DIR;
	    if [ "$?" -ne 0 ]; then
		out_err 2 "Error creating data dir.\n";
	    fi
	    
        fi
        
    elif [ ! -d "$XDG_CONFIG_HOME" ] || [ ! -d "$XDG_DATA_HOME" ]; then
    
	out_err 2 "mkdir is missing, cannot create XDG dirs!\n";
	unset CONF_USE_XDG;
	
    fi
    
    if [ "$CONF_USE_XDG" ]; then
    
        if [ -d "$XDG_CONFIG_HOME/$CONF_SCRIPT_DIR" ]; then
            CONF_CONFIG_HOME=$XDG_CONFIG_HOME/$CONF_SCRIPT_DIR;
        fi
        
        if [ -d "$XDG_DATA_HOME/$CONF_SCRIPT_DIR" ]; then
            CONF_DATA_HOME=$XDG_DATA_HOME/$CONF_SCRIPT_DIR;
        fi
    
    fi

fi

if [ ! "$CONF_USE_XDG" ]; then

    out_text 2 "Using old-style ~/.$CONF_SCRIPT_DIR path to store data.\n";

    if [ "$CONF_MKDIR_PRESENT" ]; then
    
	if [ ! -d ~/.$CONF_SCRIPT_DIR ] && [ ! -e ~/.$CONF_SCRIPT_DIR ]; then
    	    out_text 2 "No script config dir exist, creating one.\n";
            mkdir -p ~/.$CONF_SCRIPT_DIR;
            if [ "$?" -ne 0 ]; then
        	out_err 2 "Error creating config dir.\n";
            fi
        fi
        
        if [ ! -d ~/.$CONF_SCRIPT_DIR/data ] && [ ! -e ~/.$CONF_SCRIPT_DIR/data ]; then
	    out_text 2 "No script data dir exist, creating one.\n";
	    mkdir -p ~/.$CONF_SCRIPT_DIR/data;
	    if [ "$?" -ne 0 ]; then
		out_err 2 "Error creating data dir.\n";
	    fi
        fi
    elif [ ! -d ~/.$CONF_SCRIPT_DIR ] || [ ! -d ~/.$CONF_SCRIPT_DIR/data ]; then
	out_text 2 "mkdir is missing, cannot create config & data dirs!\n";
    fi
    
    if [ -d ~/.$CONF_SCRIPT_DIR ]; then
	CONF_CONFIG_HOME=~/.$CONF_SCRIPT_DIR;
    fi
    
    if [ -d ~/.$CONF_SCRIPT_DIR/data ]; then
	CONF_DATA_HOME=~/.$CONF_SCRIPT_DIR/data;
    fi
    
fi

if [ ! "$CONF_CONFIG_HOME" ] || [ ! "$CONF_DATA_HOME" ]; then

    out_err 1 "Cannot create config and/or data dir, please install manually!\n";
    exit 1;
    
fi

if [ "$CONF_CURL_PRESENT" ] && [ "$CONF_WGET_PRESENT" ]; then

    if [ "$CONF_INTERACTIVE_SETUP" ]; then
	while true; do
	    ANSWER=$(prompt_n_read "Both curl & wget found, which do you want to use? (c[url]/w[get])" "curl");
	    case $ANSWER in
		[Cc]*)
		    CONF_HTTP_BACKEND="curl";
		    ;;
		[Ww]*)
		    CONF_HTTP_BACKEND="wget";
		    ;;
		*)
		    unset ANSWER;
	    esac
	    test "$ANSWER" && break || out_text 1 "Can't get you, please repeat!\n";
	done
    else
	out_text 2 "Both curl & wget found, defaulting to curl.\n";
	CONF_HTTP_BACKEND="curl";
    fi
    
elif [ "$CONF_CURL_PRESENT" ]; then
    
    out_text 2 "Only curl is found, using it as http downloader.\n";
    CONF_HTTP_BACKEND="curl";
    
elif [ "$CONF_WGET_PRESENT" ]; then

    out_text 2 "Only wget is found, using it as http downloader.\n";
    CONF_HTTP_BACKEND="wget";
    
else

    out_err 2 "No curl or wget found, automatic downloads are disabled!\n";
    
fi

AWK_COUNT=0;
AWK_FOUND="";
AWK_CHOICE="";

if [ "$CONF_MAWK_PRESENT" ]; then
    AWK_COUNT=1;
    CONF_AWK_BACKEND="mawk";
    AWK_FOUND="mawk";
    AWK_CHOICE="[m]awk";
fi

if [ "$CONF_GAWK_PRESENT" ]; then
    AWK_COUNT=$(expr $AWK_COUNT + 1);
    CONF_AWK_BACKEND="gawk";
    if [ "$AWK_FOUND" ]; then
	AWK_FOUND=",$AWK_FOUND";
	AWK_CHOICE="/$AWK_CHOICE";
    fi
    AWK_FOUND="gawk$AWK_FOUND";
    AWK_CHOICE="[g]awk$AWK_CHOICE";
fi

if [ "$CONF_AWK_PRESENT" ]; then
    AWK_COUNT=$(expr $AWK_COUNT + 1);
    CONF_AWK_BACKEND="awk";
    if [ "$AWK_FOUND" ]; then
	AWK_FOUND=",$AWK_FOUND";
	AWK_CHOICE="/$AWK_CHOICE";
    fi
    AWK_FOUND="awk$AWK_FOUND";
    AWK_CHOICE="[a]wk$AWK_CHOICE";
fi

if [ "$AWK_COUNT" -eq 0 ]; then
    out_err 1 "No awk/gawk/mawk found, install one and rerun installation.\n";
    exit 1;
fi

if [ "$AWK_COUNT" -gt 1 ]; then

    if [ "$CONF_INTERACTIVE_SETUP" ]; then
	while true; do
	    ANSWER=$(prompt_n_read "Found multiple awk versions ($AWK_FOUND), which do you want to use? ($AWK_CHOICE)" "$CONF_AWK_BACKEND");
	    case $ANSWER in
		[Aa]*)
		    if [ "$CONF_AWK_PRESENT" ]; then
			CONF_AWK_BACKEND="awk";
		    else
			unset ANSWER;
		    fi
		    ;;
		[Gg]*)
		    if [ "$CONF_GAWK_PRESENT" ]; then
			CONF_AWK_BACKEND="gawk";
		    else
			unset ANSWER;
		    fi
		    ;;
		[Mm]*)
		    if [ "$CONF_MAWK_PRESENT" ]; then
			CONF_AWK_BACKEND="mawk";
		    else
			unset ANSWER;
		    fi
		    ;;
		*)
		    unset ANSWER;
	    esac
	    test "$ANSWER" && break || out_text 1 "Can't get you, please repeat!\n";
	done
    else
	out_text 2 "Found multiple awk versions ($AWK_FOUND), defaulting to $CONF_AWK_BACKEND.\n";
    fi
else
    out_text 2 "Found $CONF_AWK_BACKEND. Will use it.\n";
fi

if [ ! "$CONF_DD_PRESENT" ]; then
    out_err 1 "No dd found, install it and rerun installation.\n";
    exit 1;
fi

if [ ! "$CONF_STAT_PRESENT" ] && [ ! "$CONF_LS_PRESENT" ]; then
    out_err 1 "No stat and even ls are found! Your system is leaner than our script. Install one and rerun installation.\n";
    exit 1;
fi

if [ "$CONF_INTERACTIVE_SETUP" ]; then
    while true; do
	ANSWER=$(prompt_n_read "Which IPv4 ip2location DB to use? (<DB code>, none, list)" "DB3LITE");
	case $ANSWER in
	    DB1LITE)
		CONF_DB_CODE=$ANSWER;
		;;
	    DB3LITE)
		CONF_DB_CODE=$ANSWER;
		;;
	    DB5LITE)
		CONF_DB_CODE=$ANSWER;
		;;
	    DB9LITE)
		CONF_DB_CODE=$ANSWER;
		;;
	    DB11LITE)
		CONF_DB_CODE=$ANSWER;
		;;
	    [Nn][Oo][Nn][Ee])
		;;
	    [Ll][Ii][Ss][Tt])
		$PRINT "Available IPv4 bases are:";
		$PRINT_E "\tDB1LITE - Country only. (~6 Mb)";
		$PRINT_E "\tDB3LITE - Country, region, city. (~250 Mb)";
		$PRINT_E "\tDB5LITE - Country, region, city, lat & lon. (~340 Mb)";
		$PRINT_E "\tDB9LITE - Country, region, city, lat & lon, zip/postal code. (~380 Mb)";
		$PRINT_E "\tDB11LITE - Country, region, city, lat & lon, zip/postal code, timezone w/ DST. (~410 Mb)";
		$PRINT;
		continue;
		;;
	    *)
		unset ANSWER;
	esac
	test "$ANSWER" && break || out_text 1 "Can't get you, please repeat!\n";
    done
    while true; do
	ANSWER=$(prompt_n_read "Which IPv6 ip2location DB to use? (<DB code>, none, list)" "DB3LITEIPV6");
	case $ANSWER in
	    DB1LITEIPV6)
		CONF_DB6_CODE=$ANSWER;
		;;
	    DB3LITEIPV6)
		CONF_DB6_CODE=$ANSWER;
		;;
	    DB5LITEIPV6)
		CONF_DB6_CODE=$ANSWER;
		;;
	    DB9LITEIPV6)
		CONF_DB6_CODE=$ANSWER;
		;;
	    DB11LITEIPV6)
		CONF_DB6_CODE=$ANSWER;
		;;
	    [Nn][Oo][Nn][Ee])
		;;
	    [Ll][Ii][Ss][Tt])
		$PRINT "Available IPv6 bases are:";
		$PRINT_E "\tDB1LITEIPV6 - Country only. (~X Mb)";
		$PRINT_E "\tDB3LITEIPV6 - Country, region, city. (~XXX Mb)";
		$PRINT_E "\tDB5LITEIPV6 - Country, region, city, lat & lon. (~XXX Mb)";
		$PRINT_E "\tDB9LITEIPV6 - Country, region, city, lat & lon, zip/postal c\ode. (~XXX Mb)";
		$PRINT_E "\tDB11LITEIPV6 - Country, region, city, lat & lon, zip/postal code, timezone w/ DST. (~XXX Mb)";
		$PRINT;
		continue;
		;;
	    *)
		unset ANSWER;
	esac
	test "$ANSWER" && break || out_text 1 "Can't get you, please repeat!\n";
    done
else
    out_text 2 "Defaulting to DB1LITE && DB1LITEIPV6.\n";
    CONF_DB_CODE="DB1LITE";
    CONF_DB6_CODE="DB1LITEIPV6";
fi

if [ "$CONF_HTTP_BACKEND" ]; then

    if [ "$CONF_INTERACTIVE_SETUP" ]; then
	while true; do
	    ANSWER=$(prompt_n_read "Do you want to setup automatic monthly DB updates? (y[es]/n[o])" "yes");
	    case $ANSWER in
		[Yy]*)
		    CONF_DB_AUTOUPDATE=1;
		    ;;
		[Nn]*)
		    ;;
		*)
		    unset ANSWER;
	    esac
	    test "$ANSWER" && break || out_text 1 "Can't get you, please repeat!\n";
	done
	CONF_IP2LOC_LOGIN=$(prompt_n_read "Enter ip2location account login for DB updates (leave empty to skip)");
	if [ "$CONF_IP2LOC_LOGIN" ]; then
	    while true; do
		IP2LOC_PASS=$(read -sp "Enter ip2location account password (leave empty to skip) : " ANSWER; $PRINT "$ANSWER");
		$PRINT;
		if [ ! "$IP2LOC_PASS" ]; then
		    unset CONF_IP2LOC_LOGIN;
		    break;
		fi
		IP2LOC_PASS_CONFIRM=$(read -sp "Confirm ip2location account password : " ANSWER; $PRINT "$ANSWER");
		$PRINT;
		test "$IP2LOC_PASS" = "$IP2LOC_PASS_CONFIRM" && break || out_text 1 "Entered passwords doesn't match!\n";
	    done;
	    CONF_IP2LOC_PASS=$IP2LOC_PASS;
	fi
	
    else
	if [ "$CONF_CRONTAB_PRESENT" ]; then
	    out_text 2 "Defaulting to automatic DB updates.\n";
	    CONF_DB_AUTOUPDATE=1;
	fi
    fi
    
fi

if [ ! "$CONF_CRONTAB_PRESENT" ] || [ ! "$CONF_HTTP_BACKEND" ] || [ ! "$CONF_UNZIP_PRESENT" ] || [ ! "$CONF_DATE_PRESENT" ]; then
    out_err 2 "No prerequisites for autoupdate found.\nThese are: crontab, date, curl or wget, unzip\nAutomatic updates disabled.\n";
    unset CONF_DB_AUTOUPDATE;
fi

CONFIG_FILE="$CONF_CONFIG_HOME/ip2loc-lean.conf";

out_text 2 "\nInfo gathered, writing config\n\n";
out_text 2 "Just to make it clear, repeating:\n\n";
out_text 2 "Config file is at: $CONFIG_FILE\n";
out_text 2 "Data dir is at: $CONF_DATA_HOME\n";
out_text 2 "HTTP backend is $CONF_HTTP_BACKEND.\n";

test "$CONF_CRONTAB_PRESENT" && test "$CONF_HTTP_BACKEND" && test "$CONF_UNZIP_PRESENT" && test "$CONF_DATE_PRESENT" && out_text 2 "Auto-update prerequisites are met" || out_text 2 "Auto-update prerequisites are not met, auto-update is disabled.\n";
test "$CONF_DB_AUTOUPDATE" && out_text 2 " and auto-update is on." || out_text 2 " but auto-update is off. You can enable it in config at any time.";
test "$CONF_IP2LOC_LOGIN" && test "$CONF_IP2LOC_PASS" && out_text 2 "\n" || out_text 2 " Don't forget to set ip2location login & password in config.\n";
out_text 2 "Awk backend is $CONF_AWK_BACKEND.\n";
test "$CONF_DB_CODE" && out_text 2 "IPv4 database to use is $CONF_DB_CODE." || out_text 2 "No IPv4 database to be used.";
test "$CONF_DB_AUTOUPDATE" && out_text 2 "\n" || test "$CONF_DB_CODE" && out_text 2 " But as auto-update is off you need to download, unzip and put it in data dir ($CONF_DATA_HOME) manually.\n" || out_text 2 "\n";
test "$CONF_DB6_CODE" && out_text 2 "IPv6 database to use is $CONF_DB6_CODE." || out_text 2 "No IPv6 database to be used.";
test "$CONF_DB_AUTOUPDATE" && out_text 2 "\n" || test "$CONF_DB6_CODE" && out_text 2 " But as auto-update is off you need to download, unzip and put it in data dir ($CONF_DATA_HOME) manually.\n" || out_text 2 "\n";


if [ "$CONF_VERBOSE_LEVEL" -ge 2 ] && [ "$CONF_IP2LOC_LOGIN" ]; then

    $PRINT "ip2location login is: $CONF_IP2LOC_LOGIN";

    if [ "$CONF_LENGTH_PRESENT" ]; then
	PASS_LENGTH=$(length "$CONF_IP2LOC_PASS");
    elif [ "$CONF_WC_PRESENT" ]; then
	PASS_LENGTH=$($PRINT_N "$CONF_IP2LOC_PASS" | wc -c);
    fi

    if [ "$CONF_PRINTF_PRESENT" ]; then
	if [ "$CONF_SEQ_PRESENT" ]; then
	    $PRINT_N "ip2location password: ";
	    printf "*%.0s" $(seq 1 $PASS_LENGTH);
	    $PRINT;
	elif [ "$CONF_TR_PRESENT" ]; then
	    $PRINT_N "ip2location password: ";
	    printf "%"$PASS_LENGTH"s" | tr " " "*";
	    $PRINT;
	fi
    fi
    
    $PRINT "Warning! Password is stored in config as plain text!"

fi

if [ -e "$CONFIG_FILE" ]; then
    
    if [ "$CONF_INTERACTIVE_SETUP" ]; then
	while true; do
	    ANSWER=$(prompt_n_read "Config already exist. Do you really want to overwrite it? (y[es]/n[o])" "no");
	    case $ANSWER in
		[Yy]*)
		    break;
		    ;;
		[Nn]*)
		    out_err 1 "Ok, then exiting.\n";
		    exit 1;
		    ;;
		*)
		    unset ANSWER;
	    esac
	    test "$ANSWER" && break || out_text 1 "Can't get you, please repeat!\n";
	done
    else
	out_err 1 "Config already exist. Exiting without writing.\n";
	exit 1;
    fi
    
fi

$PRINT "##" > "$CONFIG_FILE";

if [ "$?" -ne 0 ]; then
    out_err "Cannot write to $CONFIG_FILE, exiting.\n";
    exit 1;
fi

$PRINT "# ip2loc-lean config" >> "$CONFIG_FILE";

if [ "$CONF_DATE_PRESENT" ]; then
    $PRINT "# created at $(date) by setup script" >> "$CONFIG_FILE";
fi

$PRINT_E "##\n\n" >> "$CONFIG_FILE";

test "$CONF_HTTP_BACKEND" || $PRINT_N "# " >> $CONFIG_FILE;
$PRINT_E "CONF_HTTP_BACKEND=\"$CONF_HTTP_BACKEND\";" >> "$CONFIG_FILE";

test "$CONF_AWK_BACKEND" || $PRINT_N "# " >> $CONFIG_FILE;
$PRINT_E "CONF_AWK_BACKEND=\"$CONF_AWK_BACKEND\";" >> "$CONFIG_FILE";

test "$CONF_GREP_PRESENT" || $PRINT_N "# " >> $CONFIG_FILE;
$PRINT_E "CONF_GREP_PRESENT=\"$CONF_GREP_PRESENT\";" >> "$CONFIG_FILE";

test "$CONF_DB_CODE" || $PRINT_N "# " >> $CONFIG_FILE;
$PRINT_E "CONF_DB_CODE=\"$CONF_DB_CODE\";" >> "$CONFIG_FILE";

test "$CONF_DB6_CODE" || $PRINT_N "# " >> $CONFIG_FILE;
$PRINT_E "CONF_DB6_CODE=\"$CONF_DB6_CODE\";" >> "$CONFIG_FILE";

test "$CONF_DB_AUTOUPDATE" || $PRINT_N "# " >> $CONFIG_FILE;
$PRINT_E "CONF_DB_AUTOUPDATE=\"$CONF_DB_AUTOUPDATE\";" >> "$CONFIG_FILE";

test "$CONF_IP2LOC_LOGIN" || $PRINT_N "# " >> $CONFIG_FILE;
$PRINT_E "CONF_IP2LOC_LOGIN=\"$CONF_IP2LOC_LOGIN\";" >> "$CONFIG_FILE";

test "$CONF_IP2LOC_PASS" || $PRINT_N "# " >> $CONFIG_FILE;
$PRINT_E "CONF_IP2LOC_PASS=\"$CONF_IP2LOC_PASS\";" >> "$CONFIG_FILE";

if [ "$CONF_STAT_PRESENT" ]; then
    CONFIG_ACCESS=$(stat -c %a "$CONFIG_FILE");
else
    CONFIG_ACCESS=$(lso "$CONFIG_FILE");
fi

if [ $CONF_IP2LOC_PASS ]; then
    DESIRED_ACCESS="600";
else
    DESIRED_ACCESS="644";
fi

if [ "$CONFIG_ACCESS" -ne "$DESIRED_ACCESS" ]; then
    if [ "$CONF_CHMOD_PRESENT" ]; then
	chmod $DESIRED_ACCESS "$CONFIG_FILE";
	if [ "$?" -eq 0 ]; then
	    CONFIG_ACCESS=$DESIRED_ACCESS;
	fi
    fi
fi

if [ "$CONFIG_ACCESS" -ne "$DESIRED_ACCESS" ]; then
    out_err 1 "Cannot set config access mode $DESIRED_ACCESS, set it manually!\n";
fi
