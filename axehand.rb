#!/usr/bin/ruby
#testings

movie = ARGV[0]
textfile = ARGV[1]

# textfile = "2015-01-21_120323114.txt"
# movie = "2015-01-21_120323114.mp4"

# Load text files of timecodes
edl = []

edlsort = File.readlines(textfile).sort_by(&:to_i)
File.open(textfile, "w") do |file|
	file.puts edlsort
end

File.open(textfile) do |f|
		f.each_line do |line|
		edl << line.strip.split(/:/)
	end
end

moviename = movie[1..-5]
z = edl.length
tempfiles = []
cuts = []

# cuts.push (5)

# Make an array of the cutpoints
edl.each_with_index do |x, index|
	cuts << edl[index][0].to_f/10000000
end

ffcutpoints = cuts.join(',')

# Write out new keyframes at cut points and Cut the video into pieces, this is my last resort
# system "ffmpeg -i #{movie} -force_key_frames #{ffcutpoints} -codec copy -map 0 \
#  -f segment -segment_list out.ffcat -segment_times #{ffcutpoints} -segment_time_delta 0.05 #{moviename}.%03d.mp4"

# Add first segment to concatlist.ffcat and tempfiles array
		File.open("concatlist.ffcat", 'a') { |f| 
			f.puts "file #{moviename}.000.mp4"
		}
tempfiles.push("#{moviename}.000.mp4")

# Add non-commercial segments to concatlist amd tempfiles array
edl.each_with_index { |val, index|
	indexx = index+1
	if
		edl[index][1] != "Commercial" and edl[index][1] != "Going Online" and edl[index][1] != "Going Offline" and index+1 < z
		File.open("concatlist.ffcat", 'a') { |f| 
			f.puts "file #{moviename}.#{"%03d" % indexx}.mp4"
		}
		tempfiles.push("#{moviename}.#{"%03d" % indexx}.mp4")
	else
		tempfiles.push("#{moviename}.#{"%03d" % indexx}.mp4")
	end
}

# Add last segment to concatlist
endtime = edl[z-1][0].to_f/10000000
File.open("concatlist.ffcat", 'a') { |f| 
			f.puts "file #{moviename}.#{"%03d" % z}.mp4"
}
tempfiles.push("#{moviename}.#{"%03d" % z}.mp4")

# Stitch it all together
# system "ffmpeg -f concat -i concatlist.ffcat -c copy #{moviename}.cut.mp4"

# Add concatlists to tempfiles array
tempfiles.push("concatlist.ffcat")
tempfiles.push("out.ffcat")

# Remove temp files
# tempfiles.each { |x| 
# File.delete(x)
# }