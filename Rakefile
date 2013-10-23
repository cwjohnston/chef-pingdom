begin
  require 'stove/rake_task'

  Stove::RakeTask.new do |stove|
    stove.git = true
    stove.devodd = false
  end
rescue LoadError
  puts "could not load stove, skipping stove tasks"
end

