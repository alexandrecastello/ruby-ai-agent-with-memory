require 'colorize'

class TestRunner
  def self.run_all
    puts "\n" + "🧪 Running All Tests".colorize(:cyan).bold
    puts "=" * 60
    puts ""
    
    tests = [
      { name: 'Structure', class_name: 'StructureTest', file: 'structure_test' },
      { name: 'Config', class_name: 'ConfigTest', file: 'config_test' },
      { name: 'Database', class_name: 'DatabaseTest', file: 'database_test' },
      { name: 'EmbeddingService', class_name: 'EmbeddingServiceTest', file: 'embedding_service_test' },
      { name: 'VectorStore', class_name: 'VectorStoreTest', file: 'vector_store_test' },
      { name: 'Models', class_name: 'ModelsTest', file: 'models_test' },
      { name: 'Memory', class_name: 'MemoryTest', file: 'memory_test' },
      { name: 'Agent', class_name: 'AgentTest', file: 'agent_test' },
      { name: 'Integration', class_name: 'IntegrationTest', file: 'integration_test' }
    ]
    
    results = []
    missing_api_keys = []
    
    tests.each do |test|
      begin
        require_relative test[:file]
        test_class = Object.const_get(test[:class_name])
        
        puts "\n"
        result = test_class.run
        results << { name: test[:name], passed: result }
        
      rescue => e
        puts "\n✗ Failed to run #{test[:name]} test: #{e.message}".colorize(:red)
        puts "  #{e.backtrace.first}".colorize(:red) if e.backtrace
        results << { name: test[:name], passed: false }
      end
    end
    
    puts "\n" + "=" * 60
    puts "\n📊 Test Summary".colorize(:cyan).bold
    puts "-" * 60
    
    passed = 0
    failed = 0
    
    results.each do |result|
      if result[:passed]
        puts "  ✅ #{result[:name]}".colorize(:green)
        passed += 1
      else
        puts "  ❌ #{result[:name]}".colorize(:red)
        failed += 1
      end
    end
    
    puts "-" * 60
    puts "  Total: #{results.length} tests"
    puts "  Passed: #{passed}".colorize(:green)
    puts "  Failed: #{failed}".colorize(:red)
    
    missing_api_keys = check_missing_api_keys
    
    if missing_api_keys.length > 0
      puts "\n🔑 Missing API Keys:".colorize(:yellow).bold
      puts "-" * 60
      missing_api_keys.each do |key|
        puts "  ⚠ #{key}".colorize(:yellow)
      end
      puts "-" * 60
      puts "  Note: Some tests were skipped due to missing API keys.".colorize(:yellow)
      puts "  To enable full testing, set these keys in your .env file.".colorize(:yellow)
    end
    
    puts ""
    
    if failed == 0
      if missing_api_keys.length > 0
        puts "✅ All tests passed (some features require API keys)".colorize(:green).bold
      else
        puts "🎉 All tests passed!".colorize(:green).bold
      end
      exit 0
    else
      puts "⚠️  Some tests failed!".colorize(:red).bold
      exit 1
    end
  end
  
  def self.check_missing_api_keys
    missing = []
    
    openai_key = ENV['OPENAI_API_KEY']
    if !openai_key || openai_key.empty?
      missing << 'OPENAI_API_KEY'
    end
    
    gemini_key = ENV['GOOGLE_GEMINI_KEY']
    if !gemini_key || gemini_key.empty?
      missing << 'GOOGLE_GEMINI_KEY'
    end
    
    missing
  end
end

if __FILE__ == $0
  TestRunner.run_all
end

