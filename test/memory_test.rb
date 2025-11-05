require_relative '../lib/memory/short_term'
require_relative '../lib/memory/long_term'
require_relative '../lib/models/contact'
require_relative '../lib/models/interaction'

class MemoryTest
  def self.run
    puts "Testing Memory (Short-term and Long-term)"
    puts "=" * 50
    
    begin
      puts "\n1. Testing ShortTermMemory..."
      short_memory = ShortTermMemory.new
      
      puts "  ✓ ShortTermMemory initialized"
      
      puts "\n2. Testing ShortTermMemory.add_interaction..."
      5.times do |i|
        short_memory.add_interaction(
          "Message #{i + 1}",
          "Response #{i + 1}",
          { index: i }
        )
      end
      
      if short_memory.size == 5
        puts "  ✓ Added 5 interactions successfully"
      else
        puts "  ✗ Failed to add interactions (size: #{short_memory.size})"
        return false
      end
      
      puts "\n3. Testing ShortTermMemory.get_recent_context..."
      recent = short_memory.get_recent_context(limit: 3)
      
      if recent && recent.length == 3
        puts "  ✓ Retrieved recent context successfully (#{recent.length} interactions)"
      else
        puts "  ✗ Failed to retrieve recent context"
        return false
      end
      
      puts "\n4. Testing ShortTermMemory context management..."
      short_memory.set_current_context(:current_topic, 'Ruby programming')
      short_memory.update_context_summary('Testing memory functionality')
      
      context = short_memory.get_current_context
      if context[:current_topic] == 'Ruby programming'
        puts "  ✓ Context management working correctly"
      else
        puts "  ✗ Context management failed"
        return false
      end
      
      puts "\n5. Testing ShortTermMemory.clear..."
      short_memory.clear
      
      if short_memory.size == 0
        puts "  ✓ ShortTermMemory cleared successfully"
      else
        puts "  ✗ Failed to clear ShortTermMemory"
        return false
      end
      
      puts "\n6. Testing LongTermMemory..."
      long_memory = LongTermMemory.new
      
      puts "  ✓ LongTermMemory initialized"
      
      puts "\n7. Testing LongTermMemory with Contact..."
      test_contact = Contact.new(
        name: 'Memory Test Contact',
        email: 'memory@test.com',
        company: 'Memory Test Co',
        status: 'new'
      )
      
      contact_id = long_memory.save_contact(test_contact)
      
      if contact_id && contact_id > 0
        puts "  ✓ Contact saved via LongTermMemory"
      else
        puts "  ✗ Failed to save contact via LongTermMemory"
        return false
      end
      
      retrieved_contact = long_memory.find_contact(contact_id)
      if retrieved_contact && retrieved_contact.name == 'Memory Test Contact'
        puts "  ✓ Contact retrieved via LongTermMemory"
      else
        puts "  ✗ Failed to retrieve contact via LongTermMemory"
        return false
      end
      
      puts "\n8. Testing LongTermMemory with Interaction..."
      test_interaction = Interaction.new(
        contact_id: contact_id,
        message: 'Test message',
        response: 'Test response',
        context_summary: 'Memory test'
      )
      
      saved_interaction = long_memory.save_interaction(test_interaction)
      interaction_id = saved_interaction.id
      
      if interaction_id && interaction_id > 0
        puts "  ✓ Interaction saved via LongTermMemory"
      else
        puts "  ✗ Failed to save interaction via LongTermMemory"
        return false
      end
      
      puts "\n9. Testing LongTermMemory.get_contact_interactions..."
      interactions = long_memory.get_contact_interactions(contact_id)
      
      if interactions && interactions.length > 0
        puts "  ✓ Retrieved #{interactions.length} interaction(s) for contact"
      else
        puts "  ✗ Failed to retrieve contact interactions"
        return false
      end
      
      puts "\n10. Testing LongTermMemory.has_recent_interaction..."
      has_recent = long_memory.has_recent_interaction?(contact_id, hours: 24)
      
      if has_recent
        puts "  ✓ Recent interaction detected correctly"
      else
        puts "  ⚠ No recent interaction (may be expected)"
      end
      
      puts "\n11. Testing LongTermMemory.get_contact_history..."
      history = long_memory.get_contact_history(contact_id)
      
      if history && history[:contact] && history[:interactions]
        puts "  ✓ Contact history retrieved successfully"
        puts "    Contact: #{history[:contact].name}"
        puts "    Interactions: #{history[:interactions].length}"
      else
        puts "  ✗ Failed to retrieve contact history"
        return false
      end
      
      puts "\n12. Testing LongTermMemory.save_context_summary..."
      summary_id = long_memory.save_context_summary(contact_id, 'Test summary')
      
      if summary_id && summary_id > 0
        puts "  ✓ Context summary saved successfully"
        
        summaries = long_memory.get_context_summaries(contact_id)
        if summaries && summaries.length > 0
          puts "  ✓ Context summaries retrieved successfully"
        else
          puts "  ✗ Failed to retrieve context summaries"
          return false
        end
      else
        puts "  ✗ Failed to save context summary"
        return false
      end
      
      puts "\n" + "=" * 50
      puts "✅ Memory tests passed!"
      return true
      
    rescue => e
      puts "\n" + "=" * 50
      puts "✗ Memory tests failed: #{e.message}"
      puts e.backtrace.first(5)
      return false
    end
  end
end

