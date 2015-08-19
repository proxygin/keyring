#!/bin/bash

# Where do you want to store your keys?
ENCRYPTED_KEYFILE="$HOME/.config/temmelighemmeligt.gpg"

# Parameters
EXPRESSION=""
CLOAK=false
CROP_DESCRIPTION=false
CROP_NAME=false
CROP_PASS=false

function append_key (){
    if [ "n" == "n$ENCRYPTED_KEYFILE" ]; then
        echo "ENCRYPTED_KEYFILE not set. Please edit the script."
        exit 1;
    fi
    touch "$ENCRYPTED_KEYFILE"
    if [ ! -f "$ENCRYPTED_KEYFILE" ]; then
        echo "Your ENCRYPTED_KEYFILE filepath dosn't make sense. Fix plz... :E" 
        exit 1;
    fi

    gpg -d -q "$ENCRYPTED_KEYFILE" | (cat && echo -e "$NEW_KEY") | gpg --symmetric --cipher aes256 > "${ENCRYPTED_KEYFILE}.new"
    if [ $? -ne 0 ]; then echo "Something when wrong. Do you have gpg?" && exit 1; fi
    mv "${ENCRYPTED_KEYFILE}.new" "${ENCRYPTED_KEYFILE}"
}


function extract_line (){
    if [ "n" == "n$ENCRYPTED_KEYFILE" ]; then
        echo "ENCRYPTED_KEYFILE not set. Please edit the script."
        exit 1;
    fi
    touch "$ENCRYPTED_KEYFILE"
    if [ ! -f "$ENCRYPTED_KEYFILE" ]; then
        echo "Your ENCRYPTED_KEYFILE filepath dosn't make sense. Fix plz... :E" 
        exit 1;
    fi

    INPUT=$(gpg -d -q "$ENCRYPTED_KEYFILE")
    #Exit if gpg command failed.
    if [ -z "$INPUT" ] ; then exit 0; fi
    MATCHED=$(egrep --max-count=1 -e "^[^\s]*$EXPRESSION" <<< "$INPUT")
}

function print_pass (){
    NAME=$( awk '{print $1}' <<< "$MATCHED" )
    PASS=$( awk '{print $2 }' <<< "$MATCHED" )

    if [ "n$MATCHED" == "n" ]; then  exit 1; fi

    DESCRIPTION=$( sed -e 's/'$NAME'//' <<< "$MATCHED" )
    DESCRIPTION=$( sed -e 's/'$PASS'//' <<< "$DESCRIPTION" )
    DESCRIPTION=${DESCRIPTION%%}
    if $CLOAK; then
        PASS=$( sed -e 's/'$PASS'/\\e\[47;06m'$PASS'\\e\[0m/' <<< "$PASS" )
    fi
    if ! $CROP_NAME; then
        OUTPUT+="$NAME"
    fi
    if ! $CROP_PASS; then
        OUTPUT+="\t$PASS"
    fi
    if ! $CROP_DESCRIPTION; then
        OUTPUT+="\t$DESCRIPTION"
    fi
    echo -e ${OUTPUT} | sed -e 's/^\t//' | sed -e 's/\t$//'
}
function print_help (){
    echo "Usage: keyring [OPTIONS] <search string> | keyring --add <name> <password> <comment>" >&2
    echo >&2
    echo "keyring is a small scripts that allows easy extraction">&2
    echo "of passwords from encrypted password-file.">&2
    echo "The password-files location is hardcoded into the the script.">&2
    echo "<search string> must denote the name, for a partial name of the">&2
    echo "password you are looking for.">&2
    echo >&2
    echo "Options:" >&2
    echo "  -a, --add               takes exacly 3 arguments. Remember \"quotes\" around. Excludes any other option." >&2
    echo >&2
    echo "  -c, --cloak-pass        cloak the password by outputting it in white, with white background." >&2
    echo "  -e, --easy-copy         make the password easy to copy. This will remove everything but the password." >&2
    echo "  -p, --pass-only         only output name and password" >&2
    echo "  -d, --description-only  only output name and destription" >&2
    echo "  -h, --help              display this help message" >&2
}


while [ $# -gt 0 ]; do
    if [ $1 == "--add" ]||[ $1 == "-a" ]; then
    	if [ $# -ne 4 ]; then
    		print_help
    		exit 1
    	fi
    
    	NEW_KEY="$2\t\t$3\t\t$4"
    	append_key
    	exit 0
    fi
    case "$1" in
    -c|--cloak-pass)
        CLOAK=true
        shift 1
        ;;
    -e|--easy-copy)
        CROP_NAME=true
        CROP_DESCRIPTION=true
        shift 1
        ;;
    -p|--pass-only)
        CROP_DESCRIPTION=true
        shift 1
        ;;
    -d|--description-only)
        CROP_PASS=true
        shift 1
        ;;
    -h|--help)
        print_help
        exit 0
        ;;
    *)
        if [ -z $EXPRESSION ]; then
            EXPRESSION=$1
            shift 1
        else
            exit 0
        fi
        ;;
    esac
done

if [ -z $EXPRESSION ]; then
    print_help
    exit 0
fi
extract_line $1
print_pass
