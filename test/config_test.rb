class ConfigTest
  def self.run
    puts "Testing Configuration"
    puts "=" * 50
    
    begin
      puts "\n1. Checking environment variables..."
      
      openai_key = ENV['OPENAI_API_KEY']
      if openai_key && !openai_key.empty?
        puts "  ✓ OPENAI_API_KEY is set"
      else
        puts "  ⚠ OPENAI_API_KEY is not set"
      end
      
      gemini_key = ENV['GOOGLE_GEMINI_KEY']
      if gemini_key && !gemini_key.empty?
        puts "  ✓ GOOGLE_GEMINI_KEY is set"
      else
        puts "  ⚠ GOOGLE_GEMINI_KEY is not set"
      end
      
      provider = ENV['EMBEDDING_PROVIDER'] || 'openai'
      puts "  ✓ EMBEDDING_PROVIDER: #{provider}"
      
      db_path = ENV['DATABASE_PATH'] || 'db/agent.db'
      puts "  ✓ DATABASE_PATH: #{db_path}"
      
      puts "\n2. Checking required gems..."
      required_gems = {
        'sqlite3' => 'sqlite3',
        'ruby-openai' => 'ruby/openai',
        'faraday' => 'faraday',
        'json' => 'json',
        'colorize' => 'colorize',
        'tty-prompt' => 'tty/prompt',
        'dotenv' => 'dotenv'
      }
      
      all_loaded = true
      required_gems.each do |gem_name, require_name|
        begin
          require require_name
          puts "  ✓ Gem '#{gem_name}' loaded"
        rescue LoadError => e
          puts "  ✗ Gem '#{gem_name}' not found: #{e.message}"
          all_loaded = false
        end
      end
      
      return false unless all_loaded
      
      puts "\n" + "=" * 50
      puts "✅ Configuration tests passed!"
      return true
      
    rescue => e
      puts "\n" + "=" * 50
      puts "✗ Configuration tests failed: #{e.message}"
      puts e.backtrace.first(5)
      return false
    end
  end
end

