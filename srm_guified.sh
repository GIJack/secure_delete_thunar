#!/bin/bash
#
# Takes file names on the command line, gives and Xdialog confirm and status
# window to make more friendly to the GUI user.
#
#  licensed under the GPLv3 http://www.gnu.org/licenses/gpl-3.0.html

# Exit codes 0-success 2-script_failure 4-user_failure Anything else:
# srm failure

# the default is to use srm from THC's secure-delete, using two passes random,
# with sync and /dev/urandom.
SRM_PROG="srm"
SRM_OPTS="lr"

DEP_LIST="srm Xdialog notify-send"
CONFIRM="N"

exit_with_error(){
  local -i win_length=45
  local -i win_height=8
  echo 1>&2 "srm_guified.sh: ERROR: ${2}"
  notify-send --icon shred "Secure Delete" "${2} (${1})"
  Xdialog --icon shred --title "Secure Delete" --msgbox "${2} (${1})" ${win_height} ${win_length}
  exit ${1}
}

exit_with_error_soft(){
  echo 1>&2 "srm_guified.sh: ERROR: ${2}"
  notify-send --icon shred "Secure Delete" "${2} (${1})"
  exit ${1}
}

message(){
  echo "srm_guified.sh: ${@}"
}

check_deps(){
  # This function checks dependencies. looks for executable binaries in path
  for dep in ${DEP_LIST};do
    which ${dep} &> /dev/null
    if [ $? -ne 0 ];then
      exit_with_error 2 "$dep is not in \$PATH! This is needed to run. Quitting"
    fi
  done
}

confirm_delete() {
  # Ask user confirmation before irrecovably wiping files. Probably most
  # important, if not sole reason for this script.
  local -i win_length=45
  local -i win_height=8
  local -i exit_code=0
  case ${NUM_FILES} in
   0)
     exit_with_error 2 "No Files to Delete, exiting"
     ;;
   *)
    Xdialog --icon shred --title "Secure Delete" --yesno "Really Wipe ${NUM_FILES} File(s)?" ${win_height} ${win_length}
    exit_code=${?}
    ;;
  esac
  case ${exit_code} in
   0)
    CONFIRM="Y"
    ;;
   *)
    CONFIRM="N"
    ;;
  esac
}

notify_complete() {
  # libnotify end results
  local -i win_length=45
  local -i win_height=8
  local -i exit_code=${1}
  case ${exit_code} in
   0)
    notify-send --icon shred "Secure Delete" "Finished Securely Deleting ${NUM_FILES} File(s)"
    exit 0
    ;;
   *)
    exit_with_error ${exit_code} "Secure Wipe Failed!"
    ;;
  esac
}

run_delete() {
  local -i win_length=45
  local -i win_height=8
  local -i exit_code=0
  local -i step=$(( 100000 / ${NUM_FILES} )) # Per 100,000. Convert later
  local -i counter=0
  local fin_wait=0.5 #time in seconds to wait after finnishing
  # If there are no files, exit and error
  case ${NUM_FILES} in
   0)
    exit_with_error 4 "run_delete ran with 0 parameters, this should never happen (4)"
    ;;
   *)
    (
      # This counts percent of total files being proccessed. files are erased
      # one at a time. Every line that writes a number to STDOUT runs the Xdialog
      # line at the end, incrementing the counter.
      for file in ${ALL_FILES};do
        echo $(( ${counter} / 1000 )) # convert back to percent
        ${SRM_PROG} -${SRM_OPTS} "${file}"
        exit_code+=${?}
        [ $counter -ge 100000 ] && continue # percent stops at 100, silly
        counter+=${step}
      done
      sleep ${fin_wait}
    ) |
    Xdialog --icon shred --title "Secure Delete" --gauge "Wiping ${NUM_FILES} file(s)" ${win_height} ${win_length}
    [ $? -eq 255 ] && exit_with_error 4 "Secure Wipe Aborted"
    ;;
  esac
  return ${exit_code}
}

main() {
  local -i exit_code=0
  declare -i NUM_FILES=$#
  declare ALL_FILES="${@}"
  confirm_delete
  # do the wipe
  if [ ${CONFIRM} == "Y" ];then
    run_delete
    exit_code=${?}
   else
    exit_with_error_soft 4 "User Canceled"
  fi
  # Then notify the user the result
  notify_complete ${exit_code}
}
main "${@}"
