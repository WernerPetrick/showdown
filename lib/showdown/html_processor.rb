require 'nokogiri'
require 'rouge'
require 'prawn/table'

module Showdown
  class HtmlProcessor
    attr_reader :pdf, :theme, :options
    
    def initialize(pdf, theme, options = {})
      @pdf = pdf
      @theme = theme
      @options = options
      # Load prawn-svg if available for SVG support
      begin
        require 'prawn-svg'
        @svg_support = true
        puts "[DEBUG] prawn-svg loaded: SVG support enabled" if @options[:verbose]
      rescue LoadError
        @svg_support = false
        puts "[DEBUG] prawn-svg NOT loaded: SVG support disabled" if @options[:verbose]
      end
    end
    
    def process_html(html_content)
      doc = Nokogiri::HTML::DocumentFragment.parse(html_content)
      process_node(doc)
    end
    
    private
    
    def process_node(node)
      case node.name
      when 'text'
        process_text(node)
      when 'h1'
        process_heading(node, 24)
      when 'h2'
        process_heading(node, 20)
      when 'h3'
        process_heading(node, 18)
      when 'h4', 'h5', 'h6'
        process_heading(node, 16)
      when 'p'
        process_paragraph(node)
      when 'ul'
        process_list(node, :unordered)
      when 'ol'
        process_list(node, :ordered)
      when 'li'
        process_list_item(node)
      when 'table'
        process_table(node)
      when 'pre'
        process_code_block(node)
      when 'code'
        process_inline_code(node)
      when 'strong', 'b'
        process_bold(node)
      when 'em', 'i'
        process_italic(node)
      when 'br'
        pdf.move_down 5
      else
        # Process child nodes for unknown elements
        node.children.each { |child| process_node(child) }
      end
    end
    
    def process_text(node)
      text = node.content.strip
      return if text.empty?
      
      pdf.text text, inline_format: true
    end
    
    def process_heading(node, size)
      text = extract_text(node)
      return if text.empty?
      
      pdf.move_down 10 unless pdf.cursor == pdf.bounds.height
      pdf.font("NotoSans", size: size) do
        pdf.text text
      end
      pdf.move_down 8
    end
    
    def process_paragraph(node)
      text = extract_formatted_text(node)
      return if text.strip.empty?
      
      pdf.font("NotoSans", size: 14) do
        pdf.text text, inline_format: true
      end
      pdf.move_down 8
    end
    
    def process_list(node, type)
      @list_counter = 0 if type == :ordered
      node.children.select(&:element?).each do |item|
        process_node(item)
      end
      pdf.move_down 5
    end
    
    def process_list_item(node)
      text = extract_formatted_text(node)
      return if text.strip.empty?
      
      # Check for task list items
      if text.match(/^\s*\[([ x])\]\s*(.*)$/i)
        checked = $1.downcase == 'x'
        content = $2
        bullet = checked ? "✓ " : "☐ "
        pdf.font("NotoSans", size: 12) { pdf.text "#{bullet}#{content}", inline_format: true }
      else
        pdf.font("NotoSans", size: 12) { pdf.text "• #{text}", inline_format: true }
      end
      pdf.move_down 3
    end
    
    def process_table(node)
      return unless node.css('tr').any?
      
      # Extract table data
      rows = []
      node.css('tr').each do |tr|
        row = []
        tr.css('td, th').each do |cell|
          row << extract_text(cell)
        end
        rows << row unless row.empty?
      end
      
      return if rows.empty?
      
      # Create table with prawn-table
      pdf.move_down 10
      pdf.font("NotoSans", size: 12)
      begin
        table_data = rows
        pdf.table(table_data, 
                  header: true,
                  width: pdf.bounds.width,
                  cell_style: { 
                    borders: [:top, :bottom, :left, :right],
                    border_width: 1,
                    border_color: 'CCCCCC',
                    padding: [5, 8]
                  }) do
          row(0).font_style = :bold if rows.length > 1
          row(0).background_color = 'F0F0F0' if rows.length > 1
        end
      rescue => e
        # Fallback to simple text if table fails
        pdf.text "Table content:"
        rows.each { |row| pdf.text row.join(" | ") }
      end
      pdf.move_down 10
    end
    
    def process_code_block(node)
      code_element = node.css('code').first
      language = nil
      code_text = nil
      if code_element
        code_text = code_element.content
        language = extract_language(code_element)
        # If not found on <code>, check <pre> node for class or lang
        if language.nil?
          if node['class']
            match = node['class'].match(/language-(\w+)/)
            language = match[1] if match
          elsif node['lang']
            language = node['lang']
          end
        end
        puts "[DEBUG] Detected code block language: #{language.inspect}, content: #{code_text.lines.first&.strip}..." if @options[:verbose]
        # Handle special cases like Mermaid
        if language == 'mermaid'
          puts "[DEBUG] Detected Mermaid code block. Calling process_mermaid..." if @options[:verbose]
          process_mermaid(code_text)
        else
          process_regular_code_block(code_text, language)
        end
      else
        puts "[DEBUG] No code element found in code block. Falling back to regular code block." if @options[:verbose]
        process_regular_code_block(node.content, nil)
      end
    end
    
    def process_mermaid(mermaid_code)
      puts "[DEBUG] process_mermaid called. Attempting to render diagram..." if @options[:verbose]
      pdf.move_down 10
      pdf.font("NotoSans", size: 12) do
        pdf.text "📊 Mermaid Diagram:"
      end
      pdf.move_down 5
      # Try to render actual diagram
      mermaid_renderer = MermaidRenderer.new(@options)
      result = mermaid_renderer.render_diagram(mermaid_code)
      puts "[DEBUG] MermaidRenderer result: #{result.inspect}" if @options[:verbose]
      case result[:type]
      when :svg, :image
        render_mermaid_image(result, mermaid_code)
      else
        puts "[DEBUG] Mermaid rendering fallback triggered. Showing code block." if @options[:verbose]
        render_mermaid_fallback(mermaid_code, result[:note])
      end
    end
    
    def render_mermaid_image(result, mermaid_code)
      begin
        case result[:type]
        when :svg
          render_svg_diagram(result)
        when :image
          render_png_diagram(result)
        else
          render_mermaid_fallback(mermaid_code, "Unsupported format")
        end
      rescue => e
        puts "Error embedding Mermaid diagram: #{e.message}" if @options[:verbose]
        render_mermaid_fallback(mermaid_code, "Rendering failed: #{e.message}")
      end
    end
    
    def render_svg_diagram(result)
      if @svg_support && File.exist?(result[:path])
        puts "[DEBUG] Rendering SVG diagram from: #{result[:path]}" if @options[:verbose]
        begin
          svg_content = File.read(result[:path])
          puts "[DEBUG] SVG file size: #{svg_content.size} bytes" if @options[:verbose]
          max_width = pdf.bounds.width - 20
          max_height = 300
          pdf.svg svg_content, 
                 at: [10, pdf.cursor],
                 width: [result[:width], max_width].min,
                 height: [result[:height], max_height].min
          pdf.move_down [result[:height], max_height].min + 10
        rescue => e
          puts "[ERROR] Exception in prawn-svg rendering: #{e.message}\n#{e.backtrace.join("\n")}" if @options[:verbose]
          render_mermaid_fallback("", "SVG rendering error: #{e.message}")
        end
      else
        puts "[DEBUG] SVG support not available or SVG file missing. Falling back..." if @options[:verbose]
        render_mermaid_fallback("", "SVG support requires prawn-svg gem or SVG file missing")
      end
    end
    
    def render_png_diagram(result)
      # Calculate dimensions to fit in available space
      max_width = pdf.bounds.width - 20
      max_height = 300
      
      img_width = [result[:width], max_width].min
      img_height = [result[:height], max_height].min
      
      # Maintain aspect ratio
      if result[:width] > 0 && result[:height] > 0
        ratio = [max_width.to_f / result[:width], max_height.to_f / result[:height]].min
        img_width = result[:width] * ratio
        img_height = result[:height] * ratio
      end
      
      # Center the image
      x_offset = (pdf.bounds.width - img_width) / 2
      
      pdf.image result[:path], 
               at: [x_offset, pdf.cursor],
               width: img_width,
               height: img_height
      
      pdf.move_down img_height + 10
    end
    
    def render_mermaid_fallback(mermaid_code, note = nil)
      # For now, show the mermaid code with a note
      pdf.stroke_color 'CCCCCC'
      pdf.fill_color '000000'
      pdf.rounded_rectangle [0, pdf.cursor], pdf.bounds.width, 100, 5
      pdf.stroke
      
      pdf.bounding_box([10, pdf.cursor - 10], width: pdf.bounds.width - 20, height: 80) do
        pdf.font("Courier", size: 10) do
          pdf.text mermaid_code
        end
        pdf.move_down 5
        pdf.font("NotoSans", size: 10) do
          note_text = note || "Mermaid diagrams are shown as code. Install mermaid-cli for diagram rendering."
          pdf.text "Note: #{note_text}", style: :italic
        end
      end
      
      pdf.move_down 110
    end
    
    def process_regular_code_block(code_text, language)
      pdf.move_down 10
      
      # Apply syntax highlighting if Rouge is available and language is specified
      if language && defined?(Rouge)
        begin
          lexer = Rouge::Lexer.find(language)
          if lexer
            render_code_block_simple(code_text, lexer, language)
            pdf.move_down 10
            return
          end
        rescue => e
          # Fall back to plain code if highlighting fails
        end
      end
      
      # Plain code block
      render_plain_code_block_simple(code_text)
      pdf.move_down 10
    end
    
    def render_code_block_simple(code_text, lexer, language)
      # Check if we have very little space left and the code block is large
      available_height = pdf.cursor - pdf.bounds.bottom - 50
      estimated_height = estimate_code_height(code_text)
      
      # Only start new page if we have less than 100 points available and the code is large
      if available_height < 100 && estimated_height > 200
        pdf.start_new_page
        pdf.move_down 20
      end
      
      # Render the code block normally
      pdf.fill_color '000000'
      pdf.stroke_color 'CCCCCC'
      
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
        # Background and border
        pdf.fill_and_stroke_rounded_rectangle [0, 0], pdf.bounds.width, estimated_height, 5
        pdf.fill_color 'F8F8F8'
        pdf.fill_rounded_rectangle [1, -1], pdf.bounds.width - 2, estimated_height - 2, 5
        
        # Language label if provided
        if language
          pdf.bounding_box([pdf.bounds.width - 100, -5], width: 90, height: 20) do
            pdf.fill_color 'DDDDDD'
            pdf.fill_rounded_rectangle [0, 0], 90, 18, 3
            pdf.fill_color '666666'
            pdf.font("NotoSans", size: 8) do
              pdf.text_box language.upcase, at: [5, 12], width: 80, height: 15, 
                          valign: :center, align: :center
            end
          end
        end
        
        # Code content
        pdf.bounding_box([10, -10], width: pdf.bounds.width - 20) do
          pdf.fill_color '000000'
          pdf.font("NotoSans", size: 10) do
            if lexer
              highlighted = highlight_code(code_text, lexer)
              pdf.text highlighted.gsub(/\e\[[0-9;]*m/, '') # Strip ANSI codes
            else
              pdf.text code_text
            end
          end
        end
      end
      
      pdf.move_down estimated_height
    end
    
    def render_plain_code_block_simple(code_text)
      # Check if we have very little space left and the code block is large
      available_height = pdf.cursor - pdf.bounds.bottom - 50
      estimated_height = estimate_code_height(code_text)
      
      # Only start new page if we have less than 100 points available and the code is large
      if available_height < 100 && estimated_height > 200
        pdf.start_new_page
        pdf.move_down 20
      end
      
      # Render the code block normally
      pdf.fill_color '000000'
      pdf.stroke_color 'CCCCCC'
      
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
        pdf.fill_and_stroke_rounded_rectangle [0, 0], pdf.bounds.width, estimated_height, 5
        pdf.fill_color 'F8F8F8'
        pdf.fill_rounded_rectangle [1, -1], pdf.bounds.width - 2, estimated_height - 2, 5
        
        pdf.bounding_box([10, -10], width: pdf.bounds.width - 20) do
          pdf.fill_color '000000'
          pdf.font("NotoSans", size: 10) do
            pdf.text code_text
          end
        end
      end
      
      pdf.move_down estimated_height
    end
    
    def process_inline_code(node)
      # This is handled in formatted text extraction
      node.content
    end
    
    def process_bold(node)
      # This is handled in formatted text extraction
      extract_text(node)
    end
    
    def process_italic(node)
      # This is handled in formatted text extraction
      extract_text(node)
    end
    
    def extract_text(node)
      return node.content if node.text?
      
      text = ""
      node.children.each do |child|
        text += extract_text(child)
      end
      text
    end
    
    def extract_formatted_text(node)
      return node.content if node.text?
      
      text = ""
      node.children.each do |child|
        case child.name
        when 'text'
          text += child.content
        when 'strong', 'b'
          text += "<b>#{extract_text(child)}</b>"
        when 'em', 'i'
          text += "<i>#{extract_text(child)}</i>"
        when 'code'
          text += "<font name='NotoSans' size='12'><color rgb='666666'>#{child.content}</color></font>"
        when 'br'
          text += "\n"
        else
          text += extract_formatted_text(child)
        end
      end
      text
    end
    
    def extract_language(code_element)
      # Look for language class on code element
      classes = code_element['class']
      return nil unless classes
      
      # CommonMarker adds language as "language-xxx"
      match = classes.match(/language-(\w+)/)
      match ? match[1] : nil
    end
    
    def highlight_code(code, lexer)
      formatter = Rouge::Formatters::Terminal.new
      formatter.format(lexer.lex(code))
    end

    def render_highlighted_code(highlighted_text)
      # For now, render as plain text since Prawn doesn't support terminal colors
      # In a more advanced implementation, you could parse the ANSI codes
      # and apply appropriate formatting
      pdf.font("NotoSans", size: 10) do
        pdf.text highlighted_text.gsub(/\e\[[0-9;]*m/, '') # Strip ANSI codes
      end
    end
    
    def estimate_code_height(code_text)
      lines = code_text.split("\n")
      line_count = lines.length
      line_height = 12
      padding = 20
      
      # Account for very long lines that might wrap
      max_chars_per_line = 80 # Approximate characters that fit in code block width
      total_lines = lines.sum do |line|
        [(line.length.to_f / max_chars_per_line).ceil, 1].max
      end
      
      [total_lines * line_height + padding, 40].max
    end
  end
end
