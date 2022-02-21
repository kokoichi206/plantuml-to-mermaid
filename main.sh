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
line_count=0
is_in_uml=false
START_CODE_BLOCK='```'
START_UML='plantuml'
START_MERMAID='mermaid'
function init_file() {
    echo -n "" > "$OUTPUT_PATH"
}
init_file

while read line
do
    # detect the start of plantuml
    if [[ "$line" =~ ^"$START_CODE_BLOCK"([ ]?)("$START_UML"|"$START_MERMAID") ]]; then
        type=${BASH_REMATCH[2]}
        echo $type
        echo $START_UML
        if [[ "$type" == "$START_UML" ]]; then
            is_in_uml=true
            # write uml start
            echo "$START_CODE_BLOCK $START_MERMAID" >> "$OUTPUT_PATH"
        fi
        continue
    fi
    # detect the end of plantuml
    if [[ "$line" =~ ^"$START_CODE_BLOCK"([ ]*)$ ]]; then
        is_in_uml=false
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
    echo $line
done < $1

