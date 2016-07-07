#!/bin/sh

init () {

    CONF_SCRIPT_DIR="ip2loc-lean";

    if [ ! "$XDG_CONFIG_HOME" ]; then
	XDG_CONFIG_HOME=~/.config;
    fi

    if [ ! "$XDG_DATA_HOME" ]; then
        XDG_DATA_HOME=~/.local/share;
    fi
    
    
    
    if [ $(command -v printf >/dev/null 2>&1 && echo "1") ]; then
	PRINT="printf %s\n";
	PRINT_E="printf %b\n";
	PRINT_N="printf %s";
	PRINT_EN="printf %b";
    elif [ $(command -v echo >/dev/null 2>&1 && echo "1") ]; then
	PRINT="echo";
	PRINT_E="echo -e";
	PRINT_N="echo -n";
	PRINT_EN="echo -en";
    else
	exit 1;
    fi
    
}

parseOptions () {

    while getopts "hscrClzt" opt
    do
	case $opt in
	    h)
		usage;
		exit 0;
		;;
	    s)
		FIELD3=1;
		;;
	    c)
		FIELD4=1;
		;;
	    r)
		FIELD5=1;
		;;
	    C)
		FIELD6=1;
		;;
	    l)
		FIELD7=1;
		FIELD8=1;
		;;
	    z)
		FIELD9=1;
		;;
	    t)
		FIELD10=1;
		;;
	esac
    done
    
}

usage () {

    $PRINT "Usage: $0 [-scrClzth] <ip address>";
    $PRINT;
    $PRINT "Getting geolocation info for supplied IP address.";
    $PRINT;
    $PRINT "Options:";
    $PRINT_E "\t-s\tTwo-character country code based on ISO 3166 (i.e. US)";
    $PRINT_E "\t-c\tCountry name based on ISO 3166 (i.e. United States), default";
    $PRINT_E "\t-r\tRegion or state name (i.e. Arizona)";
    $PRINT_E "\t-C\tCity name (i.e. Tucson)";
    $PRINT_E "\t-l\tLocation, lat & lon (i.e. 32.242850 -110.946248)";
    $PRINT_E "\t-z\tZIP/Postal code (i.e. 85719)";
    $PRINT_E "\t-t\tUTC time zone (with DST supported) (i.e. -07:00)";
    $PRINT_E "\t-h\tUsage help";
    $PRINT;

}

getDBFile () {

    case $1 in
	DB1LITE)
	    $PRINT_N "IP2LOCATION-LITE-DB1";
	    ;;
	DB3LITE)
	    $PRINT_N "IP2LOCATION-LITE-DB3";
	    ;;
	DB5LITE)
	    $PRINT_N "IP2LOCATION-LITE-DB5";
	    ;;
	DB9LITE)
	    $PRINT_N "IP2LOCATION-LITE-DB9";
	    ;;
	DB11LITE)
	    $PRINT_N "IP2LOCATION-LITE-DB11";
	    ;;
    esac

}

checkPerm () {

    ACCESS=$(stat -c %a "$1");
    
    if [ ! "$ACCESS" ]; then
	
	# Ref.: Adam Courtemanche on http://agileadam.com/2011/02/755-style-permissions-with-ls/
	# Eliah Kagan on http://askubuntu.com/a/152005
	
	ACCESS=$(ls -l "$1" | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);}');
	
    fi
    
    $PRINT_N "$ACCESS";
    
}

findConfig () {

    if [ -f "$XDG_CONFIG_HOME/$CONF_SCRIPT_DIR/ip2loc-lean.conf" ]; then
	CONFIG_FILE="$XDG_CONFIG_HOME/$CONF_SCRIPT_DIR/ip2loc-lean.conf";
    elif [ -f ~/.$CONF_SCRIPT_DIR/ip2loc-lean.conf ]; then
	CONFIG_FILE=~/.$CONF_SCRIPT_DIR/ip2loc-lean.conf;
    else
	$PRINT "No config file found, run setup script first!" >&2;
    fi
    
    if [ -f "$CONFIG_FILE" ]; then
    
    CONF_ACCESS=$(checkPerm "$CONFIG_FILE");
    
	if [ "$CONF_ACCESS" -ne 644 ] && [ "$CONF_ACCESS" -ne 600 ]; then
    
	    $PRINT_E "Wrong config ($CONFIG_FILE) permissions, set it to 644 or 600." >&2;
	    unset CONFIG_FILE;
	
	fi
    
    fi
    
    $PRINT_EN "$CONFIG_FILE";

}

