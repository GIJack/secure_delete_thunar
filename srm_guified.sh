#!/bin/bash
#
# Takes file names on the command line, gives and Xdialog confirm and status
# window to make more friendly to the GUI user.
#
#  licensed under the GPLv3 http://www.gnu.org/licenses/gpl-3.0.html

# see man srm. default is two pass 0xFF then random
SRM_OPTS="lr"

DEP_LIST="srm Xdialog notify-send"
CONFIRM="N"

exit_with_error(){
  echo 1>&2 "srm_guified.sh: ERROR: ${2}"
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
      exit_with_error 1 "$dep is not in \$PATH! This is needed to run. Quitting"
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
   1)
    # Dynamicly expand for size of filename
    win_length=$(( ${win_length} + ${#ALL_FILES} - 10 ))
    Xdialog --icon shred --title "Secure Delete" --yesno "Really Wipe ${ALL_FILES} File?" ${win_height} ${win_length}
    exit_code=${?}
    ;;
   *)
    Xdialog --icon shred --title "Secure Delete" --yesno "Really Wipe ${NUM_FILES} Files?" ${win_height} ${win_length}
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
    notify-send --icon shred "Secure Delete" "Finished Securely Deleting File(s)"
    ;;
   *)
    notify-send --icon shred "Secure Delete" "Security Wipe Failed! (${exit_code})"
    Xdialog --icon shred --title "Secure Delete" --msgbox "Security Wipe Failed! (${exit_code})" ${win_height} ${win_length}
    ;;
  esac
}

run_delete() {
  local -i win_length=45
  local -i win_height=8
  local -i exit_code=0
  local -i step=$(( 100/${NUM_FILES} ))
  local -i counter=0
  local fin_wait=0.5 #time in seconds to wait after finnishing
  # If there are no files, exit and error
  case ${NUM_FILES} in
   0)
    exit_with_error 4 "run_delete ran with 0 parameters, this should never happen (4)"
    ;;
   1)
    # Autoamticly adjust the window size for filename length so it doesn't look
    # trashy
    win_length=$(( ${win_length} + ${#ALL_FILES} - 10 ))
    # Yep, that is an anonymous function where numbers echoed change the Xdialog
    # value. gawd I love shell. NAWT!
    (
      # This switch is for one file, so we set Xdialog at %1 before, and %100
      # after it finnishes running.
      echo 1
      srm -${SRM_OPTS} "${ALL_FILES}"
      exit_code=${?}
      echo 100
      sleep ${fin_wait}
    ) |
    Xdialog --icon shred --title "Secure Delete" --gauge "Wiping ${ALL_FILES}" ${win_height} ${win_length}
    ;;
   *)
    (
      # This counts percent of total files being proccessed. files are erased
      # one at a time. Every line that writes a number to STDOUT runs the Xdialog
      # line at the end, incrementing the counter.
      for file in ${ALL_FILES};do
        echo ${counter}
        srm -${SRM_OPTS} "${file}"
        exit_code+=${?}
        [ $counter -ge 100 ] && continue # percent stops at 100, silly
        counter+=${step}
      done
      sleep ${fin_wait}
    ) |
    Xdialog --icon shred --title "Secure Delete" --gauge "Securely deleting ${NUM_FILES} files" ${win_height} ${win_length}
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
    exit_with_error 2 "User Canceled"
  fi
  # Then notify the user the result
  notify_complete ${exit_code}
  exit ${exit_code}
}
main "${@}"
