require 'thor'
require 'exif'
require 'csv'

class RubyCLI < Thor
  class_option :verbose, :type => :boolean

  IMAGE_DIRECTORY = './gps_images'
  CSV_FILE_PATH = './output.csv'

  desc 'extract', "Extract GPS data from images in #{IMAGE_DIRECTORY}"
  def extract_gps_data()

    image_files = Dir.glob("#{IMAGE_DIRECTORY}/**/*")

    image_files.each do |image_path|

      begin
        File.open(image_path) do |image|
          # Use Exif for capturing image metadata
          data = Exif::Data.new(image)
          lat, long = extract_latitude_longitude(data)
          next if lat.nil? || long.nil?

          file_name = File.basename(image_path)
          write_data(file_name, lat, long)
        end
      rescue => e
        # puts e.message
      end

    end

  end


  private
  
  def write_data(file_name, lat, long)
    puts "GPS data from #{file_name}: #{lat} #{long}" if options[:verbose]

    # Open the CSV file in append mode ('a') and write the XML string
    CSV.open(CSV_FILE_PATH, 'a') do |csv|
      csv << [file_name, lat, long]
    end
  end

  def extract_latitude_longitude(data)
    latitude = "#{parse_gps_data(data.gps_latitude)} #{data.gps_latitude_ref}"
    longitude = "#{parse_gps_data(data.gps_longitude)} #{data.gps_longitude_ref}"

    return latitude, longitude
  end
  
  # interpreting the gps data: https://github.com/tonytonyjan/exif/issues/21
  def parse_gps_data(array)
    degrees, minutes, seconds = [Rational(array[0]), Rational(array[1]), Rational(array[2])]

    degrees + minutes / 60.0 + seconds / 3600.0
  end

end

RubyCLI.start(ARGV)