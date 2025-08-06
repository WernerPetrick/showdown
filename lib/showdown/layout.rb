require 'erb'

module Showdown
  class Layout
    attr_reader :template_path, :content
    
    def initialize(template_path = nil)
      @template_path = template_path
      @content = load_template
    end
    
    def render(presentation:, slides:, theme: nil)
      return render_default(presentation, slides, theme) unless template_path
      
      # Set instance variables for ERB template
      @presentation = presentation
      @slides = slides
      @theme = theme
      
      erb = ERB.new(content)
      erb.result(binding)
    end
    
    private
    
    def load_template
      return default_template unless template_path && File.exist?(template_path)
      File.read(template_path)
    end
    
    def render_default(presentation, slides, theme)
      html = []
      html << "<!DOCTYPE html>"
      html << "<html><head><meta charset='utf-8'>"
      html << "<title>#{presentation.title}</title>"
      html << "<style>#{theme.css if theme}</style>"
      html << "</head><body>"
      
      slides.each_with_index do |slide, index|
        html << "<div class='slide' data-slide='#{index + 1}'>"
        html << "<header>"
        html << "<h1>#{presentation.title}</h1>"
        html << "<span class='slide-number'>#{index + 1} / #{slides.length}</span>"
        html << "</header>"
        html << "<main>#{slide.content}</main>"
        html << "<footer>"
        html << "<span class='author'>#{presentation.author}</span>"
        html << "<span class='date'>#{presentation.date}</span>"
        html << "</footer>"
        html << "</div>"
      end
      
      html << "</body></html>"
      html.join("\n")
    end
    
    def default_template
      <<~ERB
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
    end
  end
end
