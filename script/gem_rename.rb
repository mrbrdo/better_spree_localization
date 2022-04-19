def gsub_file(filename, find_replaces)
  text = File.read(filename)
  find_replaces.each do |(find, replace)|
    text = text.gsub(find, replace)
  end
  File.open(filename, "w") {|file| file.puts text }  
end

class String
  def camelize(uppercase_first_letter = true)
    string = self
    if uppercase_first_letter
      string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
    else
      string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
    end
    string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
  end
end

puts "New name:"
$old_name = 'gem_name'
$new_name = gets.strip

def process_folder(dir)
  Dir.glob(File.join(dir, '*')).each do |filename|
    next if File.basename(filename) == 'gem_rename.rb'
    if File.file?(filename)
      gsub_file(filename, [[$old_name, $new_name], [$old_name.camelize, $new_name.camelize]])
    end
    dir = File.dirname(filename)
    old_filename = File.basename(filename)
    new_filename = old_filename.gsub($old_name, $new_name)
    new_full_filename = File.join(dir, new_filename)
    unless new_filename == old_filename
      File.rename(File.join(dir, old_filename), new_full_filename)
    end
    if File.directory?(new_full_filename)
      process_folder(new_full_filename)
    end
  end
end

process_folder(File.expand_path('..', __dir__))
