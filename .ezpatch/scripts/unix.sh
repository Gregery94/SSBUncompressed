#!/bin/bash
# unix.sh

get_prop() {
	grep "^${1}=" "$PROPERTIES" | cut -d'=' -f2
}

md5sum_file() {
    if [[ "${UNAME}" == "darwin" ]]; then
        md5 "$1" | awk '{print $NF}'
    else
        md5sum "$1" | awk '{print $1}'
    fi
}

notify() {
    if [[ "${UNAME}" == "darwin" ]]; then
        osascript -e "display dialog \"${1}\" with title \"${NOTIF_NAME}\" buttons {\"OK\"}"
    else
		# technically, support even command line linux users,
		# even though they probably do not need help patching :)
		if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
			if [[ -n "$(command -v zenity)" ]]; then
				zenity --info --title="${NOTIF_NAME}" --text="${1}"
			else
    			notify-send -u critical "${NOTIF_NAME}" "${1}"
			fi
		else
			if [[ -n "$(command -v tput)" ]]; then
				echo "$(tput bold)${NOTIF_NAME}: $(tput sgr0)${1}"
			else
				echo "${NOTIF_NAME}: ${1}"
			fi
		fi
    fi
}

UNAME="$(uname | awk '{print tolower($0)}')"
if [[ "$UNAME" == "darwin" ]]; then
    SELF_DIR="$(cd "$(dirname "$0")"; pwd -P)"
else
    SELF_DIR="$(dirname "$(readlink -f "$0")")"
fi

BASE_DIR="$(dirname "$(dirname "$SELF_DIR")")"
BIN_DIR="${BASE_DIR}/.ezpatch/bin/${UNAME}"
NOTIF_NAME="Easy Patch"
PATCH_DIR="${BASE_DIR}/patches"
PROPERTIES="${SELF_DIR}/patch.properties"
UCON64="${BIN_DIR}/ucon64"
XDELTA3="${BIN_DIR}/xdelta3"

if [[ $# -lt 1 ]]; then
	notify "Drag your ROM onto this program"
	exit 0
fi

FORMAT="$(get_prop 'format')"
MD5SUM="$(get_prop 'md5sum')"
OUTPUT_DIR="$(get_prop 'output')"
TMP_DIR="$(mktemp -d)"
TMP_ROM="${TMP_DIR}/input.rom"

for file in "$@"; do
	cp "$file" "$TMP_ROM"
	"$UCON64" "--${FORMAT}" "$TMP_ROM"

	input_md5sum="$(md5sum_file "$TMP_ROM")"
	if [[ "$input_md5sum" == "$MD5SUM" ]]; then
		OLD_IFS="$IFS"
		IFS=$'\n' patches=($(find "$PATCH_DIR" -type f -not -name ".*"))
		IFS="$OLD_IFS"

		for patch in "${patches[@]}"; do
			patch_name="$(basename "$patch")"
			output_rom="${BASE_DIR}/${OUTPUT_DIR}/${patch_name%.*}.${FORMAT}"
			"$XDELTA3" -d -f -s "$TMP_ROM" "$patch" "$output_rom"

			if [[ $? -eq 0 ]]; then
				notify "Successfully created $(basename "$output_rom") in $(dirname "$output_rom")"
			else
				notify "There was an error creating $(basename "$output_rom")"
			fi
		done
	else
		notify "Your ROM does not match the developer's original ROM"
	fi
done

rm -rf "$TMP_DIR"
exit 0
