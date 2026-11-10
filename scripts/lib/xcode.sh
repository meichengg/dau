#!/bin/zsh
# Picks the Xcode the scripts build with (sourced, not run): one rule for every script.
# Side effects: none
#
#   dau_developer_dir   export DEVELOPER_DIR, the first of:
#                         1. $DEVELOPER_DIR, when the caller set it;
#                         2. `xcode-select -p`, when that folder has usr/bin/xcodebuild
#                            (it may point at the Command Line Tools, which have no
#                            xcodebuild and cannot build the apps);
#                         3. /Applications/Xcode.app/Contents/Developer, when it exists;
#                       otherwise print what to do and exit 1.
#
# Needs scripts/lib/log.sh sourced first.

dau_developer_dir() {
  if [[ -n ${DEVELOPER_DIR-} ]]; then
    export DEVELOPER_DIR
    return 0
  fi
  local selected
  selected=$(xcode-select -p 2>/dev/null)
  if [[ -n $selected && -x $selected/usr/bin/xcodebuild ]]; then
    export DEVELOPER_DIR=$selected
    return 0
  fi
  if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    return 0
  fi
  log_error "Không tìm thấy Xcode (xcode-select -p: ${selected:-không có}; không có /Applications/Xcode.app)."
  log_hint "Cài Xcode, hoặc đặt DEVELOPER_DIR=<Xcode.app>/Contents/Developer trước lệnh."
  exit 1
}
