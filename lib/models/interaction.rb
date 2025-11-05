require_relative '../../config/database'
require_relative 'contact'

class Interaction
  attr_accessor :id, :contact_id, :message, :response, :context_summary, :created_at

  def initialize(attributes = {})
    @id = attributes[:id]
    @contact_id = attributes[:contact_id]
    @message = attributes[:message]
    @response = attributes[:response]
    @context_summary = attributes[:context_summary]
    @created_at = attributes[:created_at]
  end

  def save
    db = Database.connection
    
    if @id
      db.execute(
        "UPDATE interactions SET contact_id = ?, message = ?, response = ?, context_summary = ? WHERE id = ?",
        [@contact_id, @message, @response, @context_summary, @id]
      )
      @id
    else
      db.execute(
        "INSERT INTO interactions (contact_id, message, response, context_summary) VALUES (?, ?, ?, ?)",
        [@contact_id, @message, @response, @context_summary]
      )
      @id = db.last_insert_row_id
    end
  end

  def self.find(id)
    db = Database.connection
    result = db.execute("SELECT * FROM interactions WHERE id = ?", [id]).first
    return nil unless result
    
    new_from_hash(result)
  end

  def self.find_by_contact(contact_id, limit: 10)
    db = Database.connection
    results = db.execute(
      "SELECT * FROM interactions WHERE contact_id = ? ORDER BY created_at DESC LIMIT ?",
      [contact_id, limit]
    )
    results.map { |row| new_from_hash(row) }
  end

  def self.all
    db = Database.connection
    results = db.execute("SELECT * FROM interactions ORDER BY created_at DESC")
    results.map { |row| new_from_hash(row) }
  end

  def contact
    @contact ||= Contact.find(@contact_id) if @contact_id
  end

  private

  def self.new_from_hash(hash)
    new(
      id: hash['id'],
      contact_id: hash['contact_id'],
      message: hash['message'],
      response: hash['response'],
      context_summary: hash['context_summary'],
      created_at: hash['created_at'] ? Time.parse(hash['created_at']) : nil
    )
  end
end

