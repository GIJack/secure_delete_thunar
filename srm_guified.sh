#!/usr/bin/env bash
#
# Takes file names on the command line, gives and Xdialog confirm and status
# window to make more friendly to the GUI user.
#
#  licensed under the GPLv3 http://www.gnu.org/licenses/gpl-3.0.html

# Exit codes 0-success 1-srm_failure 2-script_failure 4-user_failure

# the default is to use GNU shred from coreutils, using two passes random,

## THC(Van Hausen)'s Secure Delete
#SRM_PROG="srm"
#SRM_OPTS="-lr"

## GNU Shred from coreutils
SRM_PROG=shred
SRM_OPTS="--remove=wipesync -f -n2"

DEP_LIST="find shred Xdialog notify-send"
CONFIRM="N"
ICON="shred"

exit_with_error(){
  local -i win_length=45
  local -i win_height=8
  echo 1>&2 "srm_guified.sh: ERROR: ${2}"
  notify-send --icon ${ICON} "Secure Delete: ERROR!" "${2} (${1})"
  Xdialog --icon ${ICON} --title "Secure Delete" --msgbox "${2} (${1})" ${win_height} ${win_length}
  exit ${1}
}

exit_with_error_soft(){
  echo 1>&2 "srm_guified.sh: ERROR: ${2}"
  notify-send --icon ${ICON} "Secure Delete: ERROR!" "${2} (${1})"
  exit ${1}
}

warn_notify(){
  echo 1>&2 "srm_guified.sh: Warn: ${@}"
  notify-send --icon ${ICON} "Secure Delete: Warning!" "${@}"
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
    Xdialog --icon ${ICON} --title "Secure Delete" --yesno "Really Wipe ${NUM_FILES} File(s)?" ${win_height} ${win_length}
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
  local -i complete_files=$((${NUM_FILES} - ${FILE_FAILS}))
  case ${FILE_FAILS} in
   0)
    notify-send --icon ${ICON} "Secure Delete" "Finished Securely Deleting ${NUM_FILES} File(s)"
    exit 0
    ;;
   *)
    notify-send --icon ${ICON} "Secure Delete" "Finished Securely Deleted ${complete_files} File(s). Unable to delete ${FILE_FAILS} file(s)"
    exit 1
    ;;
  esac
}

delete_files() {
  local -i win_length=45
  local -i win_height=8
  local -i exit_code=0
  local -i step=$(( 100000 / ${NUM_FILES} )) # Per 100,000. Convert later
  local -i counter=0
  local fin_wait=0.5 #time in seconds to wait after finnishing
  # If there are no files, exit and error
  case ${NUM_FILES} in
   0)
    exit_with_error 4 "delete_files() ran with 0 parameters, this should never happen (4)"
    ;;
   *)
    (
      # This counts percent of total files being proccessed. files are erased
      # one at a time. Every line that writes a number to STDOUT runs the Xdialog
      # line at the end, incrementing the counter.
      for file in "${SHRED_FILES[@]}";do
        echo $(( ${counter} / 1000 )) # convert back to percent
        file=${file%%[[:space:]]}
        ${SRM_PROG} ${SRM_OPTS} "${file}"
        if [ ${?} -ne 0 ];then
          warn_notify "Could Not Delete ${file}!"
          FILE_FAILS+=1  
        fi
        [ $counter -ge 100000 ] && continue # percent stops at 100
        counter+=${step}
      done
      sleep ${fin_wait}
    ) |
    Xdialog --icon ${ICON} --title "Secure Delete" --gauge "Wiping ${NUM_FILES} file(s)" ${win_height} ${win_length}
    [ $? -eq 255 ] && exit_with_error 4 "Secure Wipe Aborted"
    ;;
  esac
  return ${exit_code}
}

delete_dirs(){
  #remove empty directories after all the files have been wiped
  local cmd_line=""
  for dir in "${SHRED_DIRS[@]}";do
    dir=${dir%%[[:space:]]}
    cmd_line+="${dir} "
    rmdir -p "${dir}"
  done
}

main() {
  declare IN_FILES=("${@}")
  declare -a SHRED_FILES
  declare -a SHRED_DIRS
  declare -i NUM_FILES=0
  declare -i FILE_FAILS=0
  declare -i DIR_FAILS=0

  local -a file_array
  for file in "${IN_FILES[@]}";do
    readarray file_array <<< $(find "${file}" -type f )
    SHRED_FILES+=("${file_array[@]}")
    readarray file_array <<< $(find "${file}" -type d )
    SHRED_DIRS+=("${file_array[@]}")
  done
  NUM_FILES=${#SHRED_FILES[@]}
  [ -z ${IN_FILES} ] && exit_with_error 4 "Nothing Specified, nothing to do!"

  confirm_delete
  # do the wipe
  if [ ${CONFIRM} == "Y" ];then
    delete_files
    delete_dirs
   else
    exit_with_error_soft 4 "User Canceled"
  fi
  # Then notify the user the result
  notify_complete
}
main "${@}"
