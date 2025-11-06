require_relative '../../config/database'
require_relative '../models/contact'
require_relative '../models/interaction'

class LongTermMemory
  def initialize
    @db = Database.connection
  end

  def save_contact(contact)
    contact.save
  end

  def find_contact(id)
    Contact.find(id)
  end

  def find_contact_by_email(email)
    Contact.find_by_email(email)
  end

  def get_all_contacts
    Contact.all
  end

  def save_interaction(interaction)
    result = interaction.save
    if result && interaction.contact_id
      contact = find_contact(interaction.contact_id)
      contact&.update_last_contact
    end
    interaction
  end

  def get_contact_interactions(contact_id, limit: 10)
    Interaction.find_by_contact(contact_id, limit: limit)
  end

  def get_recent_interactions(limit: 10)
    Interaction.all.first(limit)
  end

  def save_context_summary(contact_id, summary)
    @db.execute(
      "INSERT INTO context_summaries (contact_id, summary) VALUES (?, ?)",
      [contact_id, summary]
    )
    @db.last_insert_row_id
  end

  def get_context_summaries(contact_id, limit: 5)
    results = @db.execute(
      "SELECT * FROM context_summaries WHERE contact_id = ? ORDER BY created_at DESC LIMIT ?",
      [contact_id, limit]
    )
    results.map { |row| row['summary'] }
  end

  def get_all_context_summaries(contact_id)
    results = @db.execute(
      "SELECT * FROM context_summaries WHERE contact_id = ? ORDER BY created_at DESC",
      [contact_id]
    )
    results.map { |row| row['summary'] }
  end

  def has_recent_interaction?(contact_id, hours: 24)
    result = @db.execute(
      "SELECT COUNT(*) as count FROM interactions WHERE contact_id = ? AND created_at > datetime('now', '-' || ? || ' hours')",
      [contact_id, hours]
    ).first
    
    result['count'] > 0
  end

  def get_contact_history(contact_id)
    contact = find_contact(contact_id)
    return nil unless contact
    
    {
      contact: contact,
      interactions: get_contact_interactions(contact_id),
      summaries: get_context_summaries(contact_id),
      has_recent_interaction: has_recent_interaction?(contact_id)
    }
  end

  def count_contact_interactions(contact_id)
    result = @db.execute(
      "SELECT COUNT(*) as count FROM interactions WHERE contact_id = ?",
      [contact_id]
    ).first
    
    result['count']
  end

  def get_old_interactions(contact_id, limit: 20)
    results = @db.execute(
      "SELECT * FROM interactions WHERE contact_id = ? ORDER BY created_at ASC LIMIT ?",
      [contact_id, limit]
    )
    results.map { |row| Interaction.new_from_hash(row) }
  end

  def archive_old_interactions(contact_id, summary_text)
    old_count = count_contact_interactions(contact_id)
    
    if old_count > 20
      interactions_to_keep = 10
      interactions_to_delete = old_count - interactions_to_keep
      
      if interactions_to_delete > 0
        old_interactions = @db.execute(
          "SELECT id FROM interactions WHERE contact_id = ? ORDER BY created_at ASC LIMIT ?",
          [contact_id, interactions_to_delete]
        )
        
        if old_interactions.length > 0
          old_interactions_ids = old_interactions.map { |row| row['id'] }
          
          # IMPORTANTE: Primeiro salvar o resumo, depois deletar as interações
          # Se houver erro ao salvar o resumo, não deletar as interações
          begin
            summary_id = save_context_summary(contact_id, summary_text)
            
            if summary_id && summary_id > 0
              # Resumo salvo com sucesso, agora podemos deletar as interações
              placeholders = old_interactions_ids.map { '?' }.join(',')
              @db.execute(
                "DELETE FROM interactions WHERE id IN (#{placeholders})",
                old_interactions_ids
              )
              
              return old_interactions.length
            else
              # Erro ao salvar resumo, não deletar interações
              raise "Failed to save summary"
            end
          rescue => e
            # Se houver erro, não deletar as interações
            raise "Error archiving interactions: #{e.message}. Interactions not deleted."
          end
        end
      end
    end
    
    0
  end
end

