textfile = "2015-01-21_120323114.txt"
movie = "2015-01-21_120323114.mp4"

# Load text files of timecodes
edl = []

File.open(textfile) do |f|
	f.each_line do |line|
		edl << line.strip.split(/:/)
	end
end

moviename = movie[1..-5]
z = edl.length
tempfiles = []
cuts = []

# Make an array of the cutpoints
edl.each_with_index do |x, index|
	cuts << edl[index][0].to_f/10000000
end

ffcutpoints = cuts.join(',')

# Write out new keyframes at cut points and Cut the video into pieces, this is my last resort
system "ffmpeg -i #{movie} -force_key_frames #{ffcutpoints} -codec copy -map 0 \
 -f segment -segment_list out.ffcat -segment_times #{ffcutpoints} -segment_time_delta 0.05 #{moviename}.%03d.mp4"

# Add first segment to concatlist.ffcat and tempfiles array
		File.open("concatlist.ffcat", 'a') { |f| 
			f.puts "file #{moviename}.000.mp4"
		}
tempfiles.push("#{moviename}.000.mp4")

# Add non-commercial segments to concatlist amd tempfiles array
edl.each_with_index { |val, index|
	if
		edl[index][1] != "Commercial" and index+1 < z
		File.open("concatlist.ffcat", 'a') { |f| 
			f.puts "file #{moviename}.00#{index+1}.mp4"
		}
		tempfiles.push("#{moviename}.00#{index+1}.mp4")
	else
		tempfiles.push("#{moviename}.00#{index+1}.mp4")
	end
}

# Add last segment to concatlist
endtime = edl[z-1][0].to_f/10000000
File.open("concatlist.ffcat", 'a') { |f| 
			f.puts "file #{moviename}.00#{z}.mp4"
}
# tempfiles.push("#{moviename}.00#{z}.mp4")

# Stitch it all together
system "ffmpeg -f concat -i concatlist.ffcat -c copy #{moviename}.cut.mp4"


# Add concatlists to tempfiles array
tempfiles.push("concatlist.ffcat")
tempfiles.push("out.ffcat")

# Remove temp files
tempfiles.each { |x| 
File.delete(x)
}