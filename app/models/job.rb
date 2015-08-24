class Job

  attr_reader :session

  def initialize

  end

  # Push message to queue
  def push_to_queue(body)
    data = body.merge({:job => get_job_name})
    AwsService.send_message_to_queue(data)
  end

  def push_session_id(session_id)
    push_to_queue({:session_id => session_id})
  end

  def method_missing name, *args
  	if((result = /^push_(.*?)$/.match name) && args.length > 0)
  	  push_to_queue({result[1] => args[0]})
  	else
  	  logger.fatal "method missing name:" + name.to_s + " args:" + args.join(",")
  	  raise NoMethodError.new("NoMethodError")
  	end
  end

  def push(data)
    @session = get_session_model.new data
    if @session.save
      push_session_id @session.id
      return true
    end

    return false
  end

  protected

  def get_job_name
  	if @job_name.nil?
  	  @job_name = 'unpairmessage'
  	  @job_name['message'] = ''
    end
    return @job_name
  end

  def get_session_model
    class_name = get_job_name + '::session'
    @session_model = class_name.constantize if @session_model.nil?
    return @session_model
  end
end