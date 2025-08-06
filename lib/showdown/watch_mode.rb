require 'listen'
require 'pathname'

module Showdown
  class WatchMode
    attr_reader :file_path, :options, :listener
    
    def initialize(file_path, options = {})
      @file_path = File.expand_path(file_path)
      @options = {
        output: nil,
        verbose: false,
        notes: false,
        debounce: 0.5, # Wait 500ms for multiple changes
        **options
      }
      @last_generation = nil
      @generation_in_progress = false
    end
    
    def start
      validate_file!
      setup_initial_generation
      setup_listener
      
      puts "🚀 Starting live reload for: #{File.basename(@file_path)}"
      puts "📁 Watching directory: #{watch_directory}"
      puts "📄 Output: #{output_path}"
      puts "⚡ Live reload active - press Ctrl+C to stop"
      puts ""
      
      @listener.start
      
      # Keep the process alive
      begin
        sleep
      rescue Interrupt
        puts "\n👋 Live reload stopped"
        @listener.stop
      end
    end
    
    private
    
    def validate_file!
      unless File.exist?(@file_path)
        raise ArgumentError, "File not found: #{@file_path}"
      end
      
      unless @file_path.end_with?('.md')
        raise ArgumentError, "File must be a markdown file (.md): #{@file_path}"
      end
    end
    
    def setup_initial_generation
      puts "🔨 Generating initial PDF..."
      generate_pdf
      puts "✅ Initial PDF generated"
      puts ""
    end
    
    def setup_listener
      @listener = Listen.to(watch_directory, 
                           only: watch_patterns,
                           latency: @options[:debounce]) do |modified, added, removed|
        handle_file_changes(modified, added, removed)
      end
    end
    
    def watch_directory
      # Watch the directory containing the markdown file and related directories
      base_dir = File.dirname(@file_path)
      File.expand_path(base_dir)
    end
    
    def watch_patterns
      # Watch for changes in markdown, theme, layout, and asset files
      /\.(md|yml|yaml|erb|css|png|jpg|jpeg|svg)$/
    end
    
    def handle_file_changes(modified, added, removed)
      return if @generation_in_progress
      
      changed_files = (modified + added + removed).uniq
      relevant_changes = changed_files.select { |file| file_affects_presentation?(file) }
      
      if relevant_changes.any?
        puts "📝 Changes detected:"
        relevant_changes.each { |file| puts "   #{File.basename(file)}" }
        
        # Debounce rapid changes
        return if @last_generation && (Time.now - @last_generation) < @options[:debounce]
        
        regenerate_pdf
      end
    end
    
    def file_affects_presentation?(file_path)
      # Check if the changed file affects our presentation
      return true if file_path == @file_path # Main markdown file
      return true if file_path.match?(/\.(yml|yaml)$/) # Theme files
      return true if file_path.match?(/\.erb$/) # Layout files
      return true if file_path.include?('themes/') # Theme directory
      return true if file_path.include?('layouts/') # Layout directory
      return true if file_path.include?('assets/') # Assets directory
      
      # Check if it's referenced in the main file
      if File.exist?(@file_path)
        content = File.read(@file_path)
        relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(File.dirname(@file_path)))
        return content.include?(relative_path.to_s)
      end
      
      false
    end
    
    def regenerate_pdf
      @generation_in_progress = true
      @last_generation = Time.now
      
      puts ""
      puts "🔄 Regenerating PDF... (#{Time.now.strftime('%H:%M:%S')})"
      
      start_time = Time.now
      success = generate_pdf
      duration = ((Time.now - start_time) * 1000).round
      
      if success
        puts "✅ PDF updated successfully (#{duration}ms)"
      else
        puts "❌ PDF generation failed"
      end
      puts ""
      
      @generation_in_progress = false
    end
    
    def generate_pdf
      begin
        # Use Showdown.convert directly instead of CLI
        convert_options = {
          layout: @options[:layout],
          theme: @options[:theme],
          notes: @options[:notes],
          verbose: @options[:verbose]
        }
        
        result = Showdown.convert(@file_path, convert_options)
        File.write(output_path, result[:pdf])
        
        if @options[:notes] && result[:notes_pdf]
          notes_path = output_path.gsub('.pdf', '_notes.pdf')
          File.write(notes_path, result[:notes_pdf])
        end
        
        true
      rescue => e
        puts "❌ Error generating PDF: #{e.message}"
        puts e.backtrace.first(3).map { |line| "   #{line}" } if @options[:verbose]
        false
      end
    end
    
    def output_path
      return @options[:output] if @options[:output]
      
      # Default output: same name as input but with .pdf extension
      base_name = File.basename(@file_path, '.md')
      output_dir = File.dirname(@file_path)
      File.join(output_dir, "#{base_name}.pdf")
    end
  end
end
