# Showdown Ruby Gem - Copilot Instructions

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

This is a Ruby gem project called Showdown that converts markdown presentations to PDF using Prawn.

## Architecture Guidelines

Follow Sandi Metz's Rules:
- Classes should be no longer than 100 lines
- Methods should be no longer than 5 lines  
- Pass no more than 4 parameters (including options hash)
- Favor composition over inheritance where appropriate

## Code Style
- Use snake_case for variables and methods, CamelCase for classes
- Prefer early returns and guard clauses to reduce nesting
- Favor `.each` and `.map` over `for` loops

## Project-Specific Guidelines

### Slide Delimiters
Use triple dash syntax for slide separation:
```markdown
---slide
# Slide content here

---notes  
Speaker notes for the slide
```

### Core Components
- **Parser**: Handles markdown parsing with custom slide delimiters
- **Layout**: ERB template system for PDF layouts
- **Renderer**: Prawn-based PDF generation
- **CLI**: Thor-based command line interface
- **Themes**: Basic theming system with CSS-like syntax

### Dependencies
- `prawn` - PDF generation
- `thor` - CLI framework
- `commonmarker` - GitHub Flavored Markdown parsing
- `rouge` - Syntax highlighting
- `erb` - Template rendering
- `front_matter_parser` - Frontmatter support

### Testing
- Use RSpec for testing
- Mock external dependencies
- Test CLI commands with Thor testing helpers
