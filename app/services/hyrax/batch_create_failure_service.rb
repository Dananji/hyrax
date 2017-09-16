module Hyrax
  class BatchCreateFailureService < AbstractMessageService
    attr_reader :user
    def initialize(user)
      @user = user
      @messages = messages.to_sentence
    end

    def message
      "The batch create for #{user} failed: #{messages}"
    end

    def subject
      'Failing batch create'
    end
  end
end
