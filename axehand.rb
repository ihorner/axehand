#!/usr/bin/ruby

ARGV.each do | movie |
  begin
    textfile = movie + '.txt'
    moviefull = movie.gsub("\ ", "\\\ ")
    edl = []
    moviename = File.basename(movie, '.mp4')
    tempfiles = []
    cuts = []
    directory = File.dirname(movie)
    directory2 = File.dirname(movie).gsub("\ ", "\\\ ")

    # Load text files of timecodes and sort
    File.readlines(textfile, encoding: 'UTF-8').sort_by(&:to_i).each do |f|
      edl << f.strip.split(/:/)
    end

    z = edl.length

    # Add 5s Buffer to OP, Commercial and ED
    edl.each_with_index do |_, index|
      if edl[index][1] == 'Commercial' || edl[index][1] == 'Going Online' || edl[index][1] == 'Going Offline' && index + 1 < z
        edl[index][0] = edl[index][0].to_i + 50_000_000
      elsif edl[index][1] == 'Going Online' || edl[index][1] == 'Going Offline'
        edl[index][0] = edl[index][0].to_i + 50_000_000
      end
    end

    # Make an array of the cutpoints
    edl.each_with_index do |_, index|
      cuts << edl[index][0].to_f / 10_000_000
    end

    ffcutpoints = cuts.join(',')

    # Write out new keyframes at cut points and Cut the video into pieces, this is my last resort
    system "/usr/local/bin/ffmpeg -i #{moviefull} -force_key_frames #{ffcutpoints} -c copy -map 0 \
 -f segment -segment_list #{directory2}/#{moviename}.out.ffcat -segment_times #{ffcutpoints} -segment_time_delta 0.05 -bsf:v h264_mp4toannexb #{directory2}/#{moviename}.%03d.ts"

    tempfiles.push("#{directory}/#{moviename}.000.ts")

    # Add non-commercial segments to concatlist amd tempfiles array
    edl.each_with_index do |_, index|
      indexx = index + 1
      if edl[index][1] != 'Commercial' && edl[index][1] != 'Going Online' && edl[index][1] != 'Going Offline' && index + 1 < z
        File.open("#{directory}/#{moviename}.concatlist.ffcat", 'a') do |f|
          f.puts "file #{directory2}/#{moviename}.#{'%03d' % indexx}.ts"
        end
        tempfiles.push("#{directory}/#{moviename}.#{'%03d' % indexx}.ts")
      else
        tempfiles.push("#{directory}/#{moviename}.#{'%03d' % indexx}.ts")
      end
    end

    # Stitch it all together
    system "/usr/local/bin/ffmpeg -f concat -i #{directory2}/#{moviename}.concatlist.ffcat -bsf:a aac_adtstoasc -c copy #{directory2}/#{moviename}.cut.mp4"

    # Add concatlists to tempfiles array
    tempfiles.push("#{directory}/#{moviename}.concatlist.ffcat")
    tempfiles.push("#{directory}/#{moviename}.out.ffcat")

    # Remove temp files
    tempfiles.each do |x|
      File.delete(x)
    end
  end
end
