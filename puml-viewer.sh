#!/bin/bash
#
# puml-viewer
#
# A smart viewer script that visualizes PlantUML (.puml) files and graph
# descriptions from JSON stream files (.json), such as those produced by
# a Model-Context-Protocol (MCP) memory store: https://github.com/modelcontextprotocol/servers
#
# If given a .puml file, it generates a PNG and opens it.
# If given a .json file, it first converts it to .puml format and then proceeds.
#


#
# --- Installation for Nautilus Integration ---
#
# 1. Move puml-viewer.sh to ~/.local/bin/.
# 2. Move puml-viewer.desktop to ~/.local/share/applications/.
# 3. Make the script executable with `chmod +x ~/.local/bin/puml-viewer.sh`.
# 4. Update the desktop database with `update-desktop-database ~/.local/share/applications/`.
#

#ver. 1.3, fixes for JSON Lines and gsub regex

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 path/to/file.{json,puml}" >&2
  exit 1
fi

INPUT="$1"
EXT="${INPUT##*.}"
BASE="${INPUT%.*}"

json_to_puml() {
  local jsonfile="$1"
  local pumlfile="$2"

  if ! command -v jq >/dev/null; then
    echo "Error: jq is required for JSON processing but not installed." >&2
    exit 1
  fi

  {
    echo "@startuml"
    # Fix: Use -s (slurp) to read JSON Lines into an array, then filter for entities.
    jq -r -s '
      map(select(.type == "entity"))[] | "object \"" + .name + "\" as " + 
      ( .name | gsub("[^a-zA-Z0-9_]";"") )
    ' "$jsonfile"

    # Fix: Use -s (slurp) to read JSON Lines into an array, then filter for relations.
    # Fix: Corrected typo in gsub regex for .to field (was [^a-a-zA-Z0-9_] -> now [^a-zA-Z0-9_]).
    jq -r -s '
      map(select(.type == "relation"))[] | 
      (.from | gsub("[^a-zA-Z0-9_]";"")) + " --> " + 
      (.to | gsub("[^a-zA-Z0-9_]";"")) + " : " + (.relationType // "relates")
    ' "$jsonfile"

    echo "@enduml"
  } > "$pumlfile"
}

puml_business() {
  local puml_file="$1"
  
  #TODO: add the theme here somehow, see https://plantuml.com/theme
  plantuml "$puml_file"

  local png_file="${puml_file%.puml}.png"
  if [ -f "$png_file" ]; then
    xdg-open "$png_file" >/dev/null 2>&1 || echo "Warning: could not open $png_file"
  else
    echo "Error: PNG output file not found." >&2
    exit 1
  fi
}

# Determine PUML input for puml_business:
if [[ "$EXT" == "json" ]]; then
  PUML_FILE="${BASE}.puml"
  json_to_puml "$INPUT" "$PUML_FILE"
else
  PUML_FILE="$INPUT"
fi

puml_business "$PUML_FILE"

