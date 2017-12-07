# Secure Delete Thunar
This bash script uses xdialog and libnotify to gui-fy srm for use in thunar's
right click menu.

You can add this in thunar by editing actions in the menu. use the action as

PATH/TO/srm_guified.sh %F

Depedencies: libnotify, xdialog, secure-delete's srm, and bash

secure_delete.uca.xml can be merged into uca.xml providing the shortcut on
the right click/file menu. We do not have an automated proccess for this at
this time, but in the future.

Licensed under the GPLv3. see LICENSE for more info
