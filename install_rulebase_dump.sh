#!/bin/bash
set -euo pipefail
LOG_DIR="/var/log/rulebase_dump"
STAMP_FILE="${LOG_DIR}/.installed"
UMASK_OLD="$(umask)"; umask 077
log(){ printf "[%s] %s\n" "$(date +'%F %T')" "$*" | tee -a "${LOG_DIR}/setup.log"; }
init(){ mkdir -p "${LOG_DIR}"; touch "${LOG_DIR}/setup.log"; }
run_installer(){
  local last_xml="$CPDIR/database/downloads/ONLINE_SERVICES/1.0/last_revision.xml"
  if [[ ! -f "$last_xml" ]]; then log "ERROR: $last_xml not found"; return 1; fi
  local UO_REVISION; UO_REVISION="$(grep -oP '(?<=<Last_Revision>)[0-9]+' "$last_xml" || true)"
  [[ -z "$UO_REVISION" ]] && { log "ERROR: cannot parse Last_Revision"; return 1; }
  local sk_dir="$CPDIR/database/downloads/ONLINE_SERVICES/1.0/$UO_REVISION/static_files/rulebase_dump"
  local sk_script="$sk_dir/rulebase_dump.sh"
  [[ ! -f "$sk_script" ]] && log "INFO: $sk_script not present yet; proceeding anyway"
  bash -c 'UO_REVISION=$(grep -oP '"'"'(?<=<Last_Revision>)[0-9]+'"'"' "$CPDIR/database/downloads/ONLINE_SERVICES/1.0/last_revision.xml") ; \
           chmod +x $CPDIR/database/downloads/ONLINE_SERVICES/1.0/$UO_REVISION/static_files/rulebase_dump/rulebase_dump.sh || true ; \
           $CPDIR/database/downloads/ONLINE_SERVICES/1.0/$UO_REVISION/static_files/rulebase_dump/rulebase_dump.sh install' \
    >> "${LOG_DIR}/setup.log" 2>&1
}
main(){
  init; log "Starting installer wrapper (FORCE=${FORCE-0})"
  if [[ -f "$STAMP_FILE" && "${FORCE-0}" != "1" ]]; then log "Already installed; set FORCE=1 to reinstall"; log "Done (no-op)"; return 0; fi
  if run_installer; then touch "$STAMP_FILE"; log "Installer finished OK; stamp created"; else log "ERROR: installer failed"; return 1; fi
}
trap 'rc=$?; [[ $rc -ne 0 ]] && log "Aborted rc=$rc"; umask "$UMASK_OLD"; exit $rc' EXIT
main