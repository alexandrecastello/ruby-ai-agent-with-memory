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
end

