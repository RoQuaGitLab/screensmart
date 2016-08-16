class FinishResponse < ActiveInteraction::Base
  string :response_uuid

  validates :response_uuid, presence: true
  validate :validate_response_uuid_is_found
  validate :validate_invitation_uuid_is_found
  validate :validate_response_is_not_finished
  validate :validate_all_questions_answered

  def execute
    Events::ResponseFinished.create! invitation_uuid: invitation.invitation_uuid,
                                     response_uuid: response_uuid,
                                     answer_values: response.answer_values,
                                     estimate: response.estimate,
                                     variance: response.variance
  end

  def validate_response_uuid_is_found
    return if Response.exists? response_uuid
    errors.add(:response_uuid, 'is unknown')
  end

  def validate_invitation_uuid_is_found
    return if invitation
    errors.add(:invitation_uuid, 'is not found')
  end

  def validate_response_is_not_finished
    return unless Events::ResponseFinished.find_by(response_uuid: response_uuid)
    errors.add(:response_uuid, 'has already been finished')
  end

  def validate_all_questions_answered
    return if response.done
    errors.add(:response_uuid, 'not all questions have been answered')
  end

  # The invitation that has been used to start the response
  def invitation
    Events::InvitationAccepted.find_by(response_uuid: response_uuid)
  end

  def response
    Response.find(response_uuid)
  end
end
