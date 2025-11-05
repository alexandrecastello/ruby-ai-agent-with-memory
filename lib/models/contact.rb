require_relative '../../config/database'

class Contact
  attr_accessor :id, :name, :email, :company, :status, :last_contact_at, :created_at

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @email = attributes[:email]
    @company = attributes[:company]
    @status = attributes[:status] || 'new'
    @last_contact_at = attributes[:last_contact_at]
    @created_at = attributes[:created_at]
  end

  def save
    db = Database.connection
    
    last_contact_str = @last_contact_at.is_a?(Time) ? @last_contact_at.to_s : @last_contact_at
    
    if @id
      db.execute(
        "UPDATE contacts SET name = ?, email = ?, company = ?, status = ?, last_contact_at = ? WHERE id = ?",
        [@name, @email, @company, @status, last_contact_str, @id]
      )
      @id
    else
      db.execute(
        "INSERT INTO contacts (name, email, company, status, last_contact_at) VALUES (?, ?, ?, ?, ?)",
        [@name, @email, @company, @status, last_contact_str]
      )
      @id = db.last_insert_row_id
    end
  end

  def self.find(id)
    db = Database.connection
    result = db.execute("SELECT * FROM contacts WHERE id = ?", [id]).first
    return nil unless result
    
    new_from_hash(result)
  end

  def self.all
    db = Database.connection
    results = db.execute("SELECT * FROM contacts ORDER BY created_at DESC")
    results.map { |row| new_from_hash(row) }
  end

  def self.find_by_email(email)
    db = Database.connection
    result = db.execute("SELECT * FROM contacts WHERE email = ?", [email]).first
    return nil unless result
    
    new_from_hash(result)
  end

  def update_last_contact
    @last_contact_at = Time.now
    save
  end

  private

  def self.new_from_hash(hash)
    new(
      id: hash['id'],
      name: hash['name'],
      email: hash['email'],
      company: hash['company'],
      status: hash['status'],
      last_contact_at: hash['last_contact_at'] ? Time.parse(hash['last_contact_at']) : nil,
      created_at: hash['created_at'] ? Time.parse(hash['created_at']) : nil
    )
  end
end

