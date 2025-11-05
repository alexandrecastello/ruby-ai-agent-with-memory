require_relative '../../config/database'
require_relative 'embedding_service'
require 'json'

class VectorStore
  def initialize(embedding_service = nil)
    @embedding_service = embedding_service || EmbeddingService.new
    @db = Database.connection
  end

  def add_document(content, metadata = {})
    embedding = @embedding_service.generate_embedding(content)
    return nil unless embedding
    
    embedding_json = JSON.generate(embedding)
    metadata_json = JSON.generate(metadata)
    
    @db.execute(
      "INSERT INTO knowledge_embeddings (content, embedding, metadata) VALUES (?, ?, ?)",
      [content, embedding_json, metadata_json]
    )
    
    @db.last_insert_row_id
  end

  def search(query, limit: 5, threshold: 0.5)
    query_embedding = @embedding_service.generate_embedding(query)
    return [] unless query_embedding
    
    results = @db.execute("SELECT id, content, embedding, metadata FROM knowledge_embeddings")
    
    similarities = results.map do |row|
      stored_embedding = JSON.parse(row['embedding'])
      similarity = cosine_similarity(query_embedding, stored_embedding)
      
      {
        id: row['id'],
        content: row['content'],
        metadata: JSON.parse(row['metadata'] || '{}'),
        similarity: similarity
      }
    end
    
    similarities
      .select { |r| r[:similarity] >= threshold }
      .sort_by { |r| -r[:similarity] }
      .first(limit)
  end

  def get_by_id(id)
    result = @db.execute(
      "SELECT id, content, embedding, metadata FROM knowledge_embeddings WHERE id = ?",
      [id]
    ).first
    
    return nil unless result
    
    {
      id: result['id'],
      content: result['content'],
      embedding: JSON.parse(result['embedding']),
      metadata: JSON.parse(result['metadata'] || '{}')
    }
  end

  def delete_by_id(id)
    @db.execute("DELETE FROM knowledge_embeddings WHERE id = ?", [id])
    @db.changes > 0
  end

  def count
    @db.execute("SELECT COUNT(*) as count FROM knowledge_embeddings").first['count']
  end

  private

  def cosine_similarity(vec1, vec2)
    return 0.0 if vec1.length != vec2.length
    
    dot_product = vec1.zip(vec2).sum { |a, b| a * b }
    magnitude1 = Math.sqrt(vec1.sum { |x| x * x })
    magnitude2 = Math.sqrt(vec2.sum { |x| x * x })
    
    return 0.0 if magnitude1 == 0 || magnitude2 == 0
    
    dot_product / (magnitude1 * magnitude2)
  end
end

