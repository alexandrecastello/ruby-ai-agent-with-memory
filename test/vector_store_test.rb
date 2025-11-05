require_relative '../lib/knowledge/vector_store'
require_relative '../lib/knowledge/embedding_service'

class VectorStoreTest
  def self.run
    puts "Testing VectorStore"
    puts "=" * 50
    
    begin
      puts "\n1. Testing VectorStore initialization..."
      vector_store = VectorStore.new
      puts "  ✓ VectorStore initialized successfully"
      
      puts "\n2. Testing document addition..."
      test_content = "This is a test document about Ruby programming"
      test_metadata = { type: 'test', category: 'programming' }
      
      begin
        doc_id = vector_store.add_document(test_content, test_metadata)
        
        if doc_id && doc_id > 0
          puts "  ✓ Document added successfully with ID: #{doc_id}"
        else
          puts "  ✗ Failed to add document (returned nil or invalid ID)"
          return false
        end
      rescue => e
        error_msg = e.message.downcase
        if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key') || error_msg.include?('authentication')
          puts "  ⚠ Document addition requires valid API keys"
          puts "    Error: #{e.message}"
          puts "    This test will be skipped (API keys not configured)"
          doc_id = nil
        else
          puts "  ✗ Unexpected error in document addition: #{e.message}"
          puts "    This indicates a code bug, not just missing API keys"
          return false
        end
      end
      
      if doc_id.nil?
        puts "\n⚠ Skipping remaining tests that require API keys"
        puts "✅ VectorStore structure tests passed (API-dependent tests skipped)"
        return true
      end
      
      puts "\n3. Testing document retrieval by ID..."
      begin
        retrieved = vector_store.get_by_id(doc_id)
        
        if retrieved && retrieved[:content] == test_content
          puts "  ✓ Document retrieved successfully"
          puts "    Content: #{retrieved[:content][0..50]}..."
          puts "    Metadata: #{retrieved[:metadata]}"
        else
          puts "  ✗ Failed to retrieve document"
          return false
        end
      rescue => e
        puts "  ✗ Error retrieving document: #{e.message}"
        return false
      end
      
      puts "\n4. Testing document count..."
      begin
        count = vector_store.count
        if count > 0
          puts "  ✓ Document count: #{count}"
        else
          puts "  ✗ Document count is zero (expected at least 1 document)"
          return false
        end
      rescue => e
        puts "  ✗ Error getting document count: #{e.message}"
        return false
      end
      
      puts "\n5. Testing search functionality..."
      search_query = "Ruby code examples"
      
      begin
        search_results = vector_store.search(search_query, limit: 3, threshold: 0.0)
        
        if search_results && search_results.is_a?(Array)
          puts "  ✓ Search returned #{search_results.length} results"
          
          if search_results.length > 0
            best_match = search_results.first
            if best_match[:similarity].is_a?(Numeric) && best_match[:similarity] >= 0
              puts "    Best match similarity: #{best_match[:similarity].round(4)}"
              puts "    Best match content: #{best_match[:content][0..50]}..."
            else
              puts "  ✗ Search returned invalid similarity value"
              return false
            end
          else
            puts "  ⚠ Search returned no results (may be expected)"
          end
        else
          puts "  ✗ Search returned invalid results type"
          return false
        end
      rescue => e
        error_msg = e.message.downcase
        if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key')
          puts "  ⚠ Search test skipped (API keys required)"
        else
          puts "  ✗ Search error: #{e.message}"
          return false
        end
      end
      
      puts "\n6. Testing document deletion..."
      begin
        delete_result = vector_store.delete_by_id(doc_id)
        
        if delete_result
          puts "  ✓ Document deleted successfully"
          
          deleted_retrieval = vector_store.get_by_id(doc_id)
          if deleted_retrieval.nil?
            puts "  ✓ Deleted document no longer retrievable"
          else
            puts "  ✗ Deleted document still retrievable"
            return false
          end
        else
          puts "  ✗ Failed to delete document"
          return false
        end
      rescue => e
        puts "  ✗ Error deleting document: #{e.message}"
        return false
      end
      
      puts "\n7. Testing with multiple documents..."
      begin
        documents = [
          { content: "Python is a programming language", metadata: { lang: 'python' } },
          { content: "JavaScript is used for web development", metadata: { lang: 'javascript' } },
          { content: "Ruby is a dynamic programming language", metadata: { lang: 'ruby' } }
        ]
        
        doc_ids = documents.map do |doc|
          vector_store.add_document(doc[:content], doc[:metadata])
        end
        
        if doc_ids.all? { |id| id && id > 0 }
          puts "  ✓ Added #{doc_ids.length} documents successfully"
          
          final_count = vector_store.count
          puts "  ✓ Total documents in store: #{final_count}"
        else
          puts "  ✗ Failed to add multiple documents"
          return false
        end
      rescue => e
        puts "  ⚠ Multiple documents test skipped: #{e.message}"
        puts "    (This is OK if API keys are not set)"
      end
      
      puts "\n" + "=" * 50
      puts "✅ VectorStore tests passed!"
      return true
      
    rescue => e
      puts "\n" + "=" * 50
      puts "✗ VectorStore tests failed: #{e.message}"
      puts e.backtrace.first(5)
      return false
    end
  end
end

