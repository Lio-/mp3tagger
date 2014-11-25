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
TEST_RUN = false

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

def set_tag(file, title:nil, artist:nil, album:nil, image_path:nil)
  if(TEST_RUN)
    puts "#{file} ->"
    puts " " * 4 + "title: #{title}" unless title.nil?
    puts " " * 4 + "artist: #{artist}" unless artist.nil?
    puts " " * 4 + "album: #{album}" unless album.nil?
    return 
  end

  TagLib::MPEG::File.open(file) do |f|
    tag = f.id3v2_tag
    tag.title = title unless title.nil?
    tag.album = album unless album.nil?
    tag.artist = artist unless artist.nil?

    unless image_path.nil?
      apic = TagLib::ID3v2::AttachedPictureFrame.new
      apic.mime_type = "image/png"
      apic.description = "Cover"
      apic.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover
      apic.picture = File.open(path, 'rb') { |f| f.read }
      tag.add_frame(apic)
    end

    f.save
  end
end

def show_result(file, title, album)
    print ' ' * 4
    print "- #{file}\n"
    print ' ' * 8
    print "title: \"#{title}\", album: \"#{album}\"\n"
end

def set_tag_in_current_dir(artist:nil, album:nil, options: {})
  files = get_mp3_list
  files.each do |file|
    title = get_base_filename(file)
    title = title.gsub(/\d+[ \.]+/, '') if(options[:strip_number])

    show_result(file, title, album) unless (options[:silent]) 
    set_tag(file, title: title, artist: artist, album: album)
  end
end

#-- main
#

options = {}
OptionParser.new do |opts|
  opts.on("--strip-number", "strip the preceeding track number in the file name") do |strip|
    options[:strip_number] = strip 
  end
  opts.on("-d", "--directories=DIR1,DIR2,..", Array, "directories to scan") do |d|
    options[:directories] = d
  end
  opts.on("-s", "--silent", "show no commandline output") do |s|
    options[:silent] = s
  end
  opts.parse!(ARGV)
end

dirs = options[:directories].nil? ? `ls -d */ |grep -v test`.split("\n").map{|d| d[0..-2]} : options[:directories]
dirs.each do |artist_dir|
  puts "Processing #{artist_dir} 's songs'.."
  Dir.chdir(artist_dir){
    set_tag_in_current_dir(artist: artist_dir, options: options)

    Dir.glob('*/').each do |album_dir|
      puts "Processing album \"#{album_dir}\""
      Dir.chdir(album_dir){
        set_tag_in_current_dir(artist: artist_dir, album: album_dir, options: options)
      }
    end
  }
end
