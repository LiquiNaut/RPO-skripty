# frozen_string_literal: true

require 'open-uri'
require 'rubygems/package'
require 'json'
require 'zlib'
require 'fileutils'
require 'date'

puts "START"

buffer_size = 1024 * 1024 # Veľkosť buffera nastavená na 1 MB
directory_name = "batch-daily"

# Vytvorenie priečinka, ak neexistuje
FileUtils.mkdir_p(directory_name)

# Zisti datum prvej soboty mesiaca
def first_saturday_of_month(year, month)
  date = Date.new(year, month, 1)
  date += (6 - date.wday) % 7
  date.strftime('%Y-%m-%d')
end

first_saturday = first_saturday_of_month(Date.today.year, Date.today.month)

# Získame aktuálny dátum
today = Date.today.strftime("%Y-%m-%d")

=begin
Stiahne subory od prvej soboty mesiaca po dany den spustenia skriptu,
pozor ale batch-daily sa generuje o !!! 03:00 am !!!, cize Cron spustit az po tomto case
=end
(first_saturday..today).each do |i|

  url = "https://frkqbrydxwdp.compat.objectstorage.eu-frankfurt-1.oraclecloud.com/susr-rpo/batch-daily/actual_#{i}.json.gz"

  compressed_file = "#{directory_name}/actual_#{i}.json.gz"
  output_file = "#{directory_name}/actual_#{i}.json"

  # Stiahnutie súboru
  File.open(compressed_file, 'wb') do |local_file|
    URI.open(url, 'rb', :content_length_proc => lambda { |content_length| }) do |remote_file|
      while (buffer = remote_file.read(buffer_size))
        local_file.write(buffer)
      end
    end
  end

  # Dekompresia súboru
  Zlib::GzipReader.open(compressed_file) do |gz|
    File.open(output_file, 'wb') do |file|
      file.write(gz.read)
    end
  end

  # Zmazanie komprimovaných suborov
  File.delete(compressed_file)

  puts "Súbor bol úspešne stiahnutý, dekompresovaný a uložený ako #{output_file}."
end
