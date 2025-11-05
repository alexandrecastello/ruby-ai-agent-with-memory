require_relative 'base_model'
require_relative 'contact'

class Interaction < BaseModel
  attr_accessor :contact_id, :message, :response, :context_summary

  def initialize(attributes = {})
    super(attributes)
    @contact_id = attributes[:contact_id]
    @message = attributes[:message]
    @response = attributes[:response]
    @context_summary = attributes[:context_summary]
  end

  def self.table_name
    'interactions'
  end

  def self.find_by_contact(contact_id, limit: 10)
    db = Database.connection
    results = db.execute(
      "SELECT * FROM #{table_name} WHERE contact_id = ? ORDER BY created_at DESC LIMIT ?",
      [contact_id, limit]
    )
    results.map { |row| new_from_hash(row) }
  end

  def contact
    @contact ||= Contact.find(@contact_id) if @contact_id
  end

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

  protected

  def insert_columns
    [:contact_id, :message, :response, :context_summary]
  end

  def insert_values
    [@contact_id, @message, @response, @context_summary]
  end

  def update_columns
    [:contact_id, :message, :response, :context_summary]
  end

  def update_values
    [@contact_id, @message, @response, @context_summary]
  end
end

