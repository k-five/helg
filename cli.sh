#!/bin/bash

################################################################################
# Bash CLI template
# A more flexible CLI parser (way of parsing)
# 20XX (C) Shakiba Moshiri
################################################################################


################################################################################
# Bash CLI to check BGP route from Hurricane Elective root server which we call:
# Website: https://lg.he.net/
# Commands BGP Route
#
# The website does not have a public API and this script is a work around!
# It may not work in the future, so make sure so you how to read the code for
# later manipulation
################################################################################


################################################################################
# an associative array for storing color and a function for colorizing
################################################################################
declare -A _colors_;
_colors_[ 'red' ]='\x1b[1;31m';
_colors_[ 'green' ]='\x1b[1;32m';
_colors_[ 'yellow' ]='\x1b[1;33m';
_colors_[ 'cyan' ]='\x1b[1;36m';
_colors_[ 'white' ]='\x1b[1;37m';
_colors_[ 'reset' ]='\x1b[0m';

function colorize(){
    if [[ ${_colors_[ $1 ]} ]]; then
        echo -e "${_colors_[ $1 ]}$2${_colors_[ 'reset' ]}";
    else
        echo 'wrong color name!';
    fi
}

function print_title(){
    echo $(colorize cyan "$@");
}


################################################################################
# key-value array
################################################################################
declare -A _ip;
_ip['flag']=0;
_ip['args']='';

declare -A _log;
_log['flag']=0;
_log['args']='';
_log['html']=1;
_log['txt']=0;
_log['term']=0;
_log['json']=0;

declare -A _check;
_check['flag']=0;
_check['args']='';
_check['debug']=0;

################################################################################
# __help function
################################################################################
function _cli_title(){
    echo "Hurricane Electric's Network Looking Glass";
    echo "==========================================";
    echo "BGP Route:    Hurricane Electric Fremont 1";
}

function _ip_help(){
    printf "%-25s %s\n" "-I │ --ip" "list of IPs to check";
    printf "%-40s %s\n" "   ├── $(colorize 'yellow' '<IP/MASK>')" "request for these IP/MASK ...";
    printf "%-40s %s\n" "   └── $(colorize 'yellow' '<FILE>')" "read list of IP(s) from a file";
}

function _log_help(){
    printf "%-25s %s\n" "-L │ --log" "enable log for";
    printf "%-40s %s\n" "   ├── $(colorize 'cyan' 'html')" "save the log in HTML format (default)";
    printf "%-40s %s\n" "   ├── $(colorize 'cyan' 'txt')" "save the output in txt";
    printf "%-40s %s\n" "   ├── $(colorize 'cyan' 'json')" "save the output in JSON";
    printf "%-40s %s\n" "   └── $(colorize 'cyan' 'terminal')" "print result on screen (Terminal)";
}

function _check_help(){
    printf "%-25s %s\n" "-C │ --check" "check prerequisites";
    printf "%-40s %s\n" "   ├── $(colorize 'cyan' 'cmd')" "check prerequisite commands";
    printf "%-40s %s\n" "   └── $(colorize 'cyan' 'debug')" "turn on debug mode";
}


function _help(){
    echo "$(_cli_title)"
    echo
    printf "%-25s %s\n" "-h │ --help" "show / print help";
    echo
    echo "$(_ip_help)"
    echo
    echo "$(_log_help)"
    echo
    echo "$(_check_help)"
    echo
    echo "Developer Shakiba Moshiri"
    echo "source    https://github.com/k-five/helg"
    exit 0;
}

