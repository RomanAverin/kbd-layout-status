#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/scripts/helpers.sh"

kbd_layout_placeholder="#{kbd_layout}"
kbd_layout_script="$CURRENT_DIR/scripts/kbd-layout.sh"
format_option="@kbd-layout-format"

build_command() {
	local format
	format=$(get_tmux_option "$format_option" "")

	if [[ -n "$format" ]]; then
		# Replace #{value} placeholder in format with the script call
		echo "${format//\#\{value\}/#($kbd_layout_script)}"
	else
		echo "#($kbd_layout_script)"
	fi
}

update_option() {
	local option="$1"
	local option_value
	option_value=$(get_tmux_option "$option" "")

	if [[ "$option_value" == *"$kbd_layout_placeholder"* ]]; then
		local command
		command=$(build_command)
		local new_value="${option_value//$kbd_layout_placeholder/$command}"
		set_tmux_option "$option" "$new_value"
	fi
}

main() {
	update_option "status-right"
	update_option "status-left"
}

main
