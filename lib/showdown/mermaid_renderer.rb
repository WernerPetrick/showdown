require 'tempfile'
require 'open3'
require 'mini_magick'
require 'securerandom'
require 'fileutils'
require 'tmpdir'

module Showdown
  class MermaidRenderer
    def initialize(options = {})
      @options = options
      @temp_dir = Dir.mktmpdir('showdown_mermaid')
    end
    
    def render_diagram(mermaid_code, width: 600, height: 400)
      # Try SVG first, then PNG as fallback
      svg_result = render_svg_diagram(mermaid_code, width, height)
      return svg_result if svg_result[:type] == :svg
      
      # Fallback to PNG if SVG fails
      png_result = render_png_diagram(mermaid_code, width, height)
      return png_result if png_result[:type] == :image
      
      # Online fallback
      online_result = render_online_fallback(mermaid_code)
      return online_result if online_result[:type] == :image
      
      # Final fallback
      render_fallback(mermaid_code)
    ensure
      # Note: Don't cleanup temp files immediately as SVG/PNG files might still be needed for PDF rendering
      # Cleanup will happen when the object is garbage collected or process ends
    end
    
    def render_svg_diagram(mermaid_code, width, height)
      unless mermaid_cli_available?
        puts "[DEBUG] Mermaid CLI not available for SVG rendering..." if @options[:verbose]
        return { type: :code }
      end
      begin
        # Create temporary files
        mmd_file = create_temp_file(mermaid_code, '.mmd')
        svg_file = File.join(@temp_dir, "diagram_#{SecureRandom.hex(8)}.svg")
        puts "[DEBUG] Generating SVG with mmdc: #{svg_file}" if @options[:verbose]
        # Run mermaid CLI to generate SVG
        command = build_svg_command(mmd_file, svg_file, width, height)
        stdout, stderr, status = Open3.capture3(command)
        puts "[DEBUG] mmdc stdout: #{stdout}" if @options[:verbose]
        puts "[DEBUG] mmdc stderr: #{stderr}" if @options[:verbose]
        puts "[DEBUG] mmdc status: #{status.success?}" if @options[:verbose]
        if status.success? && File.exist?(svg_file) && File.size(svg_file) > 0
          puts "✅ SVG diagram generated successfully at #{svg_file}" if @options[:verbose]
          return {
            type: :svg,
            path: svg_file,
            width: width,
            height: height
          }
        else
          puts "[DEBUG] SVG generation failed: #{stderr}" if @options[:verbose]
          return { type: :code }
        end
      rescue => e
        puts "[DEBUG] Error rendering SVG diagram: #{e.message}" if @options[:verbose]
        return { type: :code }
      end
    end
    
    def render_png_diagram(mermaid_code, width, height)
      unless mermaid_cli_available?
        return { type: :code }
      end
      
      begin
        # Create temporary files
        mmd_file = create_temp_file(mermaid_code, '.mmd')
        png_file = File.join(@temp_dir, "diagram_#{SecureRandom.hex(8)}.png")
        
        # Run mermaid CLI to generate diagram
        command = build_mermaid_command(mmd_file, png_file, width, height)
        stdout, stderr, status = Open3.capture3(command)
        
        if status.success? && File.exist?(png_file)
          # Convert to format suitable for Prawn
          process_image(png_file)
        else
          puts "PNG generation failed: #{stderr}" if @options[:verbose]
          { type: :code }
        end
        
      rescue => e
        puts "Error rendering PNG diagram: #{e.message}" if @options[:verbose]
        { type: :code }
      end
    end
    
    def render_online_fallback(mermaid_code)
      # Use Mermaid.ink online service as fallback
      begin
        require 'net/http'
        require 'uri'
        require 'base64'
        require 'json'
        
        # Encode mermaid code for URL
        encoded = Base64.strict_encode64(mermaid_code)
        url = URI("https://mermaid.ink/img/#{encoded}")
        
        response = Net::HTTP.get_response(url)
        
        if response.code == '200'
          # Save response to temporary file
          temp_file = File.join(@temp_dir, "online_diagram_#{SecureRandom.hex(8)}.png")
          File.binwrite(temp_file, response.body)
          
          if File.exist?(temp_file) && File.size(temp_file) > 0
            return {
              type: :image,
              path: temp_file,
              width: 400,
              height: 300
            }
          end
        end
        
        render_fallback(mermaid_code)
        
      rescue => e
        puts "Online Mermaid rendering failed: #{e.message}" if @options[:verbose]
        render_fallback(mermaid_code)
      end
    end
    
    private
    
    def mermaid_cli_available?
      # Check if mermaid CLI is installed
      begin
        stdout, stderr, status = Open3.capture3('mmdc --version')
        status.success?
      rescue Errno::ENOENT
        false
      end
    end
    
    def create_temp_file(content, extension)
      file = Tempfile.new(['mermaid', extension], @temp_dir)
      file.write(content)
      file.close
      file.path
    end
    
    def build_svg_command(input_file, output_file, width, height)
      "mmdc -i #{input_file} -o #{output_file} -w #{width} -H #{height} --theme neutral --backgroundColor white"
    end
    
    def build_mermaid_command(input_file, output_file, width, height)
      "mmdc -i #{input_file} -o #{output_file} -w #{width} -H #{height} --theme neutral --backgroundColor white"
    end
    
    def process_image(image_path)
      # Use MiniMagick to ensure image is properly formatted
      image = MiniMagick::Image.open(image_path)
      
      # Ensure it's PNG format and reasonable size
      image.format 'png'
      
      if image.width > 800
        image.resize '800x600>'
      end
      
      {
        type: :image,
        path: image_path,
        width: image.width,
        height: image.height
      }
    rescue => e
      puts "Image processing failed: #{e.message}" if @options[:verbose]
      render_fallback("")
    end
    
    def render_fallback(mermaid_code)
      {
        type: :code,
        content: mermaid_code,
        note: "Mermaid CLI not available. Install with: npm install -g @mermaid-js/mermaid-cli"
      }
    end
    
    def cleanup_temp_files
      FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    end
  end
end
