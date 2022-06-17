# Bash library

log()  { echo "==> $*" 1>&2; }
info() { log "$(bold_green "INFO: "   ) $(bold "$*")"; } 
warn() { log "$(bold_red   "WARNING: ") $(bold "$*")"; }
err()  { log "$(bold_red   "ERROR: "  ) $(bold "$*")"; return 1; }
die()  { log "$(bold_red   "FATAL: "  ) $(bold "$*")"; exit 1; }

styled_text() { ATTR="$1"; shift; echo -en '\033['"${ATTR}m$*"'\033[0m'; }

bold()       { styled_text "1"    "$*"; }
blue()       { styled_text "94"   "$*"; }
bold_blue()  { styled_text "1;94" "$*"; }
red()        { styled_text "91"   "$*"; }
bold_red()   { styled_text "1;91" "$*"; }
bold_green() { styled_text "1;92" "$*"; }

log_bold() { log "$(bold_blue "$*")"; }
