#!/bin/bash -eu
#
# Description
#   Convert plantuml to mermaid
#   Now, only support sequential-diagram
#
# Usage:
#   bash main.sh <MARKDOWN_FILE_NAME>

PROGRAM=$(basename "$0")
OUTPUT_PATH="output.md"

# ===== print usage =====
function print_usage() {
    echo "Usage: $PROGRAM [OPTION] FILE"
    echo "  -h, --help, -help"
    echo "      print manual"
    echo "  -o <filename>, --output <filename>"
    echo "      output filename"
}
usage_and_exit()
{
    print_usage
    exit "$1"
}

# ======================
# parse arguments (options)
# ======================
while (( "$#" )); do
    i="$1"
    case $i in
    -h | --help | -help)
        usage_and_exit 0
        ;;
    -o | --output)
        if [[ -z "$2" ]]; then
            echo "option requires a file name -- $1"
            usage_and_exit 1
        fi
        OUTPUT_PATH="$2"
        shift 2
        ;;
    -*)
        echo "Unknown option $1"
        usage_and_exit 1
        ;;
    *)
        if [[ -n "$1" ]] && [[ -f "$1" ]]; then
            FILE="$1"
            shift 1
        fi
        ;;
    esac
done

# ======================
# parse markdown file
# ======================
START_CODE_BLOCK='```'
START_UML='plantuml'
START_MERMAID='mermaid'
NEW_LINE='<br />'

found=false
is_in_uml=false
indent="    "
indent_level=0
line_number=0

first_paticipant=""
last_paticipant=""
right_paticipant=""

function init_file() {
    echo -n "" > "$OUTPUT_PATH"
}
init_file

function make_indent() {
    for ((i=0; i < "$indent_level"; i++)); do
        echo -n "$indent" >> "$OUTPUT_PATH"
    done
}
function write_with_indent() {
    make_indent
    echo "$1" >> "$OUTPUT_PATH"
}

while read -r line
do
    line_number="$((line_number+1))"

    # detect the start of plantuml
    if [[ "$line" =~ ^"$START_CODE_BLOCK"([ ]?)("$START_UML"|"$START_MERMAID") ]]; then
        type=${BASH_REMATCH[2]}
        if [[ "$type" == "$START_UML" ]]; then
            is_in_uml=true
            # write uml start
            echo "$START_CODE_BLOCK $START_MERMAID" >> "$OUTPUT_PATH"
        fi
        found=true
        continue
    fi
    # detect the end of plantuml
    if [[ "$line" =~ ^"$START_CODE_BLOCK"([ ]*)$ ]]; then
        if "$is_in_uml"; then
            echo "$START_CODE_BLOCK" >> "$OUTPUT_PATH"
        fi
        is_in_uml=false
        continue
    fi
    # if not in uml, return
    if ! "$is_in_uml"; then
        continue
    fi

    if [[ "$line" == "@startuml"* ]]; then
        echo "%%{init: {'theme': 'forest' } }%%" >> "$OUTPUT_PATH"
        echo "sequenceDiagram" >> "$OUTPUT_PATH"
        indent_level=1
        continue
    fi
    if [[ "$line" == "@enduml" ]]; then
        continue
    fi

    # user: actor X -> actor X
    if [[ "$line" =~ ^"actor "(.*) ]]; then
        one_line="actor ${BASH_REMATCH[1]}"
        write_with_indent "$one_line"
        if [[ "$first_paticipant" == "" ]]; then
            first_paticipant="${BASH_REMATCH[1]}"
        fi
        last_paticipant="${BASH_REMATCH[1]}"
        right_paticipant="${BASH_REMATCH[1]}"
        continue
    fi

    # partincipant
    if [[ "$line" =~ "participant "(.*)" "(.*) ]]; then
        one_line="participant ${BASH_REMATCH[1]} as ${BASH_REMATCH[2]}${NEW_LINE}${BASH_REMATCH[1]}"
        write_with_indent "$one_line"
        if [[ "$first_paticipant" == "" ]]; then
            first_paticipant="${BASH_REMATCH[1]}"
        fi
        last_paticipant="${BASH_REMATCH[1]}"
        right_paticipant="${BASH_REMATCH[1]}"
        continue
    fi

    # divider: ==メニュー表示== -> note over a,b X
    if [[ "$line" =~ "="=+(.+)"="=+ ]]; then
        one_line="note over ${first_paticipant},${last_paticipant}: ${BASH_REMATCH[1]}"
        write_with_indent "$one_line"
        continue
    fi

    # alt, opt conditions
    if [[ "$line" =~ ([ ]*)(alt|opt) ]]; then
        write_with_indent "$line"
        indent_level=$((indent_level+1))
        continue
    elif [[ "$line" =~ ([ ]*)(else) ]]; then
        indent_level=$((indent_level-1))
        write_with_indent "$line"
        indent_level=$((indent_level+1))
        continue
    elif [[ "$line" =~ ([ ]*)(end) ]]; then
        indent_level=$((indent_level-1))
        write_with_indent "$line"
        continue
    fi

    # X -> Y, X --> Y ==> X ->> Y
    if [[ "$line" =~ ([^>]*)" "-+"> "([^>]*)([ ]*:[ ]*)(.*) ]]; then
        one_line="${BASH_REMATCH[1]} ->> ${BASH_REMATCH[2]} : ${BASH_REMATCH[4]}"
        write_with_indent "$one_line"
        right_paticipant="${BASH_REMATCH[2]}"
        continue
    elif [[ "$line" =~ ([^>]*)" "-+"> "([^>]*) ]]; then
        one_line="${BASH_REMATCH[1]} ->> ${BASH_REMATCH[2]}"
        write_with_indent "$one_line"
        right_paticipant="${BASH_REMATCH[2]}"
        continue
    fi

    # X <- Y, X <-- Y ==> X ->> Y
    if [[ "$line" =~ ([^>]*)" <"-+" "([^>]*)([ ]*:[ ]*)(.*) ]]; then
        one_line="${BASH_REMATCH[2]} ->> ${BASH_REMATCH[1]} : ${BASH_REMATCH[4]}"
        write_with_indent "$one_line"
        right_paticipant="${BASH_REMATCH[2]}"
        continue
    elif [[ "$line" =~ ([^>]*)" <"-+" "([^>]*) ]]; then
        one_line="${BASH_REMATCH[2]} ->> ${BASH_REMATCH[1]}"
        write_with_indent "$one_line"
        right_paticipant="${BASH_REMATCH[2]}"
        continue
    fi

    # note right: foo -> note right of X: foo
    if [[ "$line" =~ "note right"([ ])*":"([ ])*(.*) ]]; then
        one_line="note right of ${right_paticipant}: ${BASH_REMATCH[3]}"
        write_with_indent "$one_line"
        continue
    fi

    if [ -n "$line" ] && "$is_in_uml"; then
        echo "$FILE: line $line_number: unknown line"
        exit 1
    else
        echo "" >> "$OUTPUT_PATH"
    fi
done < "$FILE"

if ! "$found"; then
    echo "No plantuml code found."
    echo "The plantuml code must be surrounded by \"\`\`\`plantuml\" and \"\`\`\`\"."
fi