if [[ ${#} == 0 ]]; then
    _help;
fi

################################################################################
# parse command line options
################################################################################
mapfile -t ARGS < <( perl -lne 'print $& while /(?:(?! -)[\s\S])+/ig' <<< "$@");
if [[ ${#ARGS[@]} == 0 ]]; then
    _help;
fi

function request(){
    # passed order
    # request $ip $make $token_value $fremont1;
    local ip=$1;
    local mask=$2;
    local token_value=$3;
    local fremont1=$4;

    if [[ ${_check['debug']} == 1 ]]; then
        printf "%-30s %s" "request-for:${ip}/${mask}~" "~" | tr ' ~' '. ';
    fi

    curl -G -sL 'https://lg.he.net/' \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:86.0) Gecko/20100101 Firefox/86.0' \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        --compressed -H 'Referer: https://lg.he.net/' \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -H 'Origin: https://lg.he.net' \
        -H 'DNT: 1' \
        -H 'Connection: keep-alive' \
        -H 'Upgrade-Insecure-Requests: 1' \
        -H 'Pragma: no-cache' \
        -H 'Cache-Control: no-cache' \
        --data-urlencode "token=${token_value}" \
        --data-raw "${fremont1}" > ${ip}.html 2> ${ip}.error.html

    if [[ ${_check['debug']} == 1 ]]; then
        if [[ $? == 0 ]]; then
            printf "[ $(colorize 'green' 'OK') ]\n";
        else
            printf "[ $(colorize 'red' 'Error') ]\n";
        fi
    fi
}

function log_html(){
    # passed order
    # log_html $ip $file_name
    local ip=$1;
    local file_name=$2;

    if [[ ${_check['debug']} == 1 ]]; then
        printf "%-30s %s" "html-log:~" "~" | tr ' ~' '. ';
    fi

    perl -lne '$/=undef; /<table class="tablesorter">.*<\/table>/gs && print $&' ${ip}.html > ${file_name};
    # cat ${file_name}.html | pup | tee ${file_name}.html > /dev/null;

    if [[ ${_check['debug']} == 1 ]]; then
        if [[ $? == 0 ]]; then
            printf "[ $(colorize 'green' 'OK') ]\n";
        else
            printf "[ $(colorize 'red' 'Error') ]\n";
        fi
    fi
}

function log_txt(){
    local file_name=$1;

    if [[ ${_check['debug']} == 1 ]]; then
        printf "%-30s %s" "txt-log:~" "~" | tr ' ~' '. ';
    fi

    {
        pup  "thead > tr:nth-child(1) text{}" < ${file_name}.html | tr ' ' '-' | xargs echo
        pup  "tbody > tr:nth-child(1) text{}" < ${file_name}.html | xargs echo | perl -lpe 's/( , ?)/,/g'
        pup  "tbody > tr:nth-child(2) text{}" < ${file_name}.html | xargs echo | perl -lpe 's/( , ?)/,/g'
    } | while read line; do
        args=();
        for arg in "$line"; do
            args+=($arg)
        done
        printf "%-15s %-20s %-15s %-10s %-10s %-10s"  "${args[@]:0:6}"
        printf "%-40s"  "${args[@]:6:1}"
        printf "%-10s %s"  "${args[@]:7}"
        echo;
    done > ${file_name}.txt;

    pup  "tfoot > tr:nth-child(1) text{}" < ${file_name}.html | xargs echo | perl -lne 's/(?:(?!.*\d) )/-/g && print' >> ${file_name}.txt;

    if [[ ${_check['debug']} == 1 ]]; then
        if [[ $? == 0 ]]; then
            printf "[ $(colorize 'green' 'OK') ]\n";
        else
            printf "[ $(colorize 'red' 'Error') ]\n";
        fi
    fi
}

function log_term(){
    local file_name=$1;
    {
        pup  "thead > tr:nth-child(1) text{}" < ${file_name}.html | tr ' ' '-' | xargs echo
        pup  "tbody > tr:nth-child(1) text{}" < ${file_name}.html | xargs echo | perl -lpe 's/( , ?)/,/g'
        pup  "tbody > tr:nth-child(2) text{}" < ${file_name}.html | xargs echo | perl -lpe 's/( , ?)/,/g'
    } | while read line; do
        args=();
        for arg in "$line"; do
            args+=($arg)
        done
        printf "%-15s %-20s %-15s %-10s %-10s %-10s"  "${args[@]:0:6}"
        printf "%-40s"  "${args[@]:6:1}"
        printf "%-10s %s"  "${args[@]:7}"
        echo;
    done

    pup  "tfoot > tr:nth-child(1) text{}" < ${file_name}.html | xargs echo | perl -lne 's/(?:(?!.*\d) )/-/g && print'
}

################################################################################
# main function to send request to lg.he.net
################################################################################
function get_bgp_route(){
    ip=${1///*/};
    mask=${1//*\/};
    server='core3.fmt1.he.net';

    file_name=$(date '+%F-%T'___${ip});
    token_value=$(curl -sL 'https://lg.he.net/' | grep -i token | perl -lne '/(?<=value=").*?(?=")/ && print $&');

    # sample
    # fremont1="&routers%5B%5D=core3.fmt1.he.net&command=bgproute&ip=5.145.115.0%2F24&afPref=preferV6";
    fremont1="&routers%5B%5D=${server}&command=bgproute&ip=${ip}%2F${mask}&afPref=preferV6";
    # echo "token_value $token_value";
    # echo "request $token";

    ##########
    # request
    ##########
    request $ip $mask $token_value $fremont1;

    ##########
    # log html
    ##########
    if [[ ${_log['html']} == 1 ]]; then
        log_html $ip ${file_name}.html;
    fi

    ##########
    # log txt
    ##########
    if [[ ${_log['txt']} == 1 ]]; then
        log_txt ${file_name};
    fi

    ##########
    # log term
    ##########
    if [[ ${_log['term']} == 1 ]]; then
        log_term ${file_name};
    fi

    ##########
    # log json
    ##########
    if [[ ${_log['json']} == 1 ]]; then
        if [[ ${_check['debug']} == 1 ]]; then
            printf "%-30s %s" "json-log:~" "~" | tr ' ~' '. ';
        fi

        log_term ${file_name} | jq -s -R 'split("\n") | map(select(length>0)) | map(split(" +";"g"))' > ${file_name}.json

        if [[ ${_check['debug']} == 1 ]]; then
            if [[ $? == 0 ]]; then
                printf "[ $(colorize 'green' 'OK') ]\n";
            else
                printf "[ $(colorize 'red' 'Error') ]\n";
            fi
        fi
    fi

    ################
    # line separator
    ################
    echo
}


################################################################################
# check for prerequisites commands
################################################################################
function _cmd_check () {
    declare -a _cmds_;
    _cmds_=(curl perl pup jq grep printf echo);

    printf "check prerequisites:\n";
    for cmd in ${_cmds_[@]}; do
        temp_var=$(which  $cmd > /dev/null 2>&1);
        if [[ $? != 0 ]]; then
            printf "%-30s %s" "$cmd~" "~" | tr ' ~' '. ';
            printf "[ $(colorize 'red' 'ERROR') ] not found\n";
        else
            printf "%-30s %s" "$cmd~" "~" | tr ' ~' '. ';
            printf "[ $(colorize 'green' 'OK') ]\n";

        fi
    done
}


for arg in "${ARGS[@]}"; do
    mapfile -t _options_ < <(tr ' ' '\n' <<< "$arg");

    case ${_options_[0]} in
        -I | --ip )
            _ip['flag']=1;
            _ip['args']=${_options_[@]:1};
        ;;
        -L | --log)
            _log['flag']=1;
            _log['args']=${_options_[@]:1};
        ;;
        -C | --check )
            _check['flag']=1;
            _check['args']=${_options_[@]:1};
        ;;
        -h | --help )
            _help;
        ;;
        * )
            echo "unknown options: ${_options_[0]}";
        ;;
    esac
done


################################################################################
# set and check --log
################################################################################
if [[ ${_log['flag']} == 1 ]]; then
    args=();
    for arg in ${_log['args']}; do
        args+=($arg);
    done

    if [[ ${#args[@]} == 0 ]]; then
        _log_help;
        exit 0;
    fi

    for arg in ${args[@]}; do
        case $arg in
            html )
                _log['html']=1;
            ;;
            txt )
                _log['txt']=1;
            ;;
            term|terminal )
                _log['term']=1;
            ;;
            json )
                _log['json']=1;
            ;;
            * )
                echo "unknown option '$arg' for -L | --log";
            ;;
        esac
    done
fi

################################################################################
# set and check --check
################################################################################
if [[ ${_check['flag']} == 1 ]]; then
    args=();
    for arg in ${_check['args']}; do
        args+=($arg);
    done

    if [[ ${#args[@]} == 0 ]]; then
        _check_help;
        exit 0;
    fi

    for arg in ${args[@]}; do
        case $arg in
            cmd )
                _cmd_check;
            ;;
            debug )
                _check['debug']=1;
            ;;
            * )
                echo "unknown option '$arg' for -C | --check";
            ;;
        esac
    done
fi

################################################################################
# set and check --ip
################################################################################
if [[ ${_ip['flag']} == 1 ]]; then
    if [[ ${#_ip['args']} == 0 ]]; then
        _ip_help;
        exit 0;
    fi

    _cli_title;
    echo;

    args=();
    for arg in ${_ip['args']}; do
        args+=($arg);
    done

    # one argument and it is a file
    if [[ ${#args[@]} == 1 ]]; then
        if [[ -s ${args[0]} ]]; then
            mapfile -t args < "${args[0]}";
        fi
    fi

    # in either case (file|list) call get_bgp_route
    for arg in ${args[@]}; do
        get_bgp_route "$arg";
    done
fi

