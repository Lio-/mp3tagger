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
# ruby ./mp3tagger.rb
####


require 'taglib'
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

def set_tag_in_current_dir(artist:nil, album:nil)
  files = get_mp3_list
  files.each do |file|
    title = get_base_filename(file)
    set_tag(file, title: title, artist: artist, album: album)
  end
end

dirs = `ls -d */ |grep -v test`.split("\n").map{|d| d[0..-2]}
dirs.each do |artist_dir|
  puts "====cd-ing #{artist_dir}"
  Dir.chdir(artist_dir){
    set_tag_in_current_dir(artist: artist_dir)

    album_dirs = `ls -d */`.split("\n").map{|d| d[0..-2]}
    album_dirs.each do |album_dir|
      puts "====cd-ing #{album_dir}"
      Dir.chdir(album_dir){
        set_tag_in_current_dir(artist: artist_dir, album: album_dir)
      }
    end
  }
end