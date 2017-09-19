 $agg = {}
 at_exit do
   line_column_size = $agg.keys.max_by(&:size).size
   time_column_size = $agg.values.max_by { |v| v[:time].to_s.size }[:time].to_s.size

   puts "| line#{' ' * (line_column_size - 4)} | num_calls | time (s)#{' ' * (time_column_size - 8)} |"
   puts "| #{'-' * line_column_size} | --------- | #{'-' * time_column_size} |"
   $agg.each do |k, v|
     line_entry = k.tr('|', '')
     line_entry << ' ' * (line_column_size - line_entry.size)

     num_calls = v[:num_calls].to_s
     num_calls << ' ' * (9 - num_calls.size)

     time = v[:time].to_s
     time << ' ' * (time_column_size - time.size)

     puts "| #{line_entry} | #{num_calls} | #{time} |"
   end
 end

 # Aggregate the time it takes to run a block of code.
 # Returns the value of the block.
 # At exit, it will output the aggregated time.
 def _ta(label)
   $agg[label] ||= { time: 0, num_calls: 0 }
   t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
   ret = yield
 ensure
   $agg[label][:time] += (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t)
   $agg[label][:num_calls] += 1
   ret
 end

