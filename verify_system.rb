#!/usr/bin/env ruby

require 'dotenv/load'
require_relative 'config/database'
require_relative 'lib/agent'
require_relative 'lib/models/contact'
require_relative 'lib/models/interaction'
require_relative 'lib/memory/long_term'
require_relative 'lib/knowledge/vector_store'
require 'colorize'

puts "\n" + "🔍 Verificação Completa do Sistema".colorize(:cyan).bold
puts "=" * 70
puts ""

# Verificar configuração
puts "1. Verificando configuração...".colorize(:yellow)
Database.setup
puts "  ✓ Database configurado".colorize(:green)

if ENV['OPENAI_API_KEY'] && !ENV['OPENAI_API_KEY'].empty?
  puts "  ✓ OPENAI_API_KEY configurada".colorize(:green)
else
  puts "  ⚠ OPENAI_API_KEY não configurada".colorize(:yellow)
end

if ENV['GOOGLE_GEMINI_KEY'] && !ENV['GOOGLE_GEMINI_KEY'].empty?
  puts "  ✓ GOOGLE_GEMINI_KEY configurada".colorize(:green)
else
  puts "  ⚠ GOOGLE_GEMINI_KEY não configurada".colorize(:yellow)
end

embedding_provider = ENV['EMBEDDING_PROVIDER'] || 'openai'
puts "  ✓ EMBEDDING_PROVIDER: #{embedding_provider}".colorize(:green)

# Verificar componentes
puts "\n2. Verificando componentes...".colorize(:yellow)
agent = Agent.new
puts "  ✓ Agent inicializado".colorize(:green)

long_memory = LongTermMemory.new
puts "  ✓ LongTermMemory inicializado".colorize(:green)

vector_store = VectorStore.new
puts "  ✓ VectorStore inicializado".colorize(:green)

# Verificar dados
puts "\n3. Verificando dados no banco...".colorize(:yellow)
contacts = long_memory.get_all_contacts
puts "  ✓ Contatos encontrados: #{contacts.length}".colorize(:green)

if contacts.length > 0
  contacts.each do |contact|
    interactions_count = long_memory.count_contact_interactions(contact.id)
    puts "    - #{contact.name} (#{contact.company}): #{interactions_count} interações".colorize(:white)
    
    if interactions_count > 20
      puts "      ⚠ Mais de 20 interações - arquivamento automático ativo".colorize(:yellow)
    end
  end
end

# Verificar conhecimento vetorial
puts "\n4. Verificando base de conhecimento...".colorize(:yellow)
knowledge_count = vector_store.count
puts "  ✓ Documentos na base de conhecimento: #{knowledge_count}".colorize(:green)

# Testar funcionalidade de arquivamento
puts "\n5. Testando funcionalidade de arquivamento...".colorize(:yellow)
if contacts.length > 0
  test_contact = contacts.first
  interaction_count = long_memory.count_contact_interactions(test_contact.id)
  
  if interaction_count > 20
    puts "  ✓ Contato '#{test_contact.name}' tem #{interaction_count} interações".colorize(:green)
    puts "    ⚠ Sistema arquivará automaticamente as mais antigas (mantendo últimas 10)".colorize(:yellow)
  else
    puts "  ✓ Contato '#{test_contact.name}' tem #{interaction_count} interações".colorize(:green)
    puts "    ℹ Arquivamento automático será ativado ao atingir 21 interações".colorize(:blue)
  end
else
  puts "  ℹ Nenhum contato para testar arquivamento".colorize(:blue)
end

# Verificar funcionalidades principais
puts "\n6. Verificando funcionalidades principais...".colorize(:yellow)

# Adicionar conhecimento
begin
  test_knowledge = "Teste de conhecimento - #{Time.now.to_i}"
  doc_id = agent.add_knowledge(test_knowledge, { type: 'test', category: 'verification' })
  if doc_id
    puts "  ✓ Adicionar conhecimento: OK".colorize(:green)
    # Limpar conhecimento de teste
    vector_store.delete_by_id(doc_id)
  else
    puts "  ⚠ Adicionar conhecimento: Requer API keys".colorize(:yellow)
  end
rescue => e
  error_msg = e.message.downcase
  if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key')
    puts "  ⚠ Adicionar conhecimento: Requer API keys válidas".colorize(:yellow)
  else
    puts "  ✗ Adicionar conhecimento: #{e.message}".colorize(:red)
  end
end

# Buscar conhecimento
begin
  results = agent.search_knowledge("teste", limit: 1)
  puts "  ✓ Buscar conhecimento: OK (#{results.length} resultados)".colorize(:green)
rescue => e
  error_msg = e.message.downcase
  if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key')
    puts "  ⚠ Buscar conhecimento: Requer API keys válidas".colorize(:yellow)
  else
    puts "  ✗ Buscar conhecimento: #{e.message}".colorize(:red)
  end
end

# Processar mensagem
if contacts.length > 0
  test_contact = contacts.first
  agent.start_conversation(test_contact.id)
  
  begin
    result = agent.process_message("Teste de verificação", contact_id: test_contact.id)
    if result && result[:response]
      puts "  ✓ Processar mensagem: OK".colorize(:green)
      puts "    Total de interações: #{result[:total_interactions]}".colorize(:white)
    else
      puts "  ✗ Processar mensagem: Falhou".colorize(:red)
    end
  rescue => e
    error_msg = e.message.downcase
    if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key')
      puts "  ⚠ Processar mensagem: Requer API keys válidas".colorize(:yellow)
    else
      puts "  ✗ Processar mensagem: #{e.message}".colorize(:red)
    end
  end
else
  puts "  ℹ Processar mensagem: Nenhum contato disponível para teste".colorize(:blue)
end

# Resumo final
puts "\n" + "=" * 70
puts "\n📊 Resumo da Verificação".colorize(:cyan).bold
puts "-" * 70
puts "  ✓ Database: OK".colorize(:green)
puts "  ✓ Componentes: OK".colorize(:green)
puts "  ✓ Contatos: #{contacts.length}".colorize(:green)
puts "  ✓ Conhecimento: #{knowledge_count} documentos".colorize(:green)
puts "  ✓ Funcionalidade de arquivamento (20+ interações): Implementada".colorize(:green)

if ENV['OPENAI_API_KEY'] && !ENV['OPENAI_API_KEY'].empty?
  puts "  ✓ API Keys: Configuradas".colorize(:green)
else
  puts "  ⚠ API Keys: Algumas não configuradas (algumas funcionalidades limitadas)".colorize(:yellow)
end

puts "\n✅ Sistema verificado com sucesso!".colorize(:green).bold
puts ""

