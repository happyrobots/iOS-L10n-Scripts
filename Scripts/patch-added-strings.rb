require './Scripts/osx_strings_file_parser'

def to_utf8(src, dest)
	`iconv -f UTF-16LE -t UTF-8 #{src} > #{dest}`
end

def to_utf16(src, dest)
	`( printf "\xff\xfe" ; iconv -f UTF-8 -t UTF-16LE #{src} ) > #{dest}`
end

new_file_path, old_file_path = ARGV[0..1] # UTF-16LE

# Temporary file for UTF-8
new_file_path_utf8, old_file_path_utf8 = new_file_path + "_utf8", old_file_path + "_utf8"
to_utf8(new_file_path, new_file_path_utf8)
to_utf8(old_file_path, old_file_path_utf8)

new_content = OsxStringsFileParser.parse(File.read new_file_path_utf8)
old_content = OsxStringsFileParser.parse(File.read old_file_path_utf8)

new_keys = new_content.keys - old_content.keys
if new_keys.empty?
	puts <<-EOL
  Patching>> Identical string keys in
    #{new_file_path} and
    #{old_file_path}
    Not doing anything.

EOL
else
	$stderr.puts "  Patching>> [WARNING] Translation on #{old_file_path} is incomplete!"
	puts "  Patching>> Adding new strings from #{new_file_path} to #{old_file_path}"
	File.open(old_file_path_utf8, 'a') do |f|
		new_keys.each do |key|
			value = new_content[key]
			next unless value
			f << <<-EOL

#{value[:comment]}
"#{key}" = "#{value[:value]}";
EOL
		end
	end
	to_utf16 new_file_path_utf8, new_file_path
	to_utf16 old_file_path_utf8, old_file_path
	puts "  Patching>> New strings are added to #{old_file_path}. Please provide translations ASAP."
end

# Remove UTF-8 temporary file
`rm -f #{new_file_path_utf8} #{old_file_path_utf8}`
