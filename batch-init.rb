# frozen_string_literal: true
require 'open-uri'
require 'rubygems/package'
require 'json'
require 'zlib'
require 'fileutils'
require 'date'

puts "START"

buffer_size = 1024 * 1024 # Veľkosť buffera nastavená na 1 MB
directory_name = "batch-init"

# Vytvorenie priečinka, ak neexistuje
FileUtils.mkdir_p(directory_name)

# Zisti datum prvej soboty mesiaca
def first_saturday_of_month(year, month)
  date = Date.new(year, month, 1)
  date += (6 - date.wday) % 7
  date.strftime('%Y-%m-%d')
end

today = Date.today
first_saturday = first_saturday_of_month(today.year, today.month)

(1..21).each do |i|
  file_number = format('%03d', i) # Formátuj číslo súboru na 3 číslice s nulami
  url = "https://frkqbrydxwdp.compat.objectstorage.eu-frankfurt-1.oraclecloud.com/susr-rpo/batch-init/init_#{first_saturday}_#{file_number}.json.gz"

  compressed_file = "#{directory_name}/#{first_saturday}_#{file_number}.json.gz"
  output_file = "#{directory_name}/#{first_saturday}_#{file_number}.json"

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

  puts "Súbor č. #{file_number} bol úspešne stiahnutý, dekompresovaný a uložený ako #{output_file}."
end
