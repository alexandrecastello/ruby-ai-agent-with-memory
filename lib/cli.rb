require 'tty-prompt'
require 'colorize'
require_relative 'agent'
require_relative 'models/contact'
require_relative 'memory/long_term'

class CLI
  def initialize
    @agent = Agent.new
    @prompt = TTY::Prompt.new
    @long_memory = LongTermMemory.new
  end

  def start
    puts "\n🤖 Agente CRM com Memória e Embeddings".colorize(:cyan).bold
    puts "=" * 60
    puts ""
    
    loop do
      choice = main_menu
      
      case choice
      when 'add_contact'
        add_contact
      when 'list_contacts'
        list_contacts
      when 'start_conversation'
        start_conversation
      when 'add_knowledge'
        add_knowledge
      when 'search_knowledge'
        search_knowledge
      when 'view_memory'
        view_memory
      when 'exit'
        puts "\n👋 Até logo!".colorize(:cyan)
        break
      end
    end
  end

  private

  def main_menu
    @prompt.select("\n📋 Menu Principal".colorize(:yellow).bold, [
      { name: '➕ Adicionar Contato', value: 'add_contact' },
      { name: '📇 Listar Contatos', value: 'list_contacts' },
      { name: '💬 Iniciar Conversa', value: 'start_conversation' },
      { name: '📚 Adicionar Conhecimento', value: 'add_knowledge' },
      { name: '🔍 Buscar Conhecimento', value: 'search_knowledge' },
      { name: '🧠 Visualizar Memória', value: 'view_memory' },
      { name: '❌ Sair', value: 'exit' }
    ])
  end

  def add_contact
    puts "\n➕ Adicionar Novo Contato".colorize(:cyan).bold
    puts "-" * 60
    
    name = @prompt.ask('Nome:', required: true)
    email = @prompt.ask('Email:') { |q| q.validate(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, 'Email inválido') }
    company = @prompt.ask('Empresa:')
    status = @prompt.select('Status:', ['new', 'contacted', 'qualified', 'converted', 'lost'])
    
    contact = Contact.new(
      name: name,
      email: email,
      company: company,
      status: status
    )
    
    contact_id = @long_memory.save_contact(contact)
    
    if contact_id
      puts "\n✅ Contato adicionado com sucesso! ID: #{contact_id}".colorize(:green)
    else
      puts "\n❌ Erro ao adicionar contato.".colorize(:red)
    end
  end

  def list_contacts
    puts "\n📇 Lista de Contatos".colorize(:cyan).bold
    puts "-" * 60
    
    contacts = @long_memory.get_all_contacts
    
    if contacts.empty?
      puts "Nenhum contato encontrado.".colorize(:yellow)
      return
    end
    
    contacts.each do |contact|
      puts "\n#{contact.id}. #{contact.name}".colorize(:green)
      puts "   Email: #{contact.email}" if contact.email
      puts "   Empresa: #{contact.company}" if contact.company
      puts "   Status: #{contact.status}"
      puts "   Último contato: #{contact.last_contact_at || 'Nunca'}"
    end
  end

  def start_conversation
    contacts = @long_memory.get_all_contacts
    
    if contacts.empty?
      puts "\n⚠️  Nenhum contato encontrado. Adicione um contato primeiro.".colorize(:yellow)
      return
    end
    
    contact_options = contacts.map { |c| { name: "#{c.name} (#{c.email})", value: c.id } }
    contact_id = @prompt.select('Selecione um contato:', contact_options)
    
    contact = @agent.start_conversation(contact_id)
    
    if contact
      puts "\n💬 Conversa iniciada com #{contact.name}".colorize(:green)
      puts "-" * 60
      
      conversation_loop(contact_id)
    else
      puts "\n❌ Erro ao iniciar conversa.".colorize(:red)
    end
  end

  def conversation_loop(contact_id)
    loop do
      puts "\n" + "─" * 60
      message = @prompt.ask('Você: ', required: true)
      
      if message.downcase == 'sair' || message.downcase == 'exit'
        puts "\n👋 Encerrando conversa...".colorize(:cyan)
        break
      end
      
      puts "\n🤖 Processando...".colorize(:yellow)
      
      result = @agent.process_message(message, contact_id: contact_id)
      
      if result[:error]
        puts "\n❌ #{result[:error]}".colorize(:red)
        break
      end
      
      puts "\n🤖 Agente: #{result[:response]}".colorize(:cyan)
      
      if result[:knowledge_used]
        puts "   (Usando conhecimento do banco vetorial)".colorize(:green)
      end
      
      if result[:context_used] > 0
        puts "   (#{result[:context_used]} fonte(s) de contexto utilizada(s))".colorize(:blue)
      end
    end
  end

  def add_knowledge
    puts "\n📚 Adicionar Conhecimento ao Banco Vetorial".colorize(:cyan).bold
    puts "-" * 60
    
    content = @prompt.multiline('Conteúdo (pressione Ctrl+D quando terminar):', default: '')
    type = @prompt.select('Tipo:', ['documentation', 'faq', 'policy', 'example', 'other'])
    category = @prompt.ask('Categoria:')
    
    metadata = {
      type: type,
      category: category,
      added_at: Time.now.to_s
    }
    
    begin
      doc_id = @agent.add_knowledge(content.join("\n"), metadata)
      
      if doc_id
        puts "\n✅ Conhecimento adicionado com sucesso! ID: #{doc_id}".colorize(:green)
      else
        puts "\n❌ Erro ao adicionar conhecimento.".colorize(:red)
      end
    rescue => e
      puts "\n❌ Erro: #{e.message}".colorize(:red)
    end
  end

  def search_knowledge
    puts "\n🔍 Buscar no Conhecimento".colorize(:cyan).bold
    puts "-" * 60
    
    query = @prompt.ask('Digite sua busca:', required: true)
    limit = @prompt.ask('Quantos resultados?', default: '3').to_i
    
    begin
      results = @agent.search_knowledge(query, limit: limit)
      
      if results.empty?
        puts "\n⚠️  Nenhum resultado encontrado.".colorize(:yellow)
        return
      end
      
      puts "\n📊 Resultados encontrados:".colorize(:green)
      results.each_with_index do |result, index|
        puts "\n#{index + 1}. Similaridade: #{(result[:similarity] * 100).round(2)}%".colorize(:cyan)
        puts "   #{result[:content][0..200]}..."
        puts "   Metadata: #{result[:metadata]}" if result[:metadata]
      end
    rescue => e
      puts "\n❌ Erro: #{e.message}".colorize(:red)
    end
  end

  def view_memory
    puts "\n🧠 Estado da Memória".colorize(:cyan).bold
    puts "-" * 60
    
    context = @agent.get_current_context
    
    puts "\n📝 Memória de Curto Prazo:".colorize(:yellow)
    puts "   Interações recentes: #{context[:recent_interactions].length}"
    
    if context[:recent_interactions].length > 0
      puts "\n   Últimas interações:"
      context[:recent_interactions].last(3).each_with_index do |interaction, index|
        puts "   #{index + 1}. #{interaction[:message][0..50]}..."
      end
    end
    
    puts "\n📊 Contexto Atual:".colorize(:yellow)
    context[:current_context].each do |key, value|
      puts "   #{key}: #{value}"
    end
    
    if context[:summary]
      puts "\n📄 Resumo:".colorize(:yellow)
      puts "   #{context[:summary]}"
    end
  end
end

