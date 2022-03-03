# Background

Most calendar applications provide some kind of "meet with" feature where the user
can input a list of coworkers with whom they want to meet, and the calendar will
output a list of times where all the coworkers are available.

For example, say that we want to schedule a meeting with Jane, John, and Mary on Monday.

- Jane is busy from 9am - 10am, 12pm - 1pm, and 4pm - 5pm.
- John is busy from 9:30am - 11:00am and 3pm - 4pm
- Mary is busy from 3:30pm - 5pm.

Based on that information, our calendar app should tell us that everyone is available:
- 11:00am - 12:00pm
- 1pm - 3pm

We can then schedule a meeting during any of those available times.


# Instructions

Given the data in `events.json` and `users.json`, build a script that displays available times
for a given set of users. For example, your script might be executed like this:

```
python availability.py Maggie,Joe,Jordan
```

and would output something like this:

```
2021-07-05 13:30 - 16:00
2021-07-05 17:00 - 19:00
2021-07-05 20:00 - 21:00
2021-07-06 14:30 - 15:00
2021-07-06 16:00 - 18:00
2021-07-06 19:00 - 19:30
2021-07-06 20:00 - 20:30
2021-07-07 14:00 - 15:00
2021-07-07 16:00 - 16:15
```


For the purposes of this exercise, you should restrict your search between `2021-07-05` and `2021-07-07`,
which are the three days covered in the `events.json` file. You can also assume working hours between
`13:00` and `21:00` UTC, which is 9-5 Eastern (don't worry about any time zone conversion, just work in
UTC). Optionally, you could make your program support configured working hours, but this is not necessary.


## Data files

### `users.json`

A list of users that our system is aware of. You can assume all the names are unique (in the real world, maybe
they would be input as email addresses).

`id`: An integer unique to the user

`name`: The display name of the user - your program should accept these names as input.

### `events.json`

A dataset of all events on the calendars of all our users.

`id`: An integer unique to the event

`user_id`: A foreign key reference to a user

`start_time`: The time the event begins

`end_time`: The time the event ends


# Notes

- Feel free to use whatever language you feel most comfortable working with
- Please provide instructions for execution of your program
- Please include a description of your approach to the problem, as well as any documentation about
  key parts of your code.
- You'll notice that all our events start and end on 15 minute blocks. However, this is not a strict
  requirement. Events may start or end on any minute (for example, you may have an event from 13:26 - 13:54).


# Execution

I chose to implement this solution in Ruby.
I have version 3.1 so ideally this should be installed,
though it should work with past versions since there aren't really any dependencies being used.

To execute, run `availability.rb` with the given users as a single command line arg, separated with commas.
If no args are specified it will run with `Maggie,Joe,Jordan` as per the example.
Either directly run with configured args in an IDE (e.g. RubyMine) or from the terminal, for example:
```
ruby availability.rb Jane,John,Nick,Emily
```

# Approach

First parse the user and event json files and command line args to get all the relevant data.
Then map the input user names to their matching ids (i.e. Jane maps to 1)
so that we can look up each user's availability in the events hash.
Next, filter the events on these user id's so that we only have to worry about relevant time slots.
We also want to sort the events by their start time to make parsing them much easier.

To iterate through each of the events, we want to mark the user's overlapping availability.
Since each event marks when a user is unavailable, we are essentially just finding the overlaps between these times,
and then taking the "inverse" of this to find their shared availability.
Since the events have now been sorted by start date, this can be done in a single pass.
Then a second shorter pass over the shared busy times is needed, to get the inverse within standard working hours.

We can store the shared busy times as a hash,
where each date is mapped to an array of the overlapping busy times of that day.
For each event, when we come across a new date, we create this key in the hash and set it's array to that event's time range.
Then we can check if a given event time range is outside the current busy times.
If the start time occurs after the latest time in the range, append this range to the list.
Otherwise we need to see if there's an overlap.
If the start time occurs within the given busy times, but the end time does not,
then we just need to correct the upper bound to "expand" the last time range.
Otherwise just check the next event.

For the second pass, we basically just need to correct the lower and upper bounds
to effectively take the "inverse" of the shared busy times.
So if a time range starts with 13:00 then remove it, otherwise append it to the start of the list.
If instead a time range ends with 21:00 then again remove it, otherwise append it to the end of the list.
This will yield the list of shared available time ranges for each date.
Lastly print the availability by looping over the hash,
where for each date we check every 2 elements to get pairs of times.
