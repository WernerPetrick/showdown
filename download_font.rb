# Download NotoSans-Regular.ttf for Unicode support
require 'open-uri'
url = 'https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSans/NotoSans-Regular.ttf'
File.open('NotoSans-Regular.ttf', 'wb') do |f|
  f.write URI.open(url).read
end
puts 'NotoSans-Regular.ttf downloaded.'
