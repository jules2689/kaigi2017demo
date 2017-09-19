require_relative '../helpers/time'

i = 0

# This will output a basic statement
_t('basic') do
  puts i
end

# This will output a basic statement
_t('longer') do
  while i < 30
    i += 1
    sleep 0.1
  end
end

# _t('method') is called many times because of the recursion
# In this case we will see many outputs for _t('method')
# This may not be what we want, see the aggregation demo
def my_method(i = 0)
  _t('method') do
    return if i > 20
    sleep 0.1
    my_method(i + 1)
  end
end

my_method
