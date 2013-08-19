#!/bin/sh

# the language you design in
SRC_LOCALE="en"

# the translations you provide
TARGET_LOCALES="id"

# Parent folder of the locales (parent folder of en.lproj, id.lproj, etc.)
SRC_LOCALE_PARENT_DIRS="L10nExample"

# Parent path of localized Localizable.strings
LOCALIZABLE_LOCALE_PARENT_PATH="L10nExample"

# ------------------------------
# Helpers
# ------------------------------

function localize_file
{
	local src_file_path=$1
	local base_path=$2
	local target_locales=$3

	local file_ext="${src_file_path##*.}"
	local strings_ext="strings"
	local extless_file_path="${src_file_path%.*}"
	local file_name=`basename $extless_file_path`

	echo "Updating "$src_locale" strings file for $src_file_path"
	ibtool --generate-strings-file "$extless_file_path.strings" "$src_file_path"

	# Generate localized interfaces
	for locale in $(echo $target_locales); do
		local target_strings_file="$file_name.$strings_ext"
		local target_file="$file_name.$file_ext"
		local target_locale_path=$base_path/$locale.lproj

		local target_strings_file_path=$target_locale_path/$target_strings_file
		local target_file_path=$target_locale_path/$target_file

	    echo -n "Generating "$locale" interface"
	    if [ -d "$target_locale_path" ]; then
	        if [ -f "$target_strings_file_path" ]; then
	            ibtool --strings-file "$target_strings_file_path" --write "$target_file_path" "$src_file_path"
	        else
	            echo "Not found: *.strings file $target_strings_file in locale dir $target_locale_path"
	            echo "  creating en strings for $locale translation at $target_locale_path"
	            cp $extless_file_path.strings $target_locale_path
	        fi
	        echo "<OK>"
	    else
	        echo "[ERROR] Locale dir $target_locale_path not found>"
	        echo "  Have you activated the localization from XCode?"
	    fi
	done
}

function localize_files_in_dir
{
	local src_locale_parent_path=$1
	local src_locale=$2
	local src_locale_path="$src_locale_parent_path/$src_locale.lproj"
	local target_locales=$3

	if [ -d "$src_locale_path" ]; then
	  # Apparently there are .xib files in Code/Controllers too...
	  # So, we search for both!
	  local exts="*.storyboard *.xib"

	  for ext in $(echo $exts); do
	  	echo "Searching for files in $src_locale_path with extension $ext..."
	    local found_file_paths=`find $src_locale_path -name "$ext" -print`

	    for file_path in $found_file_paths; do
	      localize_file "$file_path" "$src_locale_parent_path" "$target_locales"
	    done
	  done
	fi
}

# ------------------------------
# Runnable
# ------------------------------

function generate_interfaces_for_target_locales
{
	for src_locale_parent_dir in $(echo $SRC_LOCALE_PARENT_DIRS); do
		localize_files_in_dir "$src_locale_parent_dir" "$SRC_LOCALE" "$TARGET_LOCALES"
		echo
	done
}

function update_strings_for_target_locales
{
	echo "Updating strings in"
	echo $SRC_LOCALE_PARENT_DIRS
	echo "for target locales $TARGET_LOCALES by copying $SRC_LOCALE locale"
	echo "---"

	for src_locale_parent_dir in $(echo $SRC_LOCALE_PARENT_DIRS); do
		echo "Finding strings for $SRC_LOCALE locale"
		local base_locale_path="$src_locale_parent_dir/$SRC_LOCALE.lproj"
		if [ ! -d "$base_locale_path" ]; then
			echo "Not found: $base_locale_path"
			echo "  Not creating strings for $src_locale_parent_dir"
			echo
		    continue
		fi
		local found_string_paths=`find $base_locale_path -name "*.strings" -print`

		for locale in $(echo $TARGET_LOCALES); do
			local src_locale_path="$src_locale_parent_dir/$locale.lproj"
			if [ ! -d "$src_locale_path" ]; then
				echo "Not found: $src_locale_path"
				echo "  Not creating strings file for that locale"
			    continue
			fi
			echo "Copying new strings for $locale locale based on $SRC_LOCALE locale"
			for string_path in $(echo $found_string_paths); do
				local target_string_file_path="$src_locale_path/`basename $string_path`"
				if [ -f $target_string_file_path ]; then
					echo "Exists: $target_string_file_path"
					echo "  Trying to patch new strings into the file"
					ruby Scripts/patch-added-strings.rb "$string_path" "$target_string_file_path"
				else
					cp $string_path $src_locale_path/
				fi
		    done
	    done
	    echo
	    echo "="
	    echo
    done

    echo "Updating $LOCALIZABLE_LOCALE_PARENT_PATH/Localizable.strings"
	echo "for target locales $TARGET_LOCALES via genstrings"
	echo "---"
	for target_locale in $(echo $TARGET_LOCALES); do
		local localizable_path="$LOCALIZABLE_LOCALE_PARENT_PATH/$target_locale.lproj"
		local new_localizable_parent_path=$localizable_path/new
		local new_localizable_path=$new_localizable_parent_path/Localizable.strings
		local actual_localizable_path=$localizable_path/Localizable.strings
		mkdir -p $new_localizable_parent_path
		echo "Generating new strings for $target_locale at"
		echo "  $new_localizable_parent_path"
		find . -name \*.m | xargs genstrings -o $new_localizable_parent_path

		if [ -f "$actual_localizable_path" ]; then
			echo "Exists: Localizable.strings for $target_locale"
			echo "  Trying to patch new strings into the file"
			ruby Scripts/patch-added-strings.rb "$new_localizable_path" "$actual_localizable_path"
		else
			cp "$new_localizable_path" "$actual_localizable_path"
		fi
		rm -fr "$new_localizable_parent_path"
	    echo "="
	    echo
	done
}
