RSpec.describe Showdown do
  it "has a version number" do
    expect(Showdown::VERSION).not_to be nil
  end

  it "can convert a simple presentation" do
    # Create a temporary markdown file
    content = <<~MARKDOWN
      ---
      title: "Test Presentation"
      author: "Test Author"
      ---
      
      ---slide
      # Hello World
      
      This is a test slide.
      
      ---slide
      ## Second Slide
      
      With more content.
    MARKDOWN
    
    temp_file = 'test_presentation.md'
    File.write(temp_file, content)
    
    begin
      result = Showdown.convert(temp_file)
      expect(result).to be_a(Hash)
      expect(result[:pdf]).not_to be_nil
    ensure
      File.delete(temp_file) if File.exist?(temp_file)
    end
  end
end
