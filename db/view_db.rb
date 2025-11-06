require_relative '../config/database'
require_relative '../lib/models/contact'
require_relative '../lib/models/interaction'
require 'json'
require 'colorize'

Database.setup
db = Database.connection

puts "\n📊 Visualização do Banco de Dados".colorize(:cyan).bold
puts "=" * 80

puts "\n📇 CONTATOS".colorize(:yellow).bold
puts "-" * 80
contacts = Contact.all.reject { |c| c.name == 'Test Contact' || c.name == 'Memory Test Contact' || c.name == 'Agent Test Contact' }
if contacts.empty?
  puts "  Nenhum contato encontrado.".colorize(:red)
else
  contacts.each do |contact|
    puts "\n  ID: #{contact.id}".colorize(:green)
    puts "  Nome: #{contact.name}"
    puts "  Email: #{contact.email}"
    puts "  Clínica: #{contact.company}"
    puts "  Status: #{contact.status}"
    puts "  Último contato: #{contact.last_contact_at || 'Nunca'}"
    puts "  Criado em: #{contact.created_at}"
  end
  puts "\n  Total: #{contacts.length} contato(s)"
  puts "  (Mostrando apenas contatos reais, excluindo dados de teste)"
end

puts "\n💬 INTERAÇÕES".colorize(:yellow).bold
puts "-" * 80
interactions = Interaction.all.reject { |i| i.contact && (i.contact.name == 'Test Contact' || i.contact.name == 'Memory Test Contact' || i.contact.name == 'Agent Test Contact') }
if interactions.empty?
  puts "  Nenhuma interação encontrada.".colorize(:red)
else
  interactions.first(10).each do |interaction|
    contact = interaction.contact
    puts "\n  ID: #{interaction.id}".colorize(:green)
    puts "  Contato: #{contact ? contact.name : "ID #{interaction.contact_id}"}"
    puts "  Mensagem: #{interaction.message[0..60]}..."
    puts "  Resposta: #{interaction.response ? interaction.response[0..60] + '...' : 'N/A'}"
    puts "  Resumo: #{interaction.context_summary || 'N/A'}"
    puts "  Criado em: #{interaction.created_at}"
  end
  puts "\n  Total: #{interactions.length} interação(ões)"
  puts "  (Mostrando as 10 mais recentes)"
end

puts "\n📚 CONHECIMENTO (Banco Vetorial)".colorize(:yellow).bold
puts "-" * 80
knowledge_count = db.execute("SELECT COUNT(*) as count FROM knowledge_embeddings").first['count']
if knowledge_count == 0
  puts "  Nenhum documento de conhecimento encontrado.".colorize(:red)
else
  knowledge = db.execute("SELECT id, content, metadata FROM knowledge_embeddings ORDER BY created_at DESC LIMIT 10")
  knowledge.each do |doc|
    puts "\n  ID: #{doc['id']}".colorize(:green)
    puts "  Conteúdo: #{doc['content'][0..80]}..."
    if doc['metadata']
      begin
        metadata = JSON.parse(doc['metadata'])
        puts "  Tipo: #{metadata['type'] || 'N/A'}"
        puts "  Categoria: #{metadata['category'] || 'N/A'}"
      rescue
        puts "  Metadata: #{doc['metadata']}"
      end
    end
  end
  puts "\n  Total: #{knowledge_count} documento(s)"
  puts "  (Mostrando os 10 mais recentes)"
end

puts "\n📝 RESUMOS DE CONTEXTO".colorize(:yellow).bold
puts "-" * 80
summaries = db.execute("SELECT id, contact_id, summary, created_at FROM context_summaries ORDER BY created_at DESC LIMIT 5")
if summaries.empty?
  puts "  Nenhum resumo encontrado.".colorize(:red)
else
  summaries.each do |summary|
    contact = Contact.find(summary['contact_id'])
    puts "\n  ID: #{summary['id']}".colorize(:green)
    puts "  Contato: #{contact ? contact.name : "ID #{summary['contact_id']}"}"
    puts "  Resumo: #{summary['summary'][0..100]}..."
    puts "  Criado em: #{summary['created_at']}"
  end
  puts "\n  Total: #{summaries.length} resumo(s) (mostrando os 5 mais recentes)"
end

puts "\n" + "=" * 80
puts "✅ Visualização concluída!".colorize(:green).bold
puts ""

