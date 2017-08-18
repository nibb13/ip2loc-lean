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

    while getopts "uhscrClzt" opt
    do
	case $opt in
	    h)
		usage;
		exit 0;
		;;
	    u)
		$(updateDB >/dev/null);
		if [ $? -eq 0 ]; then
		    createIndex 1 1;
		    createIndex 2 1;
		    flushTemp;
		else
    		    $PRINT "Autoupdate of IPv4 failed." >&2;
		fi
		
		$(updateDB 1 >/dev/null);
		if [ $? -eq 0 ]; then
		    createIndex 1 1 1;
		    createIndex 2 1 1;
		    flushTemp 1;    
		else
    		    $PRINT "Autoupdate of IPv6 failed." >&2;
		fi
		
		setCronjob;
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

    $PRINT "Usage: $0 [-scrClztuh] IP_ADDRESS [OUT_FORMAT]";
    $PRINT;
    $PRINT "Getting geolocation info for supplied IP address.";
    $PRINT "v 1.0.0-RC1";
    $PRINT;
    $PRINT "OUT_FORMAT can be:";
    $PRINT_E "\t\tempty (default) - fields delimited by ::";
    $PRINT_E "\t\tcsv - fields delimited by , and embraced by \"";
    $PRINT;
    $PRINT "Options:";
    $PRINT_E "\t-s\tTwo-character country code based on ISO 3166 (i.e. US)";
    $PRINT_E "\t-c\tCountry name based on ISO 3166 (i.e. United States), default";
    $PRINT_E "\t-r\tRegion or state name (i.e. Arizona)";
    $PRINT_E "\t-C\tCity name (i.e. Tucson)";
    $PRINT_E "\t-l\tLocation, lat & lon (i.e. 32.242850 -110.946248)";
    $PRINT_E "\t-z\tZIP/Postal code (i.e. 85719)";
    $PRINT_E "\t-t\tUTC time zone (with DST supported) (i.e. -07:00)";
    $PRINT_E "\t-u\tUpdate databases (internal use)";
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
	DB1LITEIPV6)
	    $PRINT_N "IP2LOCATION-LITE-DB1.IPV6";
	    ;;
	DB3LITEIPV6)
	    $PRINT_N "IP2LOCATION-LITE-DB3.IPV6";
	    ;;
	DB5LITEIPV6)
	    $PRINT_N "IP2LOCATION-LITE-DB5.IPV6";
	    ;;
	DB9LITEIPV6)
	    $PRINT_N "IP2LOCATION-LITE-DB9.IPV6";
	    ;;
	DB11LITEIPV6)
	    $PRINT_N "IP2LOCATION-LITE-DB11.IPV6";
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

    FILENAME="$DB_FILE_BASENAME";

    if [ "$2" ]; then
	FILENAME="$DB6_FILE_BASENAME";
    fi
    
    if [ -f "$DATA_DIR/$FILENAME.$EXT" ]; then
	$PRINT_N "$DATA_DIR/$FILENAME.$EXT";
    fi
    
}

