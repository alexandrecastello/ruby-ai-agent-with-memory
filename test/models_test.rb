require_relative '../lib/models/contact'
require_relative '../lib/models/interaction'

class ModelsTest
  def self.run
    puts "Testing Models (Contact and Interaction)"
    puts "=" * 50
    
    begin
      puts "\n1. Testing Contact model..."
      unique_email = "test_#{Time.now.to_i}@example.com"
      contact = Contact.new(
        name: 'Test Contact',
        email: unique_email,
        company: 'Test Company',
        status: 'new'
      )
      
      contact_id = contact.save
      
      if contact_id && contact_id > 0
        puts "  ✓ Contact saved successfully with ID: #{contact_id}"
        contact.id = contact_id
      else
        puts "  ✗ Failed to save contact"
        return false
      end
      
      puts "\n2. Testing Contact retrieval..."
      retrieved = Contact.find(contact_id)
      
      if retrieved && retrieved.name == 'Test Contact'
        puts "  ✓ Contact retrieved successfully"
        puts "    Name: #{retrieved.name}"
        puts "    Email: #{retrieved.email}"
        puts "    Status: #{retrieved.status}"
      else
        puts "  ✗ Failed to retrieve contact"
        return false
      end
      
      puts "\n3. Testing Contact.find_by_email..."
      found_by_email = Contact.find_by_email(unique_email)
      
      if found_by_email && found_by_email.id == contact_id
        puts "  ✓ Contact found by email successfully"
      else
        puts "  ✗ Failed to find contact by email"
        return false
      end
      
      puts "\n4. Testing Contact update..."
      contact.status = 'contacted'
      contact.save
      
      updated = Contact.find(contact_id)
      if updated && updated.status == 'contacted'
        puts "  ✓ Contact updated successfully"
      else
        puts "  ✗ Failed to update contact"
        return false
      end
      
      puts "\n5. Testing Interaction model..."
      interaction = Interaction.new(
        contact_id: contact_id,
        message: 'Hello, how are you?',
        response: 'I am doing well, thank you!',
        context_summary: 'Initial greeting exchange'
      )
      
      interaction_id = interaction.save
      
      if interaction_id && interaction_id > 0
        puts "  ✓ Interaction saved successfully with ID: #{interaction_id}"
        interaction.id = interaction_id
      else
        puts "  ✗ Failed to save interaction"
        return false
      end
      
      puts "\n6. Testing Interaction retrieval..."
      retrieved_interaction = Interaction.find(interaction_id)
      
      if retrieved_interaction && retrieved_interaction.message == 'Hello, how are you?'
        puts "  ✓ Interaction retrieved successfully"
        puts "    Message: #{retrieved_interaction.message}"
        puts "    Response: #{retrieved_interaction.response}"
      else
        puts "  ✗ Failed to retrieve interaction"
        return false
      end
      
      puts "\n7. Testing Interaction.find_by_contact..."
      contact_interactions = Interaction.find_by_contact(contact_id, limit: 5)
      
      if contact_interactions && contact_interactions.length > 0
        puts "  ✓ Found #{contact_interactions.length} interaction(s) for contact"
      else
        puts "  ✗ Failed to find interactions by contact"
        return false
      end
      
      puts "\n8. Testing contact.update_last_contact..."
      contact.update_last_contact
      updated_contact = Contact.find(contact_id)
      
      if updated_contact && updated_contact.last_contact_at
        puts "  ✓ Last contact time updated successfully"
        puts "    Last contact: #{updated_contact.last_contact_at}"
      else
        puts "  ✗ Failed to update last contact time"
        return false
      end
      
      puts "\n" + "=" * 50
      puts "✅ Models tests passed!"
      return true
      
    rescue => e
      puts "\n" + "=" * 50
      puts "✗ Models tests failed: #{e.message}"
      puts e.backtrace.first(5)
      return false
    end
  end
end

