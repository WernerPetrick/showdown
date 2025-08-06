require 'commonmarker'
require 'front_matter_parser'
require 'yaml'

module Showdown
  class Parser
    SLIDE_DELIMITER = /^---slide\s*$/
    NOTES_DELIMITER = /^---notes\s*$/
    
    def parse(file_path)
      content = File.read(file_path)
      parsed = FrontMatterParser::Parser.parse_file(file_path)
      
      presentation = Presentation.new(
        metadata: parsed.front_matter,
        slides: extract_slides(parsed.content)
      )
      
      presentation
    end
    
    private
    
    def extract_slides(content)
      slides = []
      current_slide = nil
      current_notes = nil
      mode = :content
      
      content.split("\n").each do |line|
        case line
        when SLIDE_DELIMITER
          save_current_slide(slides, current_slide, current_notes) if current_slide
          current_slide = []
          current_notes = nil
          mode = :slide
          next
        when NOTES_DELIMITER
          mode = :notes
          current_notes = []
          next
        end
        
        case mode
        when :slide
          current_slide << line if current_slide
        when :notes
          current_notes << line if current_notes
        end
      end
      
      save_current_slide(slides, current_slide, current_notes) if current_slide
      slides
    end
    
    def save_current_slide(slides, slide_content, notes_content)
      return if slide_content.empty?
      
      rendered_content = render_markdown(slide_content.join("\n"))
      rendered_notes = notes_content ? render_markdown(notes_content.join("\n")) : nil
      
      slides << Slide.new(
        content: rendered_content,
        notes: rendered_notes,
        raw_content: slide_content.join("\n")
      )
    end
    
    def render_markdown(content)
      return "" if content.strip.empty?
      
      CommonMarker.render_html(
        content,
        :GITHUB_PRE_LANG,
        [:table, :strikethrough, :autolink, :tagfilter, :tasklist]
      )
    end
  end
  
  class Presentation
    attr_reader :metadata, :slides
    
    def initialize(metadata:, slides:)
      @metadata = metadata || {}
      @slides = slides
    end
    
    def title
      metadata['title'] || 'Untitled Presentation'
    end
    
    def author
      metadata['author'] || 'Unknown Author'
    end
    
    def date
      metadata['date'] || Date.today.to_s
    end
    
    def layout_file
      metadata['layout']
    end
    
    def theme_file
      metadata['theme']
    end
  end
end
