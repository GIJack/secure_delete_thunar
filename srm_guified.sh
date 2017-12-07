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
  #This function checks dependencies. looks for executable binaries in path
  for dep in ${DEP_LIST};do
    which ${dep} &> /dev/null
    if [ $? -ne 0 ];then
      exit_with_error 1 "$dep is not in \$PATH! This is needed to run. Quitting"
    fi
  done
}

confirm_delete() {
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
    Xdialog --icon edit-delete --title "Secure Delete" --yesno "Really Secure Delete ${ALL_FILES} File?" ${win_height} ${win_length}
    exit_code=${?}
    ;;
   *)
    Xdialog --icon edit-delete --title "Secure Delete" --yesno "Really Secure Delete ${NUM_FILES} Files?" ${win_height} ${win_length}
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
  local -i exit_code=${1}
  case ${exit_code} in
   0)
    notify-send --icon edit-delete "Secure-Delete" "Finished Securely Deleting File(s)"
    ;;
   *)
    notify-send --icon edit-delete "Secure-Delete" "Security Wipe Failed ${exit_code}"
    ;;
  esac
}

run_delete() {
  local -i win_length=45
  local -i win_height=8
  local -i exit_code
  local -i step=$(( 100/${NUM_FILES} ))
  local -i counter
  #notify-send --icon edit-delete "Secure Delete" "Securely Deleting File(s)"
  case ${NUM_FILES} in
   0)
    exit_with_error 4 "run_delete ran with 0 parameters, this should never happen (2)"
    ;;
   1)
    win_length=$(( ${win_length} + ${#ALL_FILES} - 10 ))
    (
      echo 1
      srm -${SRM_OPTS} "${ALL_FILES}"
      exit_code=${?}
      echo 100
      sleep 0.5
    ) |
    Xdialog --icon edit-delete --title "Secure Delete" --gauge "Securely deleting ${ALL_FILES}" ${win_height} ${win_length}
    ;;
   *)
    counter=0
    (
      for file in "${ALL_FILES}";do
        echo ${counter}
        srm -${SRM_OPTS} "${file}"
        exit_code+=${?}
        [ $counter -ge 100 ] && continue
        counter+=${step}
      done
    ) |
    Xdialog --icon edit-delete --title "Secure Delete" --gauge "Securely deleting ${NUM_FILES} files" ${win_height} ${win_length} 0
    ;;
  esac
  #srm -${SRM_OPTS} "${ALL_FILES}"
  #exit_code=${?}
  return ${exit_code}
}

main() {
  local -i exit_code=0
  declare -i NUM_FILES=$#
  declare ALL_FILES="${@}"
  confirm_delete
  #do the wipe
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
