#!/bin/bash -eu
#
# Description
#   Convert plantuml to mermaid
#   Now, only support sequential-diagram
#
# Usage:
#   bash main.sh <MARKDOWN_FILE_NAME>


OUTPUT_PATH="output.md"
# ======================
# parse markdown file
# ======================
START_CODE_BLOCK='```'
START_UML='plantuml'
START_MERMAID='mermaid'
NEW_LINE='<br />'

is_in_uml=false
indent="    "
indent_level=0

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
    # detect the start of plantuml
    if [[ "$line" =~ ^"$START_CODE_BLOCK"([ ]?)("$START_UML"|"$START_MERMAID") ]]; then
        type=${BASH_REMATCH[2]}
        if [[ "$type" == "$START_UML" ]]; then
            is_in_uml=true
            # write uml start
            echo "$START_CODE_BLOCK $START_MERMAID" >> "$OUTPUT_PATH"
        fi
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

    if [[ "$line" == "@startuml" ]]; then
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
        one_line="${BASH_REMATCH[1]} ->> ${BASH_REMATCH[2]} : ${BASH_REMATCH[4]}"
        write_with_indent "$one_line"
        right_paticipant="${BASH_REMATCH[2]}"
        continue
    elif [[ "$line" =~ ([^>]*)" <"-+" "([^>]*) ]]; then
        one_line="${BASH_REMATCH[1]} ->> ${BASH_REMATCH[2]}"
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

    write_with_indent "$line"
done < "$1"
