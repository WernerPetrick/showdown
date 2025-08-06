#!/usr/bin/env ruby

require 'bundler/setup'
require 'prawn'
require './lib/showdown'

# Create test PDFs that show their actual dimensions
theme_portrait = Showdown::Theme.new('./themes/default.yml')
theme_landscape = Showdown::Theme.new('./themes/landscape.yml')

# Portrait test
pdf = Prawn::Document.new(page_size: theme_portrait.page_size, margin: theme_portrait.margin)
pdf.text "PORTRAIT TEST", size: 24, style: :bold
pdf.move_down 20
pdf.text "Page size: #{theme_portrait.page_size.inspect}"
pdf.text "Page bounds: #{pdf.bounds.width} x #{pdf.bounds.height}"
pdf.text "Margin: #{theme_portrait.margin}"
pdf.move_down 20
pdf.text "If this page is taller than it is wide, portrait is working."

# Draw a border to visualize the page
pdf.stroke do
  pdf.rectangle [0, pdf.bounds.height], pdf.bounds.width, pdf.bounds.height
end

pdf.render_file('portrait-bounds-test.pdf')

# Landscape test  
pdf = Prawn::Document.new(page_size: theme_landscape.page_size, margin: theme_landscape.margin)
pdf.text "LANDSCAPE TEST", size: 24, style: :bold
pdf.move_down 20
pdf.text "Page size: #{theme_landscape.page_size.inspect}"
pdf.text "Page bounds: #{pdf.bounds.width} x #{pdf.bounds.height}"
pdf.text "Margin: #{theme_landscape.margin}"
pdf.move_down 20
pdf.text "If this page is wider than it is tall, landscape is working."

# Draw a border to visualize the page
pdf.stroke do
  pdf.rectangle [0, pdf.bounds.height], pdf.bounds.width, pdf.bounds.height
end

pdf.render_file('landscape-bounds-test.pdf')

puts "Created test PDFs:"
puts "- portrait-bounds-test.pdf: #{theme_portrait.page_size.inspect}"
puts "- landscape-bounds-test.pdf: #{theme_landscape.page_size.inspect}"
