
require "showdown/version"
require "showdown/slide"
require "showdown/parser"
require "showdown/mermaid_renderer"
require "showdown/html_processor"
require "showdown/renderer"
require "showdown/layout"
require "showdown/theme"
require "showdown/watch_mode"
require "showdown/cli"

# Ensure prawn-svg is loaded for SVG diagram support
begin
  require 'prawn-svg'
rescue LoadError
  warn '[Showdown] Warning: prawn-svg gem not available, SVG rendering will be disabled.'
end

module Showdown
  class Error < StandardError; end
  
  class << self
    def convert(input_file, options = {})
      parser = Parser.new
      presentation = parser.parse(input_file)
      
      renderer = Renderer.new(options)
      renderer.render(presentation)
    end
  end
end
