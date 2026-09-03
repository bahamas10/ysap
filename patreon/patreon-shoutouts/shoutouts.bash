#!/usr/bin/env bash

##################
# CONFIGURATIONS #
##################
NAME_DESIRED_WIDTH=25

# Yes if a patreon decides to use that in their name it'll replace it.
# Patreon display names sanetization is dumb and we need to manage
# the CSV strings with commas
COMMA_ESCAPE_STRING='ESCAPEDCOMMA'
# Header + Footer + last line + line separations + sections headers
NUM_RESERVE_LINES=$(( 3+5+1+3+3 ))

CURSOR_CHARACTER='_'

COLOUR_RESET=$'\x1b[0m' # White
COLOUR_DIM=$'\x1b[2m' # Dimmed
COLOUR_PATREON=$'\x1b[38;2;249;104;84m' # Patreaon orange
COLOUR_YSAP=$'\x1b[38;5;223m' # YSAP Yellow
COLOUR_ENV=$'\x1b[38;5;162m'
COLOUR_BASH=$'\x1b[38;5;167m'
COLOUR_SH=$'\x1b[38;5;179m'

# generated via https://patorjk.com/software/taag
# font: Future
IFS= read -d '' -r INTRO <<-EOF
┏━┓┏━┓╺┳╸┏━┓┏━╸┏━┓┏┓╻   ┏━┓╻ ╻┏━┓┏━┓┏━┓┏━┓╺┳╸┏━╸┏━┓┏━┓
┣━┛┣━┫ ┃ ┣┳┛┣╸ ┃ ┃┃┗┫   ┗━┓┃ ┃┣━┛┣━┛┃ ┃┣┳┛ ┃ ┣╸ ┣┳┛┗━┓
╹  ╹ ╹ ╹ ╹┗╸┗━╸┗━┛╹ ╹   ┗━┛┗━┛╹  ╹  ┗━┛╹┗╸ ╹ ┗━╸╹┗╸┗━┛
EOF

IFS= read -d '' -r THANKS <<-EOF
╺┳╸╻ ╻┏━┓┏┓╻╻┏ ┏━┓   ┏━╸┏━┓┏━┓   ╻ ╻┏━┓╺┳╸┏━╸╻ ╻╻┏┓╻┏━╸
 ┃ ┣━┫┣━┫┃┗┫┣┻┓┗━┓   ┣╸ ┃ ┃┣┳┛   ┃╻┃┣━┫ ┃ ┃  ┣━┫┃┃┗┫┃╺┓
 ╹ ╹ ╹╹ ╹╹ ╹╹ ╹┗━┛   ╹  ┗━┛╹┗╸   ┗┻┛╹ ╹ ╹ ┗━╸╹ ╹╹╹ ╹┗━┛
EOF

######################
# END CONFIGURATIONS #
######################
 
shopt -s checkwinsize; (:) # Set globals with terminal sizes
AVAILABLE_SPACE=$(( $LINES-$NUM_RESERVE_LINES )) # Availaible lines minus the reserved lines
ENV_SUPPORTERS_START=4 # Start after the intro
ENV_SUPPORTERS_SPACE=$(( $AVAILABLE_SPACE/2 )) # Default max ENV supporters space is half of the total
DISPLAYED_NAME_COLUMNS=$(( $COLUMNS/(NAME_DESIRED_WIDTH+1) )) # Calculate the number of columns
NAME_MAX_WIDTH=$(( $COLUMNS/DISPLAYED_NAME_COLUMNS )) # Set the true max size of the column
CURSOR_MAX_COLUMNS=$((($NAME_MAX_WIDTH*$DISPLAYED_NAME_COLUMNS)+$DISPLAYED_NAME_COLUMNS-1)) # Calculate the end of the printed line

deinit-term() {
	printf '\e[?1049l' # disable alternate buffer
	printf '\e[?25h' # show the cursor
}

init-term() {
	printf '\e[?1049h' # enable alternate buffer
	printf '\e[?25l' # hide the cursor
	printf '\e[H' # move the cursor home
}

