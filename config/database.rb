require 'sqlite3'
require 'fileutils'

module Database
  def self.connection
    @connection ||= begin
      db_path = ENV['DATABASE_PATH'] || 'db/agent.db'
      
      FileUtils.mkdir_p(File.dirname(db_path)) unless File.exist?(File.dirname(db_path))
      
      db = SQLite3::Database.new(db_path)
      db.results_as_hash = true
      db.execute('PRAGMA foreign_keys = ON')
      
      db
    end
  end

  def self.setup
    connection
    
    create_contacts_table
    create_interactions_table
    create_knowledge_embeddings_table
    create_context_summaries_table
  end

  def self.create_contacts_table
    connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        company TEXT,
        status TEXT DEFAULT 'new',
        last_contact_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    SQL
  end

  def self.create_interactions_table
    connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        response TEXT,
        context_summary TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(contact_id) REFERENCES contacts(id)
      )
    SQL
  end

  def self.create_knowledge_embeddings_table
    connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS knowledge_embeddings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        embedding TEXT NOT NULL,
        metadata TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    SQL
  end

  def self.create_context_summaries_table
    connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS context_summaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER NOT NULL,
        summary TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(contact_id) REFERENCES contacts(id)
      )
    SQL
  end
end

