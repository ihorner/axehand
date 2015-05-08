#!/usr/bin/ruby

textfile = ARGV[0]
movie = ARGV[1]

moviefull = movie.gsub("\ ", "\\\ ")
textfull = textfile.gsub("\ ", "\\\ ")

edl = []
moviename = File.basename(movie, ".mp4")
tempfiles = []
cuts = []

directory = File.dirname(movie)
directory2 = File.dirname(movie)
directory2["\ "]="\\\ "

# Load text files of timecodes and sort
File.readlines(textfile, encoding: 'UTF-8').sort_by(&:to_i).each do |f|
	edl << f.strip.split(/:/)
end

z = edl.length

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
system "/usr/local/bin/ffmpeg -i #{moviefull} -force_key_frames #{ffcutpoints} -c copy -map 0 \
 -f segment -segment_list #{directory2}/out.ffcat -segment_times #{ffcutpoints} -segment_time_delta 0.05 -bsf:v h264_mp4toannexb #{directory2}/#{moviename}.%03d.ts"

tempfiles.push("#{directory}/#{moviename}.000.ts")

# Add non-commercial segments to concatlist amd tempfiles array
edl.each_with_index { |val, index|
	indexx = index+1
	if edl[index][1] != "Commercial" and edl[index][1] != "Going Online" and edl[index][1] != "Going Offline" and index+1 < z
		File.open("#{directory}/concatlist.ffcat", 'a') { |f| 
			f.puts "file #{directory2}/#{moviename}.#{"%03d" % indexx}.ts"
		}
		tempfiles.push("#{directory}/#{moviename}.#{"%03d" % indexx}.ts")
	else
		tempfiles.push("#{directory}/#{moviename}.#{"%03d" % indexx}.ts")
	end
}

endtime = edl[z-1][0].to_f/10000000

# Stitch it all together
system "/usr/local/bin/ffmpeg -f concat -i #{directory2}/concatlist.ffcat -bsf:a aac_adtstoasc -c copy #{directory2}/#{moviename}.cut.mp4"

# Add concatlists to tempfiles array
tempfiles.push("#{directory}/concatlist.ffcat")
tempfiles.push("#{directory}/out.ffcat")

# Remove temp files
tempfiles.each { |x| 
File.delete(x)
}