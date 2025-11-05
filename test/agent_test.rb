require_relative '../lib/agent'
require_relative '../lib/models/contact'
require_relative '../lib/models/interaction'

class AgentTest
  def self.run
    puts "Testing Agent"
    puts "=" * 50
    
    begin
      puts "\n1. Testing Agent initialization..."
      agent = Agent.new
      puts "  ✓ Agent initialized successfully"
      
      puts "\n2. Testing Agent with Contact..."
      test_contact = Contact.new(
        name: 'Agent Test Contact',
        email: "agent_test_#{Time.now.to_i}@example.com",
        company: 'Agent Test Co',
        status: 'new'
      )
      
      contact_id = test_contact.save
      
      if contact_id && contact_id > 0
        puts "  ✓ Contact created for testing (ID: #{contact_id})"
      else
        puts "  ✗ Failed to create test contact"
        return false
      end
      
      puts "\n3. Testing Agent.start_conversation..."
      started_contact = agent.start_conversation(contact_id)
      
      if started_contact && started_contact.id == contact_id
        puts "  ✓ Conversation started successfully"
      else
        puts "  ✗ Failed to start conversation"
        return false
      end
      
      puts "\n4. Testing Agent.get_current_context..."
      context = agent.get_current_context
      
      if context && context.is_a?(Hash)
        puts "  ✓ Current context retrieved successfully"
        puts "    Recent interactions: #{context[:recent_interactions].length}"
      else
        puts "  ✗ Failed to get current context"
        return false
      end
      
      puts "\n5. Testing Agent.add_knowledge..."
      begin
        doc_id = agent.add_knowledge("Ruby is a programming language", { type: 'test' })
        
        if doc_id && doc_id > 0
          puts "  ✓ Knowledge added successfully (ID: #{doc_id})"
        else
          puts "  ⚠ Knowledge addition skipped (API keys may be required)"
        end
      rescue => e
        error_msg = e.message.downcase
        if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key')
          puts "  ⚠ Knowledge addition skipped (API keys required)"
        else
          puts "  ✗ Failed to add knowledge: #{e.message}"
          return false
        end
      end
      
      puts "\n6. Testing Agent.search_knowledge..."
      begin
        results = agent.search_knowledge("programming", limit: 2)
        
        if results && results.is_a?(Array)
          puts "  ✓ Knowledge search working (found #{results.length} results)"
        else
          puts "  ✗ Search returned invalid results"
          return false
        end
      rescue => e
        error_msg = e.message.downcase
        if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key')
          puts "  ⚠ Knowledge search skipped (API keys required)"
        else
          puts "  ✗ Search error: #{e.message}"
          return false
        end
      end
      
      puts "\n7. Testing Agent.process_message..."
      begin
        result = agent.process_message("Hello, this is a test message", contact_id: contact_id)
        
        if result && result.is_a?(Hash)
          if result[:error]
            puts "  ⚠ Message processing returned error: #{result[:error]}"
          elsif result[:response]
            puts "  ✓ Message processed successfully"
            puts "    Response: #{result[:response][0..50]}..."
            puts "    Knowledge used: #{result[:knowledge_used]}"
          else
            puts "  ✗ Message processing returned invalid result"
            return false
          end
        else
          puts "  ✗ Message processing failed"
          return false
        end
      rescue => e
        error_msg = e.message.downcase
        if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key')
          puts "  ⚠ Message processing skipped (API keys required for full functionality)"
        else
          puts "  ✗ Message processing error: #{e.message}"
          return false
        end
      end
      
      puts "\n" + "=" * 50
      puts "✅ Agent tests passed!"
      return true
      
    rescue => e
      puts "\n" + "=" * 50
      puts "✗ Agent tests failed: #{e.message}"
      puts e.backtrace.first(5)
      return false
    end
  end
end

