require_relative '../helpers/aggregate'

i = 0

# This will react the same as _t
# except the result is deferred to the end
_ta('basic') do
  puts i
end

# This will react the same as _t
# except the result is deferred to the end
_ta('longer') do
  while i < 30
    i += 1
    sleep 0.1
  end
end

# _ta is called many times here
# But because it is aggregated - we only see once at the end
def my_method(i = 0)
  _ta('method') do
    return if i > 20
    sleep 0.1
    my_method(i + 1)
  end
end

my_method
