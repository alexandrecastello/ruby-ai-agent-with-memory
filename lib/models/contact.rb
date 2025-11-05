require_relative 'base_model'

class Contact < BaseModel
  attr_accessor :name, :email, :company, :status, :last_contact_at

  def initialize(attributes = {})
    super(attributes)
    @name = attributes[:name]
    @email = attributes[:email]
    @company = attributes[:company]
    @status = attributes[:status] || 'new'
    @last_contact_at = attributes[:last_contact_at]
  end

  def self.table_name
    'contacts'
  end

  def self.find_by_email(email)
    db = Database.connection
    result = db.execute("SELECT * FROM #{table_name} WHERE email = ?", [email]).first
    return nil unless result
    
    new_from_hash(result)
  end

  def update_last_contact
    @last_contact_at = Time.now
    save
  end

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

  protected

  def insert_columns
    [:name, :email, :company, :status, :last_contact_at]
  end

  def insert_values
    [
      @name,
      @email,
      @company,
      @status,
      format_value(@last_contact_at)
    ]
  end

  def update_columns
    [:name, :email, :company, :status, :last_contact_at]
  end

  def update_values
    [
      @name,
      @email,
      @company,
      @status,
      format_value(@last_contact_at)
    ]
  end
end

