require 'thor'
require 'showdown'
require 'date'

module Showdown
  class CLI < Thor
    desc "convert INPUT_FILE", "Convert markdown presentation to PDF"
    option :output, aliases: '-o', desc: "Output PDF file path"
    option :layout, aliases: '-l', desc: "Layout template file path"
    option :theme, aliases: '-t', desc: "Theme file path"
    option :notes, aliases: '-n', type: :boolean, desc: "Generate separate notes PDF"
    option :verbose, aliases: '-v', type: :boolean, desc: "Verbose output"
    
    def convert(input_file)
      unless File.exist?(input_file)
        puts "Error: Input file '#{input_file}' not found."
        exit 1
      end
      
      output_file = options[:output] || default_output_name(input_file)
      
      convert_options = {
        layout: options[:layout],
        theme: options[:theme],
        notes: options[:notes],
        verbose: options[:verbose]
      }
      
      puts "Converting #{input_file} to #{output_file}..." if options[:verbose]
      
      begin
        result = Showdown.convert(input_file, convert_options)
        File.write(output_file, result[:pdf])
        
        if options[:notes] && result[:notes_pdf]
          notes_file = output_file.gsub('.pdf', '_notes.pdf')
          File.write(notes_file, result[:notes_pdf])
          puts "Notes saved to #{notes_file}" if options[:verbose]
        end
        
        puts "Presentation saved to #{output_file}"
      rescue => e
        puts "Error: #{e.message}"
        exit 1
      end
    end
    
    desc "init", "Initialize a new presentation template"
    def init
      create_sample_files
      puts "Sample presentation files created!"
    end
    
    desc "version", "Show version"
    def version
      puts Showdown::VERSION
    end
    
    desc "watch INPUT_FILE", "Watch file for changes and auto-regenerate PDF"
    option :output, aliases: '-o', desc: "Output PDF file path"
    option :layout, aliases: '-l', desc: "Layout template file path"  
    option :theme, aliases: '-t', desc: "Theme file path"
    option :notes, aliases: '-n', type: :boolean, desc: "Generate separate notes PDF"
    option :verbose, aliases: '-v', type: :boolean, desc: "Verbose output"
    option :debounce, aliases: '-d', type: :numeric, default: 0.5, desc: "Debounce delay in seconds"
    
    def watch(input_file)
      unless File.exist?(input_file)
        puts "Error: Input file '#{input_file}' not found."
        exit 1
      end
      
      watch_options = {
        output: options[:output] || default_output_name(input_file),
        layout: options[:layout],
        theme: options[:theme], 
        notes: options[:notes],
        verbose: options[:verbose],
        debounce: options[:debounce]
      }
      
      require_relative 'watch_mode'
      watcher = WatchMode.new(input_file, watch_options)
      watcher.start
    end

    private
    
    def default_output_name(input_file)
      File.basename(input_file, File.extname(input_file)) + '.pdf'
    end
    
    def create_sample_files
      create_sample_presentation
      create_sample_layout
      create_sample_theme
      create_landscape_theme
    end
    
    def create_sample_presentation
      content = <<~MARKDOWN
        ---
        title: "My Presentation"
        author: "Your Name"
        date: "#{Date.today}"
        layout: "./layouts/default.erb"
        theme: "./themes/default.yml"
        ---
        
        ---slide
        # Welcome to Showdown
        
        A simple markdown to PDF presentation converter
        
        ---notes
        This is a speaker note for the first slide.
        You can add detailed explanations here.
        
        ---slide
        ## Features
        
        - GitHub Flavored Markdown support
        - Custom layouts with ERB
        - Speaker notes
        - Syntax highlighting
        - Tables and task lists
        
        ---slide
        ## Code Example
        
        ```ruby
        def hello_world
          puts "Hello, Showdown!"
        end
        ```
        
        - [x] Easy to use
        - [ ] More features coming soon
        
        ---slide
        # Thank You!
        
        Questions?
      MARKDOWN
      
      File.write('presentation.md', content)
    end
    
    def create_sample_layout
      Dir.mkdir('layouts') unless Dir.exist?('layouts')
      
      layout_content = <<~ERB
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title><%= @presentation.title %></title>
          <style>
            <%= @theme.css if @theme %>
          </style>
        </head>
        <body>
          <% @slides.each_with_index do |slide, index| %>
            <div class="slide" data-slide="<%= index + 1 %>">
              <header>
                <h1><%= @presentation.title %></h1>
                <span class="slide-number"><%= index + 1 %> / <%= @slides.length %></span>
              </header>
              
              <main>
                <%= slide.content %>
              </main>
              
              <footer>
                <span class="author"><%= @presentation.author %></span>
                <span class="date"><%= @presentation.date %></span>
              </footer>
            </div>
          <% end %>
        </body>
        </html>
      ERB
      
      File.write('layouts/default.erb', layout_content)
    end
    
    def create_sample_theme
      Dir.mkdir('themes') unless Dir.exist?('themes')
      
      theme_content = <<~YAML
        colors:
          primary: "#2563eb"
          secondary: "#64748b" 
          background: "#ffffff"
          text: "#1e293b"
        
        fonts:
          body: "Helvetica"
          heading: "Helvetica-Bold"
          code: "Courier"
        
        layout:
          margin: 72
          slide_width: 612
          slide_height: 792
          orientation: "portrait"  # "portrait" or "landscape"
        
        css: |
          .slide {
            page-break-after: always;
            padding: 40px;
            font-family: Helvetica, sans-serif;
            color: #1e293b;
          }
          
          .slide header {
            border-bottom: 2px solid #2563eb;
            padding-bottom: 10px;
            margin-bottom: 30px;
          }
          
          .slide header h1 {
            margin: 0;
            font-size: 18px;
            color: #2563eb;
          }
          
          .slide-number {
            float: right;
            color: #64748b;
          }
          
          .slide main {
            min-height: 500px;
          }
          
          .slide footer {
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #e2e8f0;
            font-size: 12px;
            color: #64748b;
          }
          
          .author {
            float: left;
          }
          
          .date {
            float: right;
          }
          
          h1, h2, h3, h4, h5, h6 {
            color: #2563eb;
            margin-top: 0;
          }
          
          code {
            background-color: #f1f5f9;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: Courier, monospace;
          }
          
          pre {
            background-color: #f8fafc;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #2563eb;
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
      YAML
      
      File.write('themes/default.yml', theme_content)
    end
    
    def create_landscape_theme
      Dir.mkdir('themes') unless Dir.exist?('themes')
      
      theme_content = <<~YAML
        colors:
          primary: "#059669"
          secondary: "#6b7280" 
          background: "#ffffff"
          text: "#111827"
        
        fonts:
          body: "Helvetica"
          heading: "Helvetica-Bold"
          code: "Courier"
        
        layout:
          margin: 50
          slide_width: 792
          slide_height: 612
          orientation: "landscape"  # "portrait" or "landscape"
        
        css: |
          .slide {
            page-break-after: always;
            padding: 30px;
            font-family: Helvetica, sans-serif;
            color: #111827;
          }
          
          .slide header {
            border-bottom: 3px solid #059669;
            padding-bottom: 15px;
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          
          .slide header h1 {
            margin: 0;
            font-size: 20px;
            color: #059669;
          }
          
          .slide-number {
            color: #6b7280;
            font-size: 14px;
          }
          
          .slide main {
            min-height: 400px;
            display: flex;
            flex-direction: column;
            justify-content: center;
          }
          
          .slide footer {
            margin-top: 25px;
            padding-top: 15px;
            border-top: 1px solid #e5e7eb;
            font-size: 12px;
            color: #6b7280;
            display: flex;
            justify-content: space-between;
          }
          
          h1, h2, h3, h4, h5, h6 {
            color: #059669;
            margin-top: 0;
          }
          
          h1 {
            font-size: 32px;
            text-align: center;
          }
          
          h2 {
            font-size: 24px;
          }
          
          code {
            background-color: #f3f4f6;
            padding: 3px 6px;
            border-radius: 4px;
            font-family: Courier, monospace;
          }
          
          pre {
            background-color: #f9fafb;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #059669;
          }
          
          ul, ol {
            font-size: 18px;
            line-height: 1.6;
          }
          
          ul li[data-task="true"] {
            list-style: none;
          }
          
          ul li[data-task="true"]:before {
            content: "✅ ";
            margin-right: 8px;
          }
          
          ul li[data-task="false"]:before {
            content: "☐ ";
            margin-right: 8px;
            color: #9ca3af;
          }
      YAML
      
      File.write('themes/landscape.yml', theme_content)
    end
  end
end
