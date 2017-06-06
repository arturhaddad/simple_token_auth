class Authentication < ApplicationRecord
  # Associations
  belongs_to :authable, polymorphic: true

  # Validations
  validates_presence_of :authable

  # Serializations
  serialize :metadata, Hash

  # Constants
  ACCEPTED_OS = [:ios, :android]

  # Virtual Attributes
  attr_accessor :raw_access_token

  # Callbacks
  before_create :generate_authentication_tokens
  before_save :convert_to_valid_device, if: 'metadata_changed?'

  # Callback and validation methods
  def generate_authentication_tokens
    self.client = Devise.friendly_token
    self.access_token =  Devise.friendly_token
  end

  # Instance methods
  def access_token=(token)
    self.raw_access_token = token
    self.encrypted_access_token = Authentication.token_encryptor(token)
  end

  def access_token
    self.raw_access_token
  end

  def register_device(device_id, os)

    # unless os_index = ACCEPTED_OS.index(os.downcase.to_sym)
    #   errors.add(:operating_system, "not accepted.")
    #   return false
    # end

    self.metadata[:device_id] = device_id
    # self.metadata[:device_os] = ACCEPTED_OS[os_index]
    self.metadata[:device_os] = os

    self.save
  end

  def convert_to_valid_device
    if metadata.has_key? :device_os
      if metadata[:device_id].blank?
        self.metadata.delete(:device_os) # remove device_os if it doesn't have a device id associated
        if metadata.has_key? :device_id
          self.metadata.delete(:device_id)
        end
        return
      end
      if metadata[:device_os].is_a? String
        unless os_index = ACCEPTED_OS.index(metadata[:device_os].downcase.to_sym)
          errors.add(:operating_system, "not accepted.")
          return false
        end
      else
        unless os_index = ACCEPTED_OS.index(metadata[:device_os].to_s.downcase.to_sym)
          errors.add(:operating_system, "not accepted.")
          return false
        end
      end
      self.metadata[:device_os] = ACCEPTED_OS[os_index]
    end
  end

  # Class methods
  def self.token_compare(token, enc_token)
    Devise.secure_compare(token_encryptor(token), enc_token)
  end

  def self.token_encryptor(token)
    Devise.token_generator.digest(Authentication, :encrypted_access_token, token)
  end

  def self.accepted_os
    ACCEPTED_OS
  end
end
