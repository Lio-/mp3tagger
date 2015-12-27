# <Usage>
#
#|- mp3tagger.rb
#|
#|-Artist1
#|  |
#|  |- Album1
#|  |  |- music1.mp3
#|  .  .
#|
#|-Artist2
#|  |
#|  |- Album1
#|  .  |- music1.mp3
#|  .  |- music2.mp3
#|     .
#
####
# ruby ./mp3tagger.rb <artist directory 1> <artist directory 2> ...
####


require 'taglib'
require 'optparse'

def escape(data)
  data.gsub(/'/, '\'"\'"\'')
end

def get_mp3_list()
  `ls *.mp3`.split("\n")
end

def get_dir_list()
  `ls -d */ |grep -v test`.split("\n").map{|d| d[0..-2]}
end

def get_base_filename(filename)
  filename =~ /(.*)\.mp3/
  raise "illegal file name #{filename}" if $1.nil?
  return $1
end

# option: {title:, artist:, album:, comment:, image_path:}
def set_tag(file, options)
  #puts "#{file} ->"
  #puts " " * 4 + "title: #{options[:title]}" unless options[:title].nil?
  #puts " " * 4 + "artist: #{options[:artist]}" unless options[:artist].nil?
  #puts " " * 4 + "comment is cleared" unless options[:clear_comment]
  #puts " " * 4 + "album: #{options[:album]}" unless options[:album].nil?

  return if(options[:test_run])

  TagLib::MPEG::File.open(file) do |f|
    tag = f.id3v2_tag
    tag.title = options[:title] unless options[:title].nil?
    binding.pry
    tag.album = options[:album] unless options[:album].nil?
    tag.artist = options[:artist] unless options[:artist].nil?
    tag.comment = nil if options[:clear_comment]

    unless options[:image_path].nil?
      apic = TagLib::ID3v2::AttachedPictureFrame.new
      apic.mime_type = "image/png"
      apic.description = "Cover"
      apic.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover
      apic.picture = File.open(options[:image_path], 'rb') { |f| f.read }
      tag.add_frame(apic)
    end

    f.save
  end
end

def show_result(file, options)
    puts ' ' * 4 + "- #{file}"
    puts ' ' * 8 + "title: \"#{options[:title]}\"" unless options[:skip_title]
    puts ' ' * 8 + "album: \"#{options[:album]}\"" unless options[:skip_album]
    puts ' ' * 8 + "artist: \"#{options[:artist]}\"" unless options[:skip_artist]
    puts " " * 8 + "comment is cleared" if options[:clear_comment]
end

def set_tag_in_current_dir(artist:nil, album:nil, options: {})
  files = get_mp3_list
  files.each do |file|
    title = get_base_filename(file)
    title = title.gsub(/\d+[ \.]+/, '') if(options[:strip_number])


    # compose options roughly
    tag_options = {
      title: options[:skip_title] ? nil : title,
      artist: options[:skip_artist] ? nil : artist,
      album: options[:skip_album] ? nil : album,
    }.merge(options)

    show_result(file, tag_options) unless (options[:silent])

    set_tag(file, tag_options)
  end
end

#-- main
#

require 'pry-byebug'

options = {}
OptionParser.new do |opts|
  opts.on("--strip-number", "strip the preceeding track number in the file name") do |o|
    options[:strip_number] = o
  end
  opts.on("-d", "--directories=DIR1,DIR2,..", Array, "directories to scan") do |o|
    options[:directories] = o
  end
  opts.on("--silent", "show no commandline output") do |o|
    options[:silent] = o
  end
  opts.on("-c", "--clear-comment", "clear comments on all files") do |o|
    options[:clear_comment] = o
  end
  opts.on("-t", "--test-run", "shows output but don't actually change tag info") do |o|
    options[:test_run] = o
  end
  opts.on("--skip-title", "don't change title") do |o|
    options[:skip_title] = o
  end
  opts.on("--skip-album", "don't change album") do |o|
    options[:skip_album] = o
  end
  opts.on("--skip-artist", "don't change artist") do |o|
    options[:skip_artist] = o
  end
  opts.parse!(ARGV)
end

if(options[:test_run])
  puts '=' * 20
  puts 'THIS IS A TEST RUN'
  puts '=' * 20
end

dirs = options[:directories].nil? ? `ls -d */ |grep -v test`.split("\n").map{|d| d[0..-2]} : options[:directories]
dirs.each do |artist_dir|
  puts "Processing songs at [#{artist_dir}] .."
  Dir.chdir(artist_dir){
    artist_name = artist_dir.split("/")[-1]
    set_tag_in_current_dir(artist: artist_name, options: options)

    Dir.glob('*/').each do |album_dir|
      puts "Processing album \"#{album_dir}\""
      Dir.chdir(album_dir){
        album_name = album_dir[0..-2]
        set_tag_in_current_dir(artist: artist_name, album: album_name, options: options)
      }
    end
  }
end

