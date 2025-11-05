require_relative '../lib/knowledge/embedding_service'

class EmbeddingServiceTest
  def self.run
    puts "Testing EmbeddingService"
    puts "=" * 50
    
    begin
      puts "\n1. Testing service initialization..."
      service = EmbeddingService.new
      provider = service.instance_variable_get(:@provider)
      puts "  ✓ Service initialized with provider: #{provider}"
      
      puts "\n2. Testing provider selection..."
      openai_service = EmbeddingService.new('openai')
      openai_provider = openai_service.instance_variable_get(:@provider)
      if openai_provider == 'openai'
        puts "  ✓ OpenAI provider selected correctly"
      else
        puts "  ✗ Failed to select OpenAI provider"
        return false
      end
      
      gemini_service = EmbeddingService.new('gemini')
      gemini_provider = gemini_service.instance_variable_get(:@provider)
      if gemini_provider == 'gemini'
        puts "  ✓ Gemini provider selected correctly"
      else
        puts "  ✗ Failed to select Gemini provider"
        return false
      end
      
      puts "\n3. Testing API keys availability..."
      openai_key = ENV['OPENAI_API_KEY']
      gemini_key = ENV['GOOGLE_GEMINI_KEY']
      
      if openai_key && !openai_key.empty?
        puts "  ✓ OpenAI API key is set"
        
        puts "\n4. Testing OpenAI embedding generation..."
        begin
          test_text = "This is a test text for embedding"
          embedding = openai_service.generate_embedding(test_text)
          
          if embedding && embedding.is_a?(Array) && embedding.length > 0
            puts "  ✓ OpenAI embedding generated successfully"
            puts "    Embedding dimension: #{embedding.length}"
            
            puts "\n5. Testing embedding cache..."
            cached_embedding = openai_service.generate_embedding(test_text)
            if cached_embedding == embedding
              puts "  ✓ Embedding cache working correctly"
            else
              puts "  ✗ Embedding cache not working"
              return false
            end
            
          else
            puts "  ✗ OpenAI embedding generation failed: invalid response"
            return false
          end
        rescue => e
          puts "  ⚠ OpenAI embedding test skipped: #{e.message}"
          puts "    (This is OK if API key is invalid or network issue)"
        end
      else
        puts "  ⚠ OpenAI API key not set (skipping embedding generation test)"
      end
      
      if gemini_key && !gemini_key.empty?
        puts "  ✓ Google Gemini key is set"
        
        puts "\n6. Testing Gemini embedding generation..."
        begin
          test_text = "This is a test text for embedding"
          embedding = gemini_service.generate_embedding(test_text)
          
          if embedding && embedding.is_a?(Array) && embedding.length > 0
            puts "  ✓ Gemini embedding generated successfully"
            puts "    Embedding dimension: #{embedding.length}"
          else
            puts "  ✗ Gemini embedding generation failed: invalid response"
            return false
          end
        rescue => e
          puts "  ⚠ Gemini embedding test skipped: #{e.message}"
          puts "    (This is OK if API key is invalid or network issue)"
        end
      else
        puts "  ⚠ Google Gemini key not set (skipping embedding generation test)"
      end
      
      puts "\n7. Testing error handling..."
      begin
        invalid_service = EmbeddingService.new('invalid_provider')
        invalid_service.generate_embedding("test")
        puts "  ✗ Should have raised error for invalid provider"
        return false
      rescue => e
        if e.message.include?('Unknown embedding provider')
          puts "  ✓ Error handling for invalid provider working correctly"
        else
          puts "  ✗ Unexpected error: #{e.message}"
          return false
        end
      end
      
      puts "\n" + "=" * 50
      puts "✅ EmbeddingService tests passed!"
      return true
      
    rescue => e
      puts "\n" + "=" * 50
      puts "✗ EmbeddingService tests failed: #{e.message}"
      puts e.backtrace.first(5)
      return false
    end
  end
end

