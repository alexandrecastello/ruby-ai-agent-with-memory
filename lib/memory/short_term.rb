class ShortTermMemory
  MAX_CONTEXT_SIZE = 10

  def initialize
    @recent_interactions = []
    @current_context = {}
    @summary = nil
  end

  def add_interaction(message, response, metadata = {})
    interaction = {
      message: message,
      response: response,
      timestamp: Time.now,
      metadata: metadata
    }
    
    @recent_interactions << interaction
    
    if @recent_interactions.length > MAX_CONTEXT_SIZE
      @recent_interactions.shift
    end
    
    update_context
  end

  def get_recent_context(limit: 5)
    @recent_interactions.last(limit)
  end

  def get_full_context
    {
      recent_interactions: @recent_interactions,
      current_context: @current_context,
      summary: @summary
    }
  end

  def update_context_summary(summary)
    @summary = summary
  end

  def clear
    @recent_interactions = []
    @current_context = {}
    @summary = nil
  end

  def set_current_context(key, value)
    @current_context[key] = value
  end

  def get_current_context(key = nil)
    if key
      @current_context[key]
    else
      @current_context
    end
  end

  def size
    @recent_interactions.length
  end

  private

  def update_context
    if @recent_interactions.length > 0
      last_interaction = @recent_interactions.last
      @current_context[:last_message] = last_interaction[:message]
      @current_context[:last_response] = last_interaction[:response]
      @current_context[:last_timestamp] = last_interaction[:timestamp]
    end
  end
end

