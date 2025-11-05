require_relative '../../config/database'

class BaseModel
  attr_accessor :id, :created_at

  def initialize(attributes = {})
    @id = attributes[:id]
    @created_at = attributes[:created_at]
  end

  def save
    db = Database.connection
    
    if @id
      update_record(db)
      @id
    else
      insert_record(db)
      @id = db.last_insert_row_id
    end
  end

  def self.find(id)
    db = Database.connection
    result = db.execute("SELECT * FROM #{table_name} WHERE id = ?", [id]).first
    return nil unless result
    
    new_from_hash(result)
  end

  def self.all
    db = Database.connection
    results = db.execute("SELECT * FROM #{table_name} ORDER BY created_at DESC")
    results.map { |row| new_from_hash(row) }
  end

  def self.table_name
    raise NotImplementedError, "Subclass must implement table_name"
  end

  def self.new_from_hash(hash)
    raise NotImplementedError, "Subclass must implement new_from_hash"
  end

  protected

  def insert_columns
    raise NotImplementedError, "Subclass must implement insert_columns"
  end

  def insert_values
    raise NotImplementedError, "Subclass must implement insert_values"
  end

  def update_columns
    raise NotImplementedError, "Subclass must implement update_columns"
  end

  def update_values
    raise NotImplementedError, "Subclass must implement update_values"
  end

  protected

  def format_value(value)
    case value
    when Time
      value.to_s
    else
      value
    end
  end

  private

  def insert_record(db)
    columns = insert_columns
    values = insert_values
    placeholders = (['?'] * values.length).join(', ')
    
    db.execute(
      "INSERT INTO #{self.class.table_name} (#{columns.join(', ')}) VALUES (#{placeholders})",
      values
    )
  end

  def update_record(db)
    columns = update_columns
    values = update_values
    set_clause = columns.map { |col| "#{col} = ?" }.join(', ')
    
    db.execute(
      "UPDATE #{self.class.table_name} SET #{set_clause} WHERE id = ?",
      values + [@id]
    )
  end
end

