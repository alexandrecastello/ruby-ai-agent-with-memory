require 'fileutils'

class StructureTest
  def self.run
    puts "Testing Project Structure"
    puts "=" * 50
    
    begin
      required_dirs = [
        'lib',
        'lib/memory',
        'lib/knowledge',
        'lib/models',
        'config',
        'db',
        'bin',
        'test'
      ]
      
      puts "\n1. Checking required directories..."
      required_dirs.each do |dir|
        if File.directory?(dir)
          puts "  ✓ Directory '#{dir}' exists"
        else
          puts "  ✗ Directory '#{dir}' missing"
          return false
        end
      end
      
      puts "\n2. Checking required files..."
      required_files = [
        'Gemfile',
        'README.md',
        'config/database.rb',
        'db/schema.rb',
        'bin/agent'
      ]
      
      optional_files = [
        'Dockerfile',
        'docker-compose.yml',
        '.gitignore'
      ]
      
      required_files.each do |file|
        if File.exist?(file)
          puts "  ✓ File '#{file}' exists"
        else
          puts "  ✗ File '#{file}' missing"
          return false
        end
      end
      
      puts "\n3. Checking optional files..."
      optional_files.each do |file|
        if File.exist?(file)
          puts "  ✓ File '#{file}' exists"
        else
          puts "  ⚠ File '#{file}' missing (optional)"
        end
      end
      
      puts "\n4. Checking database file..."
      db_path = ENV['DATABASE_PATH'] || 'db/agent.db'
      if File.exist?(db_path)
        puts "  ✓ Database file exists at '#{db_path}'"
      else
        puts "  ⚠ Database file not created yet (will be created on first run)"
      end
      
      puts "\n" + "=" * 50
      puts "✅ Structure tests passed!"
      return true
      
    rescue => e
      puts "\n" + "=" * 50
      puts "✗ Structure tests failed: #{e.message}"
      puts e.backtrace.first(5)
      return false
    end
  end
end

