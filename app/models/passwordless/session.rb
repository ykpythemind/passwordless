# frozen_string_literal: true

module Passwordless
  # The session responsible for holding the connection between the record
  # trying to log in and the unique tokens.
  class Session < ApplicationRecord
    belongs_to :authenticatable,
      polymorphic: true, inverse_of: :passwordless_sessions

    validates \
      :authenticatable,
      :timeout_at,
      :expires_at,
      :user_agent,
      :remote_addr,
      :token,
      presence: true

    before_validation :set_defaults

    scope :valid, lambda {
      where('timeout_at > ?', Time.current)
    }

    def expired?
      expires_at <= Time.current
    end

    private

    def set_defaults
      self.expires_at ||= Passwordless.expires_at.call
      self.timeout_at ||= Passwordless.timeout_at.call
      self.token ||= loop do
        token = Passwordless.token_generator.call(self)
        break token unless Session.find_by(token: token)
      end
    end
  end
end
