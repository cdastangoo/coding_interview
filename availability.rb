require 'json'
require 'time'

# constants for working hours
DAY_START = "13:00:00"
DAY_END = "21:00:00"

# parse command line args
if ARGV.length == 1
  input = ARGV[0].split(',')
else
  puts "Please specify users as single arg (separate with comma)"
  puts "Example: `availability.rb Maggie,Joe,Jordan`"
  puts "Using default users"
  input = %w(Maggie Joe Jordan)
end

# read json files
all_users = JSON.parse(File.read('users.json'))
all_events = JSON.parse(File.read('events.json'))

# map user input names to their ids
users = []
all_users.each do |user|
  if input.include?(user['name'])
    users.push(user['id'])
  end
end

# filter events by user_id and sort by start_time
events = all_events.select { |event| users.include?(event['user_id']) }
events = events.sort_by { |event| event['start_time'] }

# iterate through events to mark available time slots
availability = {}
events.each do |event|
  date = event['start_time'].split('T').first
  start_time = event['start_time'].split('T').last
  end_time = event['end_time'].split('T').last
  # initialize list for the first event of a date
  if !availability.key?(date)
    availability[date] = [start_time, end_time]
    # if this time range is outside current marked availability, add it
  elsif Time.parse(start_time) > Time.parse(availability[date].last)
    availability[date].push(start_time, end_time)
    # if the end time of the time range overlaps, correct the upper bound
  elsif Time.parse(end_time) > Time.parse(availability[date].last)
    availability[date][-1] = end_time
  end
end

# get inverse of busy hours by correcting lower and upper bounds
availability.each_key do |date|
  # if the range starts with 13:00 remove it, otherwise append it at the start
  availability[date].first == DAY_START ? availability[date].shift : availability[date].insert(0, DAY_START)
  # if the range ends with 21:00 remove it, otherwise append it at the end
  availability[date].last == DAY_END ? availability[date].pop : availability[date].push(DAY_END)
end

# print availability (times manually displayed as HH:MM)
availability.each do |date, times|
  puts "" unless times.empty?
  idx = 0
  # iterate over every pair of times, so increment idx by 2
  while idx < times.length
    puts "#{date} #{times[idx][0..-4]} - #{times[idx + 1][0..-4]}"
    idx += 2
  end
end
