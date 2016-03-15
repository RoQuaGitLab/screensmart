# Only module that should communicate with screensmart-r
module RPackage
  def self.questions
    Rails.cache.fetch('questions') do
      call('get_itembank_rdata')
    end
  end

  def self.data_for(raw_answers, estimate = nil, variance = nil)
    Rails.cache.fetch(cache_key_for(raw_answers, estimate, variance)) do
      params = {
        responses: answers_for_r(raw_answers),
        estimate: estimate ? estimate.to_f : nil,
        variance: variance ? variance.to_f : nil }.compact
      raw_data = call('call_shadowcat', params)

      {
        next_question_key: raw_data['key_new_item'],
        estimate: raw_data['estimate'][0].to_f,
        variance: raw_data['variance'][0].to_f
      }
    end
  end

  def self.cache_key_for(raw_answers, estimate, variance)
    "#{raw_answers}#{estimate}#{variance}"
  end

  def self.answers_for_r(raw_answers)
    answers = {}
    raw_answers.each do |key, value|
      answers[key] = value.to_i
    end

    # TODO: find a way to call OpenCPU with responses: [{}]
    answers.present? ? [answers] : []
  end

  def self.call(function, parameters = {})
    Rails.logger.debug "Calling OpenCPU: #{function}(#{parameters})"
    OpenCPU.client.execute('screensmart', function, user: :system, data: parameters, convert_na_to_nil: true)
  end
end