sanitize_comma() {
    local str_comma_finder='^.*(".*,.*").*$'
    local line=$1
    if [[ $line =~ $str_comma_finder ]]; then
        local var1=${BASH_REMATCH[1]//,/$COMMA_ESCAPE_STRING}
        echo ${line//${BASH_REMATCH[1]}/${var1:1:-1}}
    else
        echo $1
    fi
}

# Right padding accounting for Unicode characters
# Usage: rpad padding "text"
rpad() {
    printf "%s%*s" "$2" "$(($1-${#2}))" ""
}

parsecsv() {
    local -a columns
    local n=${#data[@]}
    #n=3
    for ((i = 0; i < n; i++)); do

        local csvline=$(sanitize_comma ${data[i]})
        # Putting unused columns in underscore to reduce line lenght
        mapfile -d ',' -t columns <<< "$csvline"
        # Unescape the commas
        local comma_name=${columns[0]//$COMMA_ESCAPE_STRING/,}
        # Limit the name to the max name width
        local name=${comma_name:0:$NAME_MAX_WIDTH}
        local tier=${columns[10]}
        local numNullSupporters=0

        if [[ $tier == "/usr/bin/env bash" ]]; then
            (( numSupporters++ ))
            (( numEnvSupporters++ ))
            B_ENV+=$(rpad $NAME_MAX_WIDTH "$name")
            if (( $(($numEnvSupporters % $DISPLAYED_NAME_COLUMNS)) > 0 )); then
                B_ENV+=" "
            fi
        elif [[ $tier == "/bin/bash" ]]; then
            (( numSupporters++ ))
            (( numBashSupporters++ ))
            B_BASH+=$(rpad $NAME_MAX_WIDTH "$name")
            if (( $(($numBashSupporters % $DISPLAYED_NAME_COLUMNS)) > 0 )); then
                B_BASH+=" "
            fi
        elif [[ $tier == "/bin/sh" ]]; then
            (( numSupporters++ ))
            (( numShSupporters++ ))
            B_SH+=$(rpad $NAME_MAX_WIDTH "$name")
            if (( $(($numShSupporters % $DISPLAYED_NAME_COLUMNS)) > 0 )); then
                B_SH+=" "
            fi
        elif [[ $tier == "Free" ]]; then
            (( numNullSupporters++ ))
            B_NULL+=$(rpad $NAME_MAX_WIDTH "$name")
            if (( $(($numNullSupporters % $DISPLAYED_NAME_COLUMNS)) > 0 )); then
                B_NULL+=" "
            fi
        fi  
    done
    if (( $(($numEnvSupporters % $DISPLAYED_NAME_COLUMNS)) > 0 )); then
        local missingCols=$(($DISPLAYED_NAME_COLUMNS-($numEnvSupporters % $DISPLAYED_NAME_COLUMNS)))
        B_ENV+=$(printf "%*s" $(($missingCols*$NAME_MAX_WIDTH)) "")
        local missingSpaces=$(($missingCols-1))
        if (( $missingSpaces > 0 )); then
            B_ENV+=$(printf "%*s" $missingSpaces "")
        fi
    fi
    if (( $(($numBashSupporters % $DISPLAYED_NAME_COLUMNS)) > 0 )); then
        local missingCols=$(($DISPLAYED_NAME_COLUMNS-($numBashSupporters % $DISPLAYED_NAME_COLUMNS)))
        B_BASH+=$(printf "%*s" $(($missingCols*$NAME_MAX_WIDTH)) "")
        local missingSpaces=$(($missingCols-1))
        if (( $missingSpaces > 0 )); then
            B_BASH+=$(printf "%*s" $missingSpaces "")
        fi
    fi
    if (( $(($numShSupporters % $DISPLAYED_NAME_COLUMNS)) > 0 )); then
        local missingCols=$(($DISPLAYED_NAME_COLUMNS-($numShSupporters % $DISPLAYED_NAME_COLUMNS)))
        B_SH+=$(printf "%*s" $(($missingCols*$NAME_MAX_WIDTH)) "")
        local missingSpaces=$(($missingCols-1))
        if (( $missingSpaces > 0 )); then
            B_SH+=$(printf "%*s" $missingSpaces "")
        fi
    fi
    if (( $(($numNullSupporters % $DISPLAYED_NAME_COLUMNS)) > 0 )); then
        local missingCols=$(($DISPLAYED_NAME_COLUMNS-($numNullSupporters % $DISPLAYED_NAME_COLUMNS)))
        B_NULL+=$(printf "%*s" $(($missingCols*$NAME_MAX_WIDTH)) "")
        local missingSpaces=$(($missingCols-1))
        if (( $missingSpaces > 0 )); then
            B_NULL+=$(printf "%*s" $missingSpaces "")
        fi
    fi
}

printBuff() {
    # Name the parameters
    local buff=$1
    local currPosition=$2
    local start=$3
    local space=$4
    local end=$(($start+$space))
    local looping=$5

    local bufSize=${#buff}
    # Keep the position inside the limits of the buffer and loop
    local bufPosition=$(( $currPosition % ${bufSize}))
    # Calculate the line to print on
    local posLine=$((($currPosition/$CURSOR_MAX_COLUMNS)+$start+1))
    # Calculate the column to print on
    local posCol=$((($currPosition % $CURSOR_MAX_COLUMNS)+1))
    
    if (( $looping == 0 && $posLine > $(($end)) ));then
        # If it's not looping and is fully printed, skip
        return 0
    elif (( $looping == 1 && $posLine > $(($end)) )); then
        # If we've used the full space, start looping
        local targetLine=$posLine
        posLine=$end
        if (( $posCol == 1 )); then
            # if we're back at the first column, move the text one line up
            local loopBack=0
            local startPosition=$(((($targetLine-$posLine)*$CURSOR_MAX_COLUMNS)%$bufSize))
            local length=$((($space-1)*$CURSOR_MAX_COLUMNS))
            local extraPosition
            if (( $(($startPosition+$length)) > $bufSize )); then
                # if we're at the end of the text buffer print use the rest and prepare to print the start
                loopBack=1
                extraPosition=$(($startPosition+$length-$bufSize))
                length=$(($length-$extraPosition))
            fi
            printf "\e[$(($start+1))H"
            printf "${buff:$startPosition:$length}"
            if (( $loopBack == 1 )); then
                # If we need to print the start of the buffer
                printf "${buff:0:$extraPosition}"
            fi
            # Clear the new line
            printf "%*s" $CURSOR_MAX_COLUMNS ""
        fi
    fi
    
    # Print the next character
    printf "\e[${posLine};${posCol}H"
    printf "${buff:$bufPosition:1}"

    if (( $posLine != $(($end)) || $posCol != $CURSOR_MAX_COLUMNS )); then
        # Print the fake cursor if it's not on the last line or not in the last column
        echo -n "${CURSOR_CHARACTER}"
    fi
}

printEnvs() {
    printBuff "$B_ENV" $envPosition $ENV_SUPPORTERS_START $ENV_SUPPORTERS_SPACE $envLooping
    (( envPosition++ ))
}
printBashs() {
    printBuff "$B_BASH" $bashPosition $BASH_SUPPORTERS_START $BASH_SUPPORTERS_SPACE $bashLooping
    (( bashPosition++ ))
}
printShs() {
    printBuff "$B_SH" $shPosition $SH_SUPPORTERS_START $SH_SUPPORTERS_SPACE $shLooping
    (( shPosition++ ))
}

# If the printed sections is longer than the available section set to loop,
# otherwise set it's available space to it's size and calculate the next sections
setSpacing() {
    if (( $(($numEnvSupporters/$DISPLAYED_NAME_COLUMNS)) < $ENV_SUPPORTERS_SPACE )); then
        # If theres more space than supporters, reduce the space and don't loop
        ENV_SUPPORTERS_SPACE=$(($numEnvSupporters/$DISPLAYED_NAME_COLUMNS))
        if (( $(($numEnvSupporters%$DISPLAYED_NAME_COLUMNS)) > 0 )); then
            # If the last line is full add an extra space
            (( ENV_SUPPORTERS_SPACE++ ))
        fi
        envLooping=0
    fi
    BASH_SUPPORTERS_START=$(( $ENV_SUPPORTERS_START + $ENV_SUPPORTERS_SPACE + 2 ))
    BASH_SUPPORTERS_SPACE=$(( ($AVAILABLE_SPACE-$ENV_SUPPORTERS_SPACE)/3*2 ))
    if (( $(($numBashSupporters/$DISPLAYED_NAME_COLUMNS)) < $BASH_SUPPORTERS_SPACE )); then
        # If theres more space than supporters, reduce the space and don't loop
        BASH_SUPPORTERS_SPACE=$(($numBashSupporters/$DISPLAYED_NAME_COLUMNS))
        if (( $(($numBashSupporters%$DISPLAYED_NAME_COLUMNS)) > 0 )); then
            # If the last line is full add an extra space
            (( BASH_SUPPORTERS_SPACE++ ))
        fi
        bashLooping=0
    fi
    SH_SUPPORTERS_SPACE=$(($AVAILABLE_SPACE-$ENV_SUPPORTERS_SPACE-$BASH_SUPPORTERS_SPACE))
    SH_SUPPORTERS_START=$(( $BASH_SUPPORTERS_START + $BASH_SUPPORTERS_SPACE + 2 ))
    if (( $(($numShSupporters/$DISPLAYED_NAME_COLUMNS)) < $SH_SUPPORTERS_SPACE )); then
        # If theres more space than supporters, reduce the space and don't loop
        SH_SUPPORTERS_SPACE=$(($numShSupporters/$DISPLAYED_NAME_COLUMNS))
        if (( $(($numShSupporters%$DISPLAYED_NAME_COLUMNS)) > 0 )); then
            # If the last line is full add an extra space
            (( SH_SUPPORTERS_SPACE++ ))
        fi
        shLooping=0
    fi
}

printHeader() {
    printf "\e[0H"
    printf "${COLOUR_PATREON}${INTRO}${COLOUR_RESET}"
}

printSectionsHeaders() {
    printf "\e[4H"
    printf "${COLOUR_ENV}/usr/bin/env bash${COLOUR_RESET} ${COLOUR_DIM}(${numEnvSupporters} members)${COLOUR_RESET}"
    printf "\e[${BASH_SUPPORTERS_START}H"
    echo "${COLOUR_BASH}/bin/bash${COLOUR_RESET} ${COLOUR_DIM}(${numBashSupporters} members)${COLOUR_RESET}"
    printf "\e[${SH_SUPPORTERS_START}H"
    echo "${COLOUR_SH}/bin/sh${COLOUR_RESET} ${COLOUR_DIM}(${numShSupporters} members)${COLOUR_RESET}"
}

printFooter() {
    printf "\e[$(($SH_SUPPORTERS_START+$SH_SUPPORTERS_SPACE+2))H"
    printf "${COLOUR_DIM}Total: $numSupporters active members${COLOUR_RESET}\n"
    echo "${COLOUR_DIM}Patreon:${COLOUR_RESET} https:ysap.sh/patreon"
    printf "${COLOUR_YSAP}${THANKS}${COLOUR_RESET}"
}

main() {
    trap deinit-term EXIT
    init-term

    local -a data
    mapfile -s 1 -t data

    local numSupporters=0
    local numEnvSupporters=0
    local numBashSupporters=0
    local numShSupporters=0
    local B_ENV
    local B_BASH
    local B_SH
    local B_NULL

    parsecsv

    clear

    local envPosition=0 # Position in the buffer
    local bashPosition=0 # Position in the buffer
    local shPosition=0 # Position in the buffer
    local envLooping=1 # Loop the buffer
    local bashLooping=1 # Loop the buffer
    local shLooping=1 # Loop the buffer

    setSpacing

    printHeader
    printFooter
    printSectionsHeaders

    while true; do
        printEnvs
        printBashs
        printShs
        sleep 0.01
    done
}

IFS= main "$@"
