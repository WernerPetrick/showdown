module Showdown
  class Slide
    attr_reader :content, :notes, :raw_content
    
    def initialize(content:, notes: nil, raw_content: nil)
      @content = content
      @notes = notes
      @raw_content = raw_content
    end
    
    def has_notes?
      !notes.nil? && !notes.strip.empty?
    end
    
    def title
      # Extract first heading from content
      if match = content.match(/<h[1-6][^>]*>(.*?)<\/h[1-6]>/i)
        match[1].strip
      else
        "Slide"
      end
    end
    
    def plain_text
      # Strip HTML tags for plain text representation
      content.gsub(/<[^>]+>/, '').strip
    end
  end
end
