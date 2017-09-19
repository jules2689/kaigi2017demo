require 'chart_helpers'
require 'date'

# We use a global aggregate cache to allow us to track methods within a loop all at once
$timed = {}

at_exit do
  $timed.each do |method_name, timed_hash|
    output = []

    # Output mermaid syntax for gantt
    title_file = timed_hash[:path].dup
    title_file.gsub!(ENV.fetch('GEM_HOME', 'GEM_HOME'), '')
    title_file.gsub!(ENV.fetch('HOME', 'USER'), '')
    output << "gantt"
    output << "   title file: #{title_file} method: #{method_name}"

    curr_percent = 0.000

    # Aggregate the lines together. Loops can cause things to become unweildly otherwise
    @grouped_lines = timed_hash[:entries].group_by do |line|
      [line[:line], line[:line_no]]
    end

    # Calculate total time for all groups
    total_group_time = ->(group) do
      gantt_chart_time = 0.000024 * group.size # 0.000024 is an approximation
      time = group.collect { |e| e[:time] }.inject(:+) - gantt_chart_time
      time < 0.001 ? 0.001 : time
    end
    total_time = @grouped_lines.collect { |_, group| total_group_time.call(group) }.inject(:+)

    @grouped_lines.each do |(group_name, _line_no), group|
      # If we have run more than once, we should indicate how many times something is called
      entry_name = group.size > 1 ? "#{group_name} (run #{group.size} times)" : group_name
      entry_name = entry_name.tr('"', "'").tr(",", ' ') # Mermaid has trouble with these

      # Total time for all entries to run
      time = total_group_time.call(group)
      percent = (time / total_time * 100)

      # Output the line
      post_percent = percent + curr_percent
      output << format("   \"%s\" :a1, %.3f, %.3f", entry_name, curr_percent, post_percent)
      curr_percent = post_percent
    end

    output << "\n\n"

    file_name = "output/#{method_name}.svg"
    puts "Outputting chart to #{file_name}"
    # Could also output the `output` content instead
    # The original intention of the library was to use
    # human readable/writeable syntax
    ChartHelpers.render_chart(output.join("\n"), file_name)
  end
end

def _gantt_chart
  ret = nil

  # Determine the method and path that we're calling from
  call_loc = caller_locations.reject { |l| l.path.include?('byebug') }.first
  method_name = call_loc.label
  path = call_loc.path
  source = File.readlines(path)

  unless $timed[method_name]
    puts "Tracing #{path} for method #{method_name}"
    $timed[method_name] = { path: path, entries: [], calls: 0 }
  end

  # This block will be used to finalize the time it to run, gather the line source, etc.
  finalize_time = -> () do
    if last = $timed[method_name][:entries].pop
      # Finalize the time
      return if last[:start].nil? # Sometimes at the end it can mess up
      time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - last[:start]
      # Get the source line from the line number
      line = source[last[:line_no] - 1].strip
      next if line.include?('_gantt_chart')
      $timed[method_name][:entries] << { line_no: last[:line_no], line: line, time: time }
    end
  end

  # We use Ruby's tracepoint on a per line basis
  # We only care about lines called within our method and within our path
  trace = TracePoint.new(:line) do |tp|
    next unless tp.path == path
    next unless tp.method_id.to_s == method_name.to_s

    # We could have a call from last time, finalize it, we've moved to a new line
    finalize_time.call
    # Initialize a new entry with the line number and a start time
    $timed[method_name][:entries] << { line_no: tp.lineno, start: Process.clock_gettime(Process::CLOCK_MONOTONIC) }
  end

  begin
    trace.enable do
      ret = yield
    end
  ensure
    finalize_time.call # The last call needs to be finalized, finalize it here
  end

  ret
end