downloadDB () {

    if [ ! "$CONF_IP2LOC_LOGIN" ] || [ ! "$CONF_IP2LOC_PASS" ]; then
	$PRINT "No ip2location login and/or password supplied in config." >&2;
	exit 1;
    fi
    
    ZIP_FILE="$DATA_DIR/$DB_FILE_BASENAME.ZIP";
    DB_CODE="$CONF_DB_CODE";
    
    if [ "$1" ]; then
	ZIP_FILE="$DATA_DIR/$DB6_FILE_BASENAME.ZIP";
	DB_CODE="$CONF_DB6_CODE";
    fi

    if [ "$CONF_HTTP_BACKEND" = "curl" ]; then
	curl -o "$ZIP_FILE" "http://www.ip2location.com/download?login=$CONF_IP2LOC_LOGIN&password=$CONF_IP2LOC_PASS&productcode=$DB_CODE" >/dev/null 2>&1
	ERROR_CODE=$?;
    elif [ "$CONF_HTTP_BACKEND" = "wget" ]; then
	wget -O "$ZIP_FILE" -q "http://www.ip2location.com/download?login=$CONF_IP2LOC_LOGIN&password=$CONF_IP2LOC_PASS&productcode=$DB_CODE" >/dev/null 2>&1
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

updateDB () {

    if [ ! "$CONF_DB_AUTOUPDATE" ]; then
	$PRINT "No autoupdate set." >&2;
	exit 1;
    fi

    mkdir -p "$DATA_DIR/tmp";
    
    if [ "$?" -ne 0 ]; then
	$PRINT "Error creating $DATA_DIR/tmp directory. Exiting." >&2;
	exit 1;
    fi

    ZIP_FILE=$(findDB "ZIP" "$1");
    
    if [ "$1" ] && [ ! "$DB6_FILE_BASENAME" ] ; then
	$PRINT_N "No database code set for IPv6 in config" >&2;
	exit 1;
    elif [ ! "$1" ] && [ ! "$DB_FILE_BASENAME" ]; then
	$PRINT_N "No database code set for IPv4 in config" >&2;
	exit 1;
    fi

    if [ ! "$ZIP_FILE" ]; then
	$PRINT "DB not found. Downloading..." >&2;
	RESULT=$(downloadDB "$1");
	if [ "$?" -ne 0 ]; then
	    $PRINT "Error while downloading:" >&2;
	    $PRINT "$RESULT" >&2;
	    exit 1;
	else
	    ZIP_FILE=$RESULT;
	fi
    fi
    
    if [ -f "$ZIP_FILE" ]; then
    
	$PRINT "Got zip file at $ZIP_FILE, unpacking..." >&2;
	if [ "$CONF_GREP_PRESENT" ]; then
	    FILENAME=$(unzip -lq "$ZIP_FILE" | grep "\.CSV$");
	else
	    if [ "$1" ]; then
		FILENAME="$DB6_FILE_BASENAME.CSV";
	    else
		FILENAME="$DB_FILE_BASENAME.CSV";
	    fi
	fi
	unzip "$ZIP_FILE" "$FILENAME" -d "$DATA_DIR/tmp" >/dev/null 2>&1;
	EXIT_CODE=0;
	if [ "$?" -ne 0 ]; then
	    $PRINT "Error unpacking $ZIP_FILE." >&2;
	    EXIT_CODE=1;
	fi
	chmod 644 "$DATA_DIR/tmp/$FILENAME";
	rm "$ZIP_FILE";
	if [ "$?" -ne 0 ]; then
	    $PRINT "Error removing $ZIP_FILE." >&2
	    EXIT_CODE=1;
	fi
	
	$PRINT_EN "$ZIP_FILE";
	exit $EXIT_CODE;
	
    fi;
    
}

createIndex () {

    if [ "$2" ]; then
	DIR="tmp/";
    fi
    
    FILENAME="$DB_FILE_BASENAME";
    
    if [ "$3" ]; then
	FILENAME="$DB6_FILE_BASENAME";
    fi

    if [ "$1" -eq 1 ]; then
	DELIMITER="\"*,\"*";
	IN_FILE="$DATA_DIR/$DIR$FILENAME.CSV";
	OUT_FILE="$DATA_DIR/$DIR$FILENAME.IDX";
    elif [ "$1" -eq 2 ]; then
	DELIMITER=" ";
	IN_FILE="$DATA_DIR/$DIR$FILENAME.IDX";
	OUT_FILE="$DATA_DIR/$DIR$FILENAME.ID2";
    fi
    
    $CONF_AWK_BACKEND -F "$DELIMITER"  "BEGIN{NR=-1; totalBytes=0; prevBytes=0; } { prevBytes = totalBytes; totalBytes += length(\$0) + 1; gsub(/\"/, \"\"); if (NR % 100 == 0) { print \$1 \" \" prevBytes; }} END { print \$1 \" \" totalBytes; }" "$IN_FILE"  > "$OUT_FILE";

}

flushTemp () {

    #TODO: make wait for other ip2loc-lean processes exit.
    
    FILENAME="$DB_FILE_BASENAME";

    if [ "$1" ]; then
	FILENAME="$DB6_FILE_BASENAME";
    fi

    mv -f "$DATA_DIR/tmp/$FILENAME.CSV" "$DATA_DIR/";
    mv -f "$DATA_DIR/tmp/$FILENAME.IDX" "$DATA_DIR/";
    mv -f "$DATA_DIR/tmp/$FILENAME.ID2" "$DATA_DIR/";
    if [ "$DATA_DIR" ]; then
	rm -rf "$DATA_DIR/tmp";
    fi;

}

setCronjob () {
    
    RAND_DAY=$(awk 'BEGIN {srand(); print int(1 + rand() * 7)}');
    CURR_CRONTAB=$(crontab -l 2>/dev/null | grep -v 'ip2loc-lean');
    NEW_CRONTAB="0 0 $RAND_DAY * * ip2loc-lean.sh -u >/dev/null 2>&1\n";
    if [ "$CURR_CRONTAB" ]; then
	NEW_CRONTAB="$NEW_CRONTAB$CURR_CRONTAB\n";
    fi
    #TODO: get absolute path for ip2loc-lean.sh
    $PRINT_EN "$NEW_CRONTAB" | crontab -;
    
}

prepend () {

    PRE_BLOCK="";
    DELIMITER="\"::\"";
    POST_BLOCK="";

    if [ "$OUT_FORMAT" = "csv" ]; then
	PRE_BLOCK="\"\\\"\"";
	DELIMITER="\",\"";
	POST_BLOCK="\"\\\"\"";
    fi

    if [ "$1" ]; then
	$PRINT_EN "$PRE_BLOCK$2$POST_BLOCK$DELIMITER$1";
    else
	$PRINT_EN "$PRE_BLOCK$2$POST_BLOCK";
    fi

}

init;
CONFIG_FILE=$(findConfig);
DATA_DIR=$(findData);

if [ ! "$CONFIG_FILE" ] || [ ! "$DATA_DIR" ]; then
    exit 1;
fi

. "$CONFIG_FILE";

DB_FILE_BASENAME=$(getDBFile "$CONF_DB_CODE");
DB6_FILE_BASENAME=$(getDBFile "$CONF_DB6_CODE");

parseOptions "$@";
shift $((OPTIND-1));

IP_ADDRESS=$1;
OUT_FORMAT=$2;

# Not sure if this is the best way:
IS_IPV4=$($PRINT "$IP_ADDRESS" | awk -F "." '{if ($1 < 1 || $1 > 255 || $2 < 0 || $2 > 255 || $3 < 0 || $3 > 255 || $4 < 1 || $4 > 255){exit 0} print "1";}');

# Even worse approach:
if [ ! "$IS_IPV4" ]; then
    IS_IPV6="1";
fi

# TODO: Fix this ^

DB_FILE=$(findDB "" "$IS_IPV6");

if [ ! "$DB_FILE" ]; then
    
    $PRINT "Downloading db" >&2;
    
    ZIP_FILE=$(updateDB "$IS_IPV6");

    if [ $? -eq 0 ]; then
	$PRINT "Downloaded, creating index" >&2;
	createIndex 1 1 "$IS_IPV6";
	createIndex 2 1 "$IS_IPV6";
	flushTemp "$IS_IPV6";
	setCronjob;
    else
	test "$IS_IPV4" && $PRINT_N "IPv4 " || $PRINT_N "IPv6 ";
        $PRINT "DB not found." >&2;
    fi
    
fi

DB_FILE=$(findDB "" "$IS_IPV6");

if [ "$DB_FILE" ]; then
    
    INDEX_FILE=$(findDB "IDX" "$IS_IPV6");
    
    if [ ! "$INDEX_FILE" ]; then
	$PRINT_N "Creating primary index..." >&2;
        createIndex 1 "" "$IS_IPV6";
        $PRINT " OK!" >&2;
    fi
    
    INDEX_FILE=$(findDB "IDX" "$IS_IPV6");
    
    if [ -f "$INDEX_FILE" ]; then
    
	INDEX2_FILE=$(findDB "ID2" "$IS_IPV6");
    
	if [ ! "$INDEX2_FILE" ]; then
	    $PRINT_N "Creating secondary index..." >&2;
	    createIndex 2 "" "$IS_IPV6";
	    $PRINT " OK!" >&2;
        fi
        
        INDEX2_FILE=$(findDB "ID2" "$IS_IPV6");
        
        if [ ! "$INDEX2_FILE" ]; then
    	    $PRINT "Cannot find nor create secondary index file." >&2;
        fi
        
    else
	$PRINT "Cannot find nor create primary index file." >&2;
    fi
    
fi

if [ "$INDEX_FILE" ] && [ "$INDEX2_FILE" ]; then

    if [ "$IS_IPV4" ]; then
	IP_NUMBER=$($PRINT "$IP_ADDRESS" | $CONF_AWK_BACKEND -F "." '{print 16777216 * $1 + 65536 * $2 + 256 * $3 + $4;}');
    else
	$PRINT "Expanding IPv6 address...";
	IP_ADDRESS=$($PRINT_EN "$IP_ADDRESS" | awk '
{

ORS="";

count = split($0, condensedParts, "::");

if (count == 1){
    fieldsCount = split($0, fields, ":");
} else {
    part1Count = split(condensedParts[1], part1, ":");
    part2Count = split(condensedParts[2], part2, ":");
    
    missingFieldsCount = 8 - (part1Count + part2Count);
    zeroes = "0000";
    for (i=1; i<missingFieldsCount; i++){
	zeroes = zeroes"0000";
    }
    
    for (i=1; i<=part1Count; i++){
	fields[i] = part1[i];
    }
    
    fields[part1Count+1] = zeroes;
    
    for (i=1; i<=part2Count; i++){
	fields[i+part1Count+1] = part2[i];
    }
    
    fieldsCount = part1Count + part2Count + 1;
    
}

for (i=1; i<=fieldsCount; i++){
    pad = 4 - length(fields[i]);
    for (j=1; j<=pad; j++){print "0"};
    print toupper(fields[i]);
}

}');

    $PRINT "Done, result: $IP_ADDRESS";

	if [ "$CONF_BC_PRESENT" ]; then
		$PRINT "bc is present, using it";
		IP_NUMBER=$($PRINT "ibase=16;$IP_ADDRESS" | bc);
		$PRINT "Done, number: $IP_NUMBER";
	else
		IP_NUMBER=$($PRINT_N "$IP_ADDRESS" | awk '

function arr_add(one, two, oneLength, twoLength)
{

	c = 0;
	rCount = 0;
	
	if (one[1] == "-") {onePad = 1;} else {onePad = 0;}
	if (two[1] == "-") {twoPad = 1;} else {twoPad = 0;}

	oneIndex = oneLength + onePad;
	twoIndex = twoLength + twoPad;

	do {

		elemOne = one[oneIndex];
		elemTwo = two[twoIndex];
		if (elemOne == "" || elemOne == "-") {elemOne=0}
		if (elemTwo == "" || elemTwo == "-") {elemTwo=0}

		s = elemOne + elemTwo + c;

		if (s < 10){
			one[oneIndex + (1 - onePad)] = s;
			c = 0;
		} else {
			one[oneIndex + (1 - onePad)] = s - 10;
			c = 1;
		}
		
		oneIndex--;
		twoIndex--;
		rCount++;

	} while(twoIndex - twoPad > 0 || onePad == 0 && oneIndex > 0)
	
	if (c){
	    one[1]=1;
	    rCount++;
	} else if (!onePad){one[1] = "-";}
	
	if (rCount > oneLength){return rCount};
	return oneLength;

}

{

ORS="";

dec[1] = 0;
digit[1] = 1;
rLength = 1;
digitsCount = split($0, digits, "");
for (j=1; j<=digitsCount; j++){
	n = int("0x"digits[j]);
	for (t=8; t>0; t=rshift(t,1)){
		rLength = arr_add(dec, dec, rLength, rLength);
		if (and(n, t) != 0) {rLength = arr_add(dec, digit, rLength, 1)}
	}
}

if (dec[1] == "-") {pad = 1;} else {pad = 0;}

for (i=1; i<=rLength+pad; i++){
	print dec[i+pad];
}

}');
	fi
    fi
    
    SKIP_BYTES=$(awk "{if (\$1 > $IP_NUMBER) {exit 0;} byteskip=\$2} END {print byteskip;}" "$INDEX2_FILE");
    SKIP_BYTES=$(dd if="$INDEX_FILE" bs=1 skip=$SKIP_BYTES 2>/dev/null | awk "{if (\$1 > $IP_NUMBER) {exit 0;} byteskip=\$2} END {print byteskip;}");
    
    case $CONF_DB_CODE in
	DB1LITE*)
	    I=4;
	    ;;
	DB3LITE*)
	    I=6;
	    ;;
	DB5LITE*)
	    I=8;
	    ;;
	DB9LITE*)
	    I=9;
	    ;;
	DB11LITE*)
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
	FIELDS=$(prepend "" "\$4");
    fi
    
    dd if="$DB_FILE" bs=1 skip=$SKIP_BYTES 2>/dev/null | awk -F "\"*,\"*" "{ gsub(/\"\r/, \"\"); if (\$1 <= $IP_NUMBER && \$2 >= $IP_NUMBER) { print $FIELDS; exit 0;}}";
    
fi
