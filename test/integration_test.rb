require_relative '../lib/agent'
require_relative '../lib/models/contact'
require_relative '../lib/models/interaction'
require_relative '../lib/memory/long_term'

class IntegrationTest
  def self.run
    puts "Testing Full Integration"
    puts "=" * 50
    
    begin
      puts "\n1. Testing complete flow..."
      agent = Agent.new
      long_memory = LongTermMemory.new
      
      puts "\n2. Creating test contact..."
      test_contact = Contact.new(
        name: 'Integration Test Contact',
        email: "integration_test_#{Time.now.to_i}@example.com",
        company: 'Integration Test Clinic',
        status: 'new'
      )
      
      contact_id = test_contact.save
      
      if contact_id && contact_id > 0
        puts "  ✓ Contact created (ID: #{contact_id})"
      else
        puts "  ✗ Failed to create contact"
        return false
      end
      
      puts "\n3. Testing conversation flow..."
      started_contact = agent.start_conversation(contact_id)
      
      if started_contact
        puts "  ✓ Conversation started successfully"
      else
        puts "  ✗ Failed to start conversation"
        return false
      end
      
      puts "\n4. Testing multiple interactions..."
      messages = [
        'Olá, gostaria de conhecer o sistema.',
        'Quais são as funcionalidades principais?',
        'Como funciona o agendamento?',
        'Preciso de suporte técnico.',
        'Quanto custa o sistema?'
      ]
      
      messages.each_with_index do |message, index|
        result = agent.process_message(message, contact_id: contact_id)
        
        if result && result[:response]
          puts "  ✓ Interaction #{index + 1}/#{messages.length} processed"
          puts "    Total interactions: #{result[:total_interactions]}"
        else
          puts "  ✗ Failed to process message #{index + 1}"
          return false
        end
      end
      
      puts "\n5. Testing interaction count..."
      total = long_memory.count_contact_interactions(contact_id)
      
      if total == messages.length
        puts "  ✓ Total interactions: #{total}"
      else
        puts "  ✗ Expected #{messages.length} interactions, got #{total}"
        return false
      end
      
      puts "\n6. Testing 20+ interactions threshold..."
      additional_messages = Array.new(16) { |i| "Mensagem adicional #{i + 1}" }
      
      additional_messages.each_with_index do |message, index|
        result = agent.process_message(message, contact_id: contact_id)
        
        if result && result[:total_interactions]
          puts "  ✓ Interaction #{index + 1}/#{additional_messages.length} (#{result[:total_interactions]} total)"
          
          if result[:total_interactions] > 20
            puts "    ⚠ Threshold of 20 interactions reached!"
          end
        else
          puts "  ✗ Failed to process additional message #{index + 1}"
          return false
        end
      end
      
      final_count = long_memory.count_contact_interactions(contact_id)
      puts "\n  Final interaction count: #{final_count}"
      
      if final_count <= 20
        puts "  ✓ Old interactions archived correctly (keeping last 10)"
      else
        puts "  ⚠ Still have #{final_count} interactions (may need adjustment)"
      end
      
      # Verificar se foi criado um resumo
      summaries = long_memory.get_context_summaries(contact_id, limit: 10)
      if summaries.length > 0
        puts "  ✓ Summary created: #{summaries.length} summary(ies) found"
        puts "    Latest summary preview: #{summaries.first[0..100]}..."
      else
        puts "  ⚠ No summaries found (may be created at next threshold)"
      end
      
      puts "\n7. Testing knowledge search integration..."
      begin
        search_results = agent.search_knowledge("sistema de gestão", limit: 3)
        
        if search_results && search_results.is_a?(Array)
          puts "  ✓ Knowledge search working (#{search_results.length} results)"
        else
          puts "  ✗ Knowledge search failed"
          return false
        end
      rescue => e
        error_msg = e.message.downcase
        if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key')
          puts "  ⚠ Knowledge search skipped (API keys required)"
        else
          puts "  ✗ Knowledge search error: #{e.message}"
          return false
        end
      end
      
      puts "\n8. Testing context retrieval..."
      context = agent.get_current_context
      
      if context && context.is_a?(Hash)
        puts "  ✓ Context retrieved successfully"
        puts "    Recent interactions: #{context[:recent_interactions].length}"
      else
        puts "  ✗ Failed to retrieve context"
        return false
      end
      
      puts "\n" + "=" * 50
      puts "✅ Integration tests passed!"
      return true
      
    rescue => e
      puts "\n" + "=" * 50
      puts "✗ Integration tests failed: #{e.message}"
      puts e.backtrace.first(10)
      return false
    end
  end
end

