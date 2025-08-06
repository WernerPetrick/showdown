require 'prawn'
require 'prawn/table'

# Hide UTF-8 warnings for built-in fonts
Prawn::Fonts::AFM.hide_m17n_warning = true

module Showdown
  class Renderer
    attr_reader :options, :layout, :theme
    
    def initialize(options = {})
      @options = options
    end
    
    def render(presentation)
      setup_theme_and_layout(presentation)
      
      # Render HTML first using layout
      html_content = layout.render(
        presentation: presentation,
        slides: presentation.slides,
        theme: theme
      )
      
      # Convert to PDF using Prawn
      pdf_content = html_to_pdf(html_content, presentation)
      notes_pdf_content = render_notes(presentation) if options[:notes]
      
      {
        pdf: pdf_content,
        notes_pdf: notes_pdf_content
      }
    end
    
    private
    
    def setup_theme_and_layout(presentation)
      theme_path = options[:theme] || presentation.theme_file
      layout_path = options[:layout] || presentation.layout_file
      
      @theme = Theme.new(theme_path)
      @layout = Layout.new(layout_path)
    end
    
    def html_to_pdf(html_content, presentation)
      # For now, we'll create a simple PDF with Prawn
      # In a full implementation, you might want to use a HTML-to-PDF converter
      # like wkhtmltopdf or integrate with a browser engine
      
      pdf = Prawn::Document.new(
        page_size: theme.page_size,
        margin: theme.margin
      )

      # Register Unicode font
      font_path = File.expand_path("../../NotoSans-Regular.ttf", __dir__)
      if File.exist?(font_path)
        pdf.font_families.update(
          "NotoSans" => {
            normal: font_path,
            bold: font_path,
            italic: font_path,
            bold_italic: font_path
          }
        )
        pdf.font "NotoSans"
      end

      presentation.slides.each_with_index do |slide, index|
        pdf.start_new_page unless index == 0
        render_slide_to_pdf(pdf, slide, presentation, index + 1)
      end

      pdf.render
    end
    
    def render_slide_to_pdf(pdf, slide, presentation, slide_number)
      # Header
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 50) do
        pdf.font("NotoSans", size: 16) { pdf.text presentation.title }
        pdf.move_cursor_to pdf.bounds.height - 20
        pdf.font("NotoSans", size: 12) {
          pdf.draw_text "#{slide_number} / #{presentation.slides.length}",
                        at: [pdf.bounds.width - 100, pdf.cursor]
        }
        pdf.move_cursor_to 0
        pdf.stroke_horizontal_rule
        pdf.move_down 20
      end

      # Main content
      content_height = pdf.cursor - 100
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: content_height) do
        render_slide_content(pdf, slide)
      end

      # Footer
      pdf.bounding_box([0, 70], width: pdf.bounds.width, height: 50) do
        pdf.stroke_horizontal_rule
        pdf.move_down 10
        pdf.font("NotoSans", size: 10) {
          pdf.text_box presentation.author,
                       at: [0, pdf.cursor]
          pdf.text_box presentation.date,
                       at: [pdf.bounds.width - 100, pdf.cursor]
        }
      end
    end
    
    def render_slide_content(pdf, slide)
      # Use the new HTML processor for proper GFM support
      processor = HtmlProcessor.new(pdf, theme, @options)
      processor.process_html(slide.content)
    rescue => e
      pdf.font("NotoSans", size: 10) { pdf.text "Error rendering slide content: #{e.message}" }
      puts "Debug: #{e.message}" if @options[:verbose]
    end
    
    def render_notes(presentation)
      return nil unless presentation.slides.any?(&:has_notes?)
      
      pdf = Prawn::Document.new(
        page_size: 'A4',
        margin: 72
      )
      
      # Register Unicode font for notes PDF too
      font_path = File.expand_path("../../NotoSans-Regular.ttf", __dir__)
      if File.exist?(font_path)
        pdf.font_families.update(
          "NotoSans" => {
            normal: font_path,
            bold: font_path,
            italic: font_path,
            bold_italic: font_path
          }
        )
        pdf.font "NotoSans"
      end
      
      pdf.font("NotoSans", size: 18) do
        pdf.text "#{presentation.title} - Speaker Notes"
      end
      
      pdf.move_down 20
      
      presentation.slides.each_with_index do |slide, index|
        next unless slide.has_notes?
        
        pdf.start_new_page unless index == 0
        
        pdf.font("NotoSans", size: 14) do
          pdf.text "Slide #{index + 1}: #{slide.title}"
        end
        
        pdf.move_down 10
        
        pdf.font("NotoSans", size: 12) do
          notes_text = slide.notes.gsub(/<[^>]+>/, '')
          pdf.text notes_text
        end
        
        pdf.move_down 20
      end
      
      pdf.render
    end
    
    def hex_to_rgb(hex_color)
      # Convert hex color to RGB values for Prawn (0.0 to 1.0 range)
      return hex_color unless hex_color.is_a?(String) && hex_color.start_with?('#')
      
      hex = hex_color[1..-1]
      return hex_color if hex.length != 6
      
      r = hex[0..1].to_i(16) / 255.0
      g = hex[2..3].to_i(16) / 255.0
      b = hex[4..5].to_i(16) / 255.0
      
      [r, g, b]
    end
  end
end
