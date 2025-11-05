require_relative '../config/database'

Database.setup

puts "Database schema created successfully!"
puts "Tables: contacts, interactions, knowledge_embeddings, context_summaries"

