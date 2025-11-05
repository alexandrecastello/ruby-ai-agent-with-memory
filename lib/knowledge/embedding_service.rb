require 'ruby/openai'
require 'faraday'
require 'json'

class EmbeddingService
  def initialize(provider = nil)
    @provider = provider || ENV['EMBEDDING_PROVIDER'] || 'openai'
    @cache = {}
  end

  def generate_embedding(text)
    return nil if text.nil? || text.empty?
    
    cache_key = "#{@provider}:#{text}"
    return @cache[cache_key] if @cache.key?(cache_key)
    
    embedding = case @provider
    when 'openai'
      generate_openai_embedding(text)
    when 'gemini'
      generate_gemini_embedding(text)
    else
      raise "Unknown embedding provider: #{@provider}"
    end
    
    @cache[cache_key] = embedding if embedding
    embedding
  end

  def generate_embeddings(texts)
    texts.map { |text| generate_embedding(text) }
  end

  private

  def generate_openai_embedding(text)
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    
    response = client.embeddings(
      parameters: {
        model: 'text-embedding-3-small',
        input: text
      }
    )
    
    if response['data'] && response['data'].first
      response['data'].first['embedding']
    else
      raise "OpenAI API error: #{response['error'] || 'Unknown error'}"
    end
  rescue => e
    raise "OpenAI embedding generation failed: #{e.message}"
  end

  def generate_gemini_embedding(text)
    api_key = ENV['GOOGLE_GEMINI_KEY']
    raise "GOOGLE_GEMINI_KEY not set" unless api_key
    
    url = "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=#{api_key}"
    
    conn = Faraday.new(url: url) do |faraday|
      faraday.request :json
      faraday.response :json
    end
    
    response = conn.post do |req|
      req.body = {
        model: 'models/text-embedding-004',
        content: {
          parts: [{ text: text }]
        }
      }
    end
    
    if response.status == 200 && response.body['embedding']
      response.body['embedding']['values']
    else
      error_msg = response.body['error'] || 'Unknown error'
      raise "Gemini API error: #{error_msg}"
    end
  rescue => e
    raise "Gemini embedding generation failed: #{e.message}"
  end
end