findData () {
    
    if [ -d "$XDG_DATA_HOME/$CONF_SCRIPT_DIR" ]; then
	$PRINT_EN "$XDG_DATA_HOME/$CONF_SCRIPT_DIR";
    elif [ -d ~/.$CONF_SCRIPT_DIR/data ]; then
	$PRINT_EN ~/.$CONF_SCRIPT_DIR/data;
    else
	$PRINT "No data dir found, run setup script first!" >&2;
    fi
    
}

findDB () {
    
    EXT="CSV";
    
    if [ "$1" ]; then
	EXT=$1;
    fi
    
    if [ -f "$DATA_DIR/$DB_FILE_BASENAME.$EXT" ]; then
	$PRINT_N "$DATA_DIR/$DB_FILE_BASENAME.$EXT";
    fi
    
}

downloadDB () {

    if [ ! "$CONF_IP2LOC_LOGIN" ] || [ ! "$CONF_IP2LOC_PASS" ]; then
	$PRINT "No ip2location login and/or password supplied in config." >&2;
	exit 1;
    fi
    
    ZIP_FILE="$DATA_DIR/$DB_FILE_BASENAME.ZIP";

    if [ "$CONF_HTTP_BACKEND" = "curl" ]; then
	curl -o "$ZIP_FILE" "http://www.ip2location.com/download?login=$CONF_IP2LOC_LOGIN&password=$CONF_IP2LOC_PASS&productcode=$CONF_DB_CODE" >/dev/null 2>&1
	ERROR_CODE=$?;
    elif [ "$CONF_HTTP_BACKEND" = "wget" ]; then
	wget -O "$ZIP_FILE" -q "http://www.ip2location.com/download?login=$CONF_IP2LOC_LOGIN&password=$CONF_IP2LOC_PASS&productcode=$CONF_DB_CODE" >/dev/null 2>&1
	ERROR_CODE=$?;
    else
	$PRINT "No http downloader found." >&2;
	exit 1;
    fi
    
    if [ "$ERROR_CODE" -ne 0 ]; then
	$PRINT "General download error." >&2;
    fi
    
    if [ ! -f "$ZIP_FILE" ]; then
	$PRINT "Download failed." >&2;
	exit 1;
    fi
    
    if [ "$CONF_GREP_PRESENT" ]; then
    
	if [ ! -z "$(grep 'NO PERMISSION' $ZIP_FILE)" ]; then
	    $PRINT "Permission denied by ip2location download service." >&2;
	    exit 1;
	fi
    
	if [ ! -z "$(grep '5 times' $ZIP_FILE)" ]; then
	    $PRINT "Download quota exceed." >&2;
	    exit 1;
	fi
    
    fi
    
    $PRINT "$ZIP_FILE";

}

createIndex () {

    if [ "$1" -eq 1 ]; then
	DELIMITER="\"*,\"*";
	IN_FILE=$DB_FILE;
	OUT_FILE="$DATA_DIR/$DB_FILE_BASENAME.IDX";
    elif [ "$1" -eq 2 ]; then
	DELIMITER=" ";
	IN_FILE="$DATA_DIR/$DB_FILE_BASENAME.IDX";
	OUT_FILE="$DATA_DIR/$DB_FILE_BASENAME.ID2";
    fi
    
    $CONF_AWK_BACKEND -F "$DELIMITER"  "BEGIN{NR=-1; totalBytes=0; prevBytes=0; } { prevBytes = totalBytes; totalBytes += length(\$0) + 1; gsub(/\"/, \"\"); if (NR % 100 == 0) { print \$1 \" \" prevBytes; }} END { print \$1 \" \" totalBytes; }" "$IN_FILE"  > "$OUT_FILE";

}

prepend () {

    if [ "$1" ]; then
	$PRINT_EN "$2,$1";
    else
	$PRINT_EN "$2";
    fi

}

