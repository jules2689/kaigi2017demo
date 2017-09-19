require_relative '../helpers/gantt'

# This is the basic example of a gantt chart
# Each line takes about an equal amount of time
def my_method(i)
  _gantt_chart do
    puts i
    return if i > 200
    my_method(i + 1)
  end
end

# This shows the difference when one line takes a lot longer than the others
# You can see the `sleep` line takes a lot longer than the other lines
def my_method_2(i)
  _gantt_chart do
    puts i
    return if i > 20
    sleep 0.1
    my_method_2(i + 1)
  end
end

my_method(0)
my_method_2(0)
