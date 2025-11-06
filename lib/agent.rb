require_relative 'memory/short_term'
require_relative 'memory/long_term'
require_relative 'knowledge/vector_store'
require_relative 'knowledge/embedding_service'
require_relative 'models/contact'
require_relative 'models/interaction'
require 'ruby/openai'
require 'colorize'

class Agent
  def initialize(embedding_provider: nil)
    @short_memory = ShortTermMemory.new
    @long_memory = LongTermMemory.new
    @vector_store = VectorStore.new(EmbeddingService.new(embedding_provider))
    @embedding_service = EmbeddingService.new(embedding_provider)
    @current_contact = nil
    @openai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY']) if ENV['OPENAI_API_KEY']
  end

  def start_conversation(contact_id)
    @current_contact = @long_memory.find_contact(contact_id)
    return nil unless @current_contact
    
    @short_memory.clear
    
    history = @long_memory.get_contact_history(contact_id)
    recent_interactions = history[:interactions].first(5)
    
    recent_interactions.each do |interaction|
      @short_memory.add_interaction(
        interaction.message,
        interaction.response,
        { timestamp: interaction.created_at }
      )
    end
    
    summaries = @long_memory.get_context_summaries(contact_id)
    if summaries.length > 0
      @short_memory.update_context_summary(summaries.first)
    end
    
    @current_contact
  end

  def process_message(message, contact_id: nil)
    contact_id ||= @current_contact&.id
    return { error: 'No contact selected' } unless contact_id
    
    @current_contact ||= @long_memory.find_contact(contact_id)
    
    context = build_context(message, contact_id)
    response = generate_response(message, context)
    
    interaction = Interaction.new(
      contact_id: contact_id,
      message: message,
      response: response,
      context_summary: context[:summary]
    )
    
    @long_memory.save_interaction(interaction)
    @short_memory.add_interaction(message, response, { contact_id: contact_id })
    
    total_interactions = @long_memory.count_contact_interactions(contact_id)
    
    if @short_memory.size >= 10
      summary = summarize_context
      @long_memory.save_context_summary(contact_id, summary)
      @short_memory.clear
    end
    
    if total_interactions > 20
      archived_count = archive_old_interactions(contact_id)
      if archived_count > 0
        puts "\n📦 Archived #{archived_count} old interactions (keeping last 10)".colorize(:yellow) if defined?(Colorize)
      end
    end
    
    {
      response: response,
      context_used: context[:sources].length,
      knowledge_used: context[:knowledge_found],
      total_interactions: total_interactions
    }
  end

  def add_knowledge(content, metadata = {})
    @vector_store.add_document(content, metadata)
  end

  def search_knowledge(query, limit: 3)
    @vector_store.search(query, limit: limit, threshold: 0.5)
  end

  def get_current_context
    @short_memory.get_full_context
  end

  private

  def build_context(message, contact_id)
    context_parts = []
    knowledge_sources = []
    
    history = @long_memory.get_contact_history(contact_id)
    
    recent_interactions = @short_memory.get_recent_context(limit: 3)
    recent_interactions.each do |interaction|
      context_parts << "Previous: #{interaction[:message]} -> #{interaction[:response]}"
    end
    
    if history[:summaries].length > 0
      context_parts << "Summary: #{history[:summaries].first}"
    end
    
    knowledge_results = @vector_store.search(message, limit: 3, threshold: 0.5)
    if knowledge_results.length > 0
      knowledge_sources = knowledge_results.map { |r| r[:content] }
      context_parts << "Knowledge: #{knowledge_sources.join(' | ')}"
    end
    
    contact_info = "Contact: #{@current_contact.name}"
    contact_info += " (#{@current_contact.company})" if @current_contact.company
    contact_info += " - Status: #{@current_contact.status}"
    context_parts.unshift(contact_info)
    
    {
      full_context: context_parts.join("\n"),
      sources: knowledge_sources,
      knowledge_found: knowledge_results.length > 0,
      summary: history[:summaries].first
    }
  end

  def generate_response(message, context)
    return "I'm sorry, but I cannot generate responses without an OpenAI API key." unless @openai_client
    
    prompt = build_prompt(message, context)
    
    begin
      response = @openai_client.chat(
        parameters: {
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: 'You are a helpful CRM assistant. You help manage customer relationships and follow-ups. Be professional, concise, and avoid repeating information that was already mentioned.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          temperature: 0.7,
          max_tokens: 500
        }
      )
      
      response.dig('choices', 0, 'message', 'content') || 'I apologize, but I could not generate a response.'
    rescue => e
      "I encountered an error: #{e.message}"
    end
  end

  def build_prompt(message, context)
    prompt = <<~PROMPT
      Context:
      #{context[:full_context]}
      
      Current message: #{message}
      
      Based on the context above, provide a helpful response. Avoid repeating information that was already mentioned in previous interactions.
    PROMPT
    
    prompt
  end

  def summarize_context
    context = @short_memory.get_full_context
    interactions = context[:recent_interactions]
    
    if interactions.length > 0
      summary = "Recent interactions: "
      summary += interactions.map { |i| "#{i[:message][0..50]}..." }.join('; ')
      summary
    else
      "No recent interactions to summarize."
    end
  end

  def archive_old_interactions(contact_id)
    total_count = @long_memory.count_contact_interactions(contact_id)
    
    return 0 if total_count <= 20
    
    interactions_to_keep = 10
    interactions_to_archive = total_count - interactions_to_keep
    
    if interactions_to_archive > 0
      # Buscar todas as interações antigas para sumarizar
      old_interactions = @long_memory.get_old_interactions(contact_id, limit: interactions_to_archive)
      
      if old_interactions.length > 0
        # Criar um resumo completo de todas as interações usando OpenAI
        summary_text = summarize_interactions(old_interactions)
        
        # Arquivar as interações antigas (primeiro salva o resumo, depois deleta)
        begin
          archived = @long_memory.archive_old_interactions(contact_id, summary_text)
          
          if archived > 0
            puts "\n📦 Arquivadas #{archived} interações antigas (mantendo últimas #{interactions_to_keep})".colorize(:yellow) if defined?(Colorize)
            puts "   Resumo criado e salvo com sucesso antes de deletar as interações".colorize(:green) if defined?(Colorize)
          end
          
          archived
        rescue => e
          puts "\n❌ Erro ao arquivar interações: #{e.message}".colorize(:red) if defined?(Colorize)
          puts "   As interações não foram deletadas para preservar os dados.".colorize(:yellow) if defined?(Colorize)
          0
        end
      else
        0
      end
    else
      0
    end
  end

  def summarize_interactions(interactions)
    return "Nenhuma interação para sumarizar." if interactions.empty?
    
    # Preparar o texto com todas as interações
    interactions_text = interactions.map.with_index do |interaction, index|
      "#{index + 1}. Usuário: #{interaction.message}\n   Agente: #{interaction.response}"
    end.join("\n\n")
    
    # Se não houver cliente OpenAI, criar um resumo simples
    unless @openai_client
      return "Resumo de #{interactions.length} interações: #{interactions.map { |i| i.message[0..50] }.join('; ')}"
    end
    
    # Usar OpenAI para criar um resumo inteligente
    begin
      prompt = <<~PROMPT
        Você precisa criar um resumo completo e conciso de todas as interações abaixo.
        O resumo deve capturar os pontos principais, temas discutidos, decisões tomadas e contexto importante.
        Seja claro e objetivo, mantendo as informações mais relevantes.
        
        Interações:
        #{interactions_text}
        
        Resumo:
      PROMPT
      
      response = @openai_client.chat(
        parameters: {
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: 'Você é um assistente especializado em criar resumos concisos e informativos de conversas.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          temperature: 0.3,
          max_tokens: 500
        }
      )
      
      summary = response.dig('choices', 0, 'message', 'content') || "Resumo de #{interactions.length} interações arquivadas."
      
      # Adicionar metadados ao resumo
      "📋 Resumo de #{interactions.length} interações arquivadas:\n#{summary}"
      
    rescue => e
      # Em caso de erro, criar um resumo simples
      "📋 Resumo de #{interactions.length} interações arquivadas: #{interactions.map { |i| i.message[0..50] }.join('; ')}"
    end
  end
end