init;
CONFIG_FILE=$(findConfig);
DATA_DIR=$(findData);

if [ ! "$CONFIG_FILE" ] || [ ! "$DATA_DIR" ]; then
    exit 1;
fi

. "$CONFIG_FILE";

parseOptions "$@";
shift $((OPTIND-1));

IP_ADDRESS=$1;

DB_FILE_BASENAME=$(getDBFile "$CONF_DB_CODE");
DB_FILE=$(findDB);

if [ ! "$DB_FILE" ]; then

    if [ "$CONF_DB_AUTOUPDATE" ]; then
    
	ZIP_FILE=$(findDB "ZIP");
	
	if [ ! "$ZIP_FILE" ]; then
    	    $PRINT "DB not found. Downloading..." >&2;
    	    RESULT=$(downloadDB);
    	    if [ "$?" -ne 0 ]; then
    		$PRINT "Error while downloading:" >&2;
    		$PRINT "$RESULT" >&2;
	    else
		ZIP_FILE=$RESULT;
	    fi
	fi
	if [ -f "$ZIP_FILE" ]; then
	    $PRINT "Got zip file at $ZIP_FILE, unpacking..." >&2;
	    unzip "$ZIP_FILE" "$DB_FILE_BASENAME.CSV" -d "$DATA_DIR" >/dev/null 2>&1;
	fi;
    else
        $PRINT "DB not found." >&2;
    fi
    
fi

DB_FILE=$(findDB);

if [ "$DB_FILE" ]; then
    
    INDEX_FILE=$(findDB "IDX");
    
    if [ ! "$INDEX_FILE" ]; then
	$PRINT_N "Creating primary index..." >&2;
        createIndex 1;
        $PRINT " OK!" >&2;
    fi
    
    INDEX_FILE=$(findDB "IDX");
    
    if [ -f "$INDEX_FILE" ]; then
    
	INDEX2_FILE=$(findDB "ID2");
    
	if [ ! "$INDEX2_FILE" ]; then
	    $PRINT_N "Creating secondary index..." >&2;
	    createIndex 2;
	    $PRINT " OK!" >&2;
        fi
        
        INDEX2_FILE=$(findDB "ID2");
        
        if [ ! "$INDEX2_FILE" ]; then
    	    $PRINT "Cannot find nor create secondary index file." >&2;
        fi
        
    else
	$PRINT "Cannot find nor create primary index file." >&2;
    fi
    
fi

if [ "$INDEX_FILE" ] && [ "$INDEX2_FILE" ]; then

    IP_NUMBER=$($PRINT "$IP_ADDRESS" | $CONF_AWK_BACKEND -F "." '{print 16777216 * $1 + 65536 * $2 + 256 * $3 + $4;}');
    
    SKIP_BYTES=$(awk "{if (\$1 > $IP_NUMBER) {exit 0;} byteskip=\$2} END {print byteskip;}" "$INDEX2_FILE");
    SKIP_BYTES=$(dd if="$INDEX_FILE" bs=1 skip=$SKIP_BYTES 2>/dev/null | awk "{if (\$1 > $IP_NUMBER) {exit 0;} byteskip=\$2} END {print byteskip;}");
    
    case $CONF_DB_CODE in
	DB1LITE)
	    I=4;
	    ;;
	DB3LITE)
	    I=6;
	    ;;
	DB5LITE)
	    I=8;
	    ;;
	DB9LITE)
	    I=9;
	    ;;
	DB11LITE)
	    I=10;
	    ;;
    esac
    
    while true; do
		
	if [ $(eval $PRINT_EN "\$FIELD$I") ]; then
	    FIELDS=$(prepend "$FIELDS" "\$$I");
	fi
	
	I=$(($I - 1));
	
	test $I -eq 2 && break;
    
    done
    
    if [ ! "$FIELDS" ]; then
	FIELDS="\$4";
    fi
    
    dd if="$DB_FILE" bs=1 skip=$SKIP_BYTES 2>/dev/null | awk -F "\"*,\"*" "{ gsub(/\"/, \"\"); if (\$1 <= $IP_NUMBER && \$2 >= $IP_NUMBER) { print $FIELDS; exit 0;}}";
    
fi
