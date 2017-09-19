def _t(label)
  t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  ret = yield
  puts "#{label} #{Process.clock_gettime(Process::CLOCK_MONOTONIC) - t}"
  ret
end