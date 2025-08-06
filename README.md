![ShowDown Logo](https://github.com/WernerPetrick/showdown/raw/main/images/ShowDown_logo.png)

Showdown is a Ruby gem that converts markdown presentations to PDF with custom layouts. It supports GitHub Flavored Markdown, custom slide delimiters, ERB layouts, speaker notes, and theming.

## Features

- 📊 **GitHub Flavored Markdown** - Full support for tables, code highlighting, task lists, and more
- 🎨 **Custom Layouts** - Use ERB templates to create custom slide layouts  
- 🎯 **Slide Delimiters** - Use `---slide` and `---notes` for clear slide separation
- 📝 **Speaker Notes** - Generate separate PDF with detailed speaker notes
- 🎭 **Theming** - Customize colors, fonts, and styling with YAML theme files
- 📐 **Orientation Support** - Choose between portrait and landscape orientations
- ⚡ **CLI Interface** - Simple command-line tool for quick conversions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'showdown'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install showdown

## Quick Start

1. Initialize a new presentation:
```bash
showdown init
```

2. Edit the generated `presentation.md` file with your content

3. Convert to PDF:
```bash
showdown convert presentation.md
```

4. Generate with speaker notes:
```bash
showdown convert presentation.md --notes
```

## Slide Format

Showdown uses a simple delimiter syntax for slides:

```markdown
---
title: "My Presentation"
author: "Your Name"  
date: "2025-08-06"
layout: "./layouts/default.erb"
theme: "./themes/default.yml"
---

---slide
# Welcome Slide

Your content here with **GitHub Flavored Markdown** support:

- [x] Task lists
- [ ] Code highlighting
- Tables and more!

---notes
These are speaker notes that appear in a separate PDF.
Add detailed explanations and talking points here.

---slide
## Features

| Feature | Supported |
|---------|-----------|
| GFM | ✅ |
| Themes | ✅ |
| Notes | ✅ |

``ruby
def example_code
  puts "Syntax highlighting works!"
end
``

---slide
# Thank You!

Questions?
```

## Layouts

Create custom ERB layouts in the `layouts/` directory:

```erb
<!DOCTYPE html>
<html>
<head>
  <title><%= @presentation.title %></title>
  <style><%= @theme.css if @theme %></style>
</head>
<body>
  <% @slides.each_with_index do |slide, index| %>
    <div class="slide" data-slide="<%= index + 1 %>">
      <header>
        <h1><%= @presentation.title %></h1>
        <span class="slide-number"><%= index + 1 %> / <%= @slides.length %></span>
      </header>
      
      <main><%= slide.content %></main>
      
      <footer>
        <span class="author"><%= @presentation.author %></span>
        <span class="date"><%= @presentation.date %></span>
      </footer>
    </div>
  <% end %>
</body>
</html>
```

## Themes

Customize appearance with YAML theme files:

```yaml
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
    font-family: Helvetica, sans-serif;
    padding: 40px;
  }
  
  h1, h2, h3 {
    color: #2563eb;
    font-family: Helvetica-Bold;
  }
```

## Orientation Support

Showdown supports both portrait and landscape orientations. Configure the orientation in your theme file:

### Portrait Mode (Default)
```yaml
layout:
  orientation: "portrait"
  slide_width: 612   # 8.5 inches
  slide_height: 792  # 11 inches
```

### Landscape Mode  
```yaml
layout:
  orientation: "landscape"
  slide_width: 792   # 11 inches  
  slide_height: 612  # 8.5 inches
```

When using landscape mode, the width and height are automatically swapped to provide the correct page dimensions. This is ideal for:
- Wide tables and charts
- Code snippets with long lines  
- Side-by-side content comparisons
- Dashboard-style layouts

## CLI Commands

### Convert
```bash
showdown convert presentation.md [options]
```

Options:
- `-o, --output` - Output PDF file path
- `-l, --layout` - Layout template file path  
- `-t, --theme` - Theme file path
- `-n, --notes` - Generate separate notes PDF
- `-v, --verbose` - Verbose output

### Initialize
```bash
showdown init
```

Creates sample presentation files including:
- `presentation.md` - Sample presentation
- `layouts/default.erb` - Default layout template
- `themes/default.yml` - Default theme

### Version
```bash
showdown version
```

## GitHub Flavored Markdown Support

Showdown supports all major GFM features:

- **Tables** - Pipe-separated tables with header rows
- **Code Highlighting** - Fenced code blocks with syntax highlighting  
- **Task Lists** - Interactive checkboxes (rendered as ✓/☐)
- **Strikethrough** - ~~crossed out text~~
- **Autolinks** - Automatic URL linking

## Examples

See the generated sample files after running `showdown init` for complete examples.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wernerpetrick/showdown. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
