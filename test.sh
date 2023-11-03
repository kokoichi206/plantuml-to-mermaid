#!/bin/bash
#
# Description
#   test of main.sh for the files in samples directory.
#
# Usage:
#   bash test.sh
set -euo pipefail

## sequential-diagram
bash main.sh -o samples/sequence_diagram/output.md samples/sequence_diagram/plant_uml.md
diff samples/sequence_diagram/mermaid.md samples/sequence_diagram/output.md
