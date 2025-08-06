require 'yaml'

module Showdown
  class Theme
    attr_reader :config, :css
    
    def initialize(theme_path = nil)
      @config = load_theme_config(theme_path)
      @css = load_css
    end
    
    def colors
      config.dig('colors') || default_colors
    end
    
    def fonts
      config.dig('fonts') || default_fonts
    end
    
    def layout
      config.dig('layout') || default_layout
    end
    
    def margin
      layout['margin'] || 72
    end
    
    def slide_width
      layout['slide_width'] || 612
    end
    
    def slide_height
      layout['slide_height'] || 792
    end
    
    def orientation
      layout['orientation'] || 'portrait'
    end
    
    def page_size
      case orientation.downcase
      when 'landscape'
        [slide_width, slide_height]  # For landscape, use width x height as specified
      else
        [slide_width, slide_height]  # For portrait, use width x height as specified
      end
    end
    
    private
    
    def load_theme_config(theme_path)
      return {} unless theme_path && File.exist?(theme_path)
      
      case File.extname(theme_path)
      when '.yml', '.yaml'
        YAML.load_file(theme_path) || {}
      else
        {}
      end
    rescue => e
      puts "Warning: Could not load theme file #{theme_path}: #{e.message}"
      {}
    end
    
    def load_css
      custom_css = config['css']
      return default_css unless custom_css
      
      "#{default_css}\n\n#{custom_css}"
    end
    
    def default_colors
      {
        'primary' => '#2563eb',
        'secondary' => '#64748b',
        'background' => '#ffffff',
        'text' => '#1e293b'
      }
    end
    
    def default_fonts
      {
        'body' => 'Helvetica',
        'heading' => 'Helvetica-Bold',
        'code' => 'Courier'
      }
    end
    
    def default_layout
      {
        'margin' => 72,
        'slide_width' => 612,
        'slide_height' => 792,
        'orientation' => 'portrait'
      }
    end
    
    def default_css
      <<~CSS
        .slide {
          page-break-after: always;
          padding: 40px;
          font-family: #{fonts['body']}, sans-serif;
          color: #{colors['text']};
          background-color: #{colors['background']};
        }
        
        .slide header {
          border-bottom: 2px solid #{colors['primary']};
          padding-bottom: 10px;
          margin-bottom: 30px;
        }
        
        .slide header h1 {
          margin: 0;
          font-size: 18px;
          color: #{colors['primary']};
          font-family: #{fonts['heading']}, sans-serif;
        }
        
        .slide-number {
          float: right;
          color: #{colors['secondary']};
        }
        
        .slide main {
          min-height: 500px;
        }
        
        .slide footer {
          margin-top: 30px;
          padding-top: 10px;
          border-top: 1px solid #e2e8f0;
          font-size: 12px;
          color: #{colors['secondary']};
        }
        
        .author {
          float: left;
        }
        
        .date {
          float: right;
        }
        
        h1, h2, h3, h4, h5, h6 {
          color: #{colors['primary']};
          margin-top: 0;
          font-family: #{fonts['heading']}, sans-serif;
        }
        
        code {
          background-color: #f1f5f9;
          padding: 2px 4px;
          border-radius: 3px;
          font-family: #{fonts['code']}, monospace;
        }
        
        pre {
          background-color: #f8fafc;
          padding: 15px;
          border-radius: 5px;
          border-left: 4px solid #{colors['primary']};
        }
        
        pre code {
          background-color: transparent;
          padding: 0;
          font-family: #{fonts['code']}, monospace;
        }
        
        table {
          border-collapse: collapse;
          width: 100%;
          margin: 20px 0;
        }
        
        th, td {
          border: 1px solid #e2e8f0;
          padding: 8px 12px;
          text-align: left;
        }
        
        th {
          background-color: #{colors['primary']};
          color: white;
          font-family: #{fonts['heading']}, sans-serif;
        }
        
        ul li[data-task="true"] {
          list-style: none;
        }
        
        ul li[data-task="true"]:before {
          content: "✓ ";
          color: #10b981;
          font-weight: bold;
        }
        
        ul li[data-task="false"]:before {
          content: "☐ ";
          color: #6b7280;
        }
      CSS
    end
  end
end
