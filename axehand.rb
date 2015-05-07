#!/usr/bin/ruby


textfile = ARGV[0]
movie = ARGV[1]

# textfile = "2015-01-21_120323114.txt"
# movie = "2015-01-21_120323114.ts"

edl = []
moviename = movie[0..-5]
tempfiles = []
cuts = []

# Load text files of timecodes and sort
File.readlines(textfile).sort_by(&:to_i).each do |f|
	edl << f.strip.split(/:/)
end

z = edl.length

# cuts.push (5)

# edl[0][0] = edl[0][0].to_i-50000000

# Add 5s Buffer to OP, Commercial and ED
edl.each_with_index { |val, index|
	if edl[index][1] == "Commercial" or edl[index][1] == "Going Online" or edl[index][1] == "Going Offline" and index+1 < z
		edl[index][0] = edl[index][0].to_i+50000000
	elsif edl[index][1] == "Going Online" or edl[index][1] == "Going Offline"
		edl[index][0] = edl[index][0].to_i+50000000
	end
}

# Make an array of the cutpoints
edl.each_with_index do |x, index|
	cuts << edl[index][0].to_f/10000000
end

ffcutpoints = cuts.join(',')


# Write out new keyframes at cut points and Cut the video into pieces, this is my last resort
system "ffmpeg -i #{movie} -force_key_frames #{ffcutpoints} -c copy -map 0 \
 -f segment -segment_list out.ffcat -segment_times #{ffcutpoints} -segment_time_delta 0.05 -bsf:v h264_mp4toannexb #{moviename}.%03d.ts"

# Remove first segment to concatlist.ffcat and tempfiles array
		# File.open("concatlist.ffcat", 'a') { |f| 
		# 	f.puts "file #{moviename}.000.ts"
		# }

tempfiles.push("#{moviename}.000.ts")

# Add non-commercial segments to concatlist amd tempfiles array
edl.each_with_index { |val, index|
	indexx = index+1
	if edl[index][1] != "Commercial" and edl[index][1] != "Going Online" and edl[index][1] != "Going Offline" and index+1 < z
		File.open("concatlist.ffcat", 'a') { |f| 
			f.puts "file #{moviename}.#{"%03d" % indexx}.ts"
		}
		tempfiles.push("#{moviename}.#{"%03d" % indexx}.ts")
	else
		tempfiles.push("#{moviename}.#{"%03d" % indexx}.ts")
	end
}

endtime = edl[z-1][0].to_f/10000000

# Add last segment to concatlist
# if edl[z][1] = "Going Offline"
# 	tempfiles.push("#{moviename}.#{"%03d" % z}.ts")
# else
# 	File.open("concatlist.ffcat", 'a') { |f| 
# 			f.puts "file #{moviename}.#{"%03d" % z}.ts"
# }
# tempfiles.push("#{moviename}.#{"%03d" % z}.ts")
# end

# Stitch it all together
system "ffmpeg -f concat -i concatlist.ffcat -bsf:a aac_adtstoasc -c copy #{moviename}.cut.mp4"

# Add concatlists to tempfiles array
tempfiles.push("concatlist.ffcat")
tempfiles.push("out.ffcat")

Remove temp files
tempfiles.each { |x| 
File.delete(x)
}