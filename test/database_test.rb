require_relative '../config/database'

class DatabaseTest
  def self.run
    puts "Testing Database Module"
    puts "=" * 50
    
    begin
      Database.setup
      db = Database.connection
      
      puts "\n1. Checking tables..."
      tables = db.execute("SELECT name FROM sqlite_master WHERE type='table'")
      table_names = tables.map { |t| t['name'] }
      expected_tables = ['contacts', 'interactions', 'knowledge_embeddings', 'context_summaries']
      
      expected_tables.each do |table|
        if table_names.include?(table)
          puts "  ✓ Table '#{table}' exists"
        else
          puts "  ✗ Table '#{table}' missing"
          return false
        end
      end
      
      puts "\n2. Testing contacts table..."
      contact_id = db.execute(
        "INSERT INTO contacts (name, email, company, status) VALUES (?, ?, ?, ?)",
        ["Test Contact", "test@example.com", "Test Company", "new"]
      )
      puts "  ✓ Contact inserted with ID: #{db.last_insert_row_id}"
      
      contact = db.execute("SELECT * FROM contacts WHERE id = ?", [db.last_insert_row_id]).first
      if contact && contact['name'] == "Test Contact"
        puts "  ✓ Contact retrieved successfully"
      else
        puts "  ✗ Failed to retrieve contact"
        return false
      end
      
      puts "\n3. Testing interactions table..."
      db.execute(
        "INSERT INTO interactions (contact_id, message, response) VALUES (?, ?, ?)",
        [contact['id'], "Hello", "Hi there!"]
      )
      puts "  ✓ Interaction inserted"
      
      interaction = db.execute("SELECT * FROM interactions WHERE contact_id = ?", [contact['id']]).first
      if interaction && interaction['message'] == "Hello"
        puts "  ✓ Interaction retrieved successfully"
      else
        puts "  ✗ Failed to retrieve interaction"
        return false
      end
      
      puts "\n4. Testing knowledge_embeddings table..."
      db.execute(
        "INSERT INTO knowledge_embeddings (content, embedding, metadata) VALUES (?, ?, ?)",
        ["Test content", "[0.1, 0.2, 0.3]", '{"type": "test"}']
      )
      puts "  ✓ Knowledge embedding inserted"
      
      embedding = db.execute("SELECT * FROM knowledge_embeddings WHERE content = ?", ["Test content"]).first
      if embedding && embedding['content'] == "Test content"
        puts "  ✓ Knowledge embedding retrieved successfully"
      else
        puts "  ✗ Failed to retrieve embedding"
        return false
      end
      
      puts "\n5. Verifying data counts..."
      contacts_count = db.execute("SELECT COUNT(*) as count FROM contacts").first['count']
      interactions_count = db.execute("SELECT COUNT(*) as count FROM interactions").first['count']
      embeddings_count = db.execute("SELECT COUNT(*) as count FROM knowledge_embeddings").first['count']
      
      puts "  Contacts: #{contacts_count}"
      puts "  Interactions: #{interactions_count}"
      puts "  Knowledge embeddings: #{embeddings_count}"
      
      puts "\n" + "=" * 50
      puts "✅ Database tests passed!"
      return true
      
    rescue => e
      puts "\n" + "=" * 50
      puts "✗ Database tests failed: #{e.message}"
      puts e.backtrace.first(5)
      return false
    end
  end
end

