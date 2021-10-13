require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
   zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_number(number)
    number = trim_number(number)

    if number.length == 11 && number[0] == "1"
        number[1..11]
    elsif number.length == 10
        number
    else
        "No number available"
    end
end

def trim_number(number)
    number.gsub(/[^0-9]/, "")
end

def best_hours(time_array)
    times = time_array.reduce(Hash.new(0)) do |key, value|
        key[value.hour] += 1
        key
    end   
    time_slots_array = []
    mapped_times = times.to_a.each do |time_slot|
        time_slots_array.push(time_slot[1])
    end
    
    peak_registers = time_slots_array.max
    peak_times_array = []
    peak_times = times.to_a.each do |hour|
        if hour[1] == peak_registers
            peak_times_array.push(hour)
        end
    end

    peak_times_array
end

def best_day_of_week(date, day_array)

    day_of_week = date.each do |day|
        
        weekday = 
                    case day.wday
                    when 0
                        day_array.push("Sunday")
                    when 1
                        day_array.push("Monday")
                    when 2
                        day_array.push("Tuesday")
                    when 3
                        day_array.push("Wednesday")
                    when 4
                        day_array.push("Thursday")
                    when 5
                        day_array.push("Friday")
                    when 6
                        day_array.push("Saturday")
                    else
                        "No valid day of the week"
                    end
    end
end

def peak_day_of_week(day_array)
    peak_days = day_array.reduce(Hash.new(0)) do |key, value|
        key[value] += 1
        key
    end
end


def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue 
        'Go to www.commoncause.org/take-action/find-elected-officials for more info.'
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
    puts form_letter
end


puts 'Event Manager Initialized!'

contents = CSV.open('event_attendees.csv', 
    headers: true,
    header_converters: :symbol
)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

time_array = []
day_array = []

contents.each do |row|
    id = row[0]
    name = row[:first_name]

    phone_number = clean_number(row[:homephone])

    register_date = row[:regdate]

    
    date = DateTime.strptime(register_date, "%m/%d/%Y %H:%M")

    time_array.push(date)
    
   
    puts "#{name} #{phone_number} #{register_date}"
    

    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
end

puts "Peak times:"
p best_hours(time_array)

puts "Peak Days"
best_day_of_week(time_array, day_array)
p peak_day_of_week(day_array)



