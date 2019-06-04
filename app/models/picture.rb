class Picture < ActiveRecord::Base
  MaxWidth = 500
  MaxHeight = 300
  has_one :play
  has_attached_file :image,
    :url => "/system/pictures/:uuid/:id/:style/response.:correct_extension",
    :path => ":rails_root/public/system/pictures/:uuid/:id/:style/response.:correct_extension",
    :styles => { :display => MaxWidth.to_s + 'x' + MaxHeight.to_s + '>' },
    :s3_protocol => 'https'
  validates_attachment_presence :image
  validates_attachment_content_type :image, :content_type => [ 'image/jpeg', 'image/png', 'image/gif', 'image/x-png', 'image/pjpeg' ], :message => 'must be a PNG, JPEG, or GIF'
  validate :validate_file_type_by_contents
  after_post_process :set_dimensions
  after_validation :clean_errors
  after_initialize :init

  Paperclip.interpolates :correct_extension do |attachment, style|
    attachment.instance.correct_extension
  end

  Paperclip.interpolates :uuid do |attachment, style|
    attachment.instance.uuid
  end

  def init
    self.uuid ||= SecureRandom.uuid
  end

  # Access Control

  def self.can_show(user)
    where(Play.
      joins(:game => :players).
      where{ plays.picture_id == pictures.id }.
      where{ players.user_id == user.id }.
      exists)
  end

  def can_show?(user)
    Picture.can_show(user).exists?(self)
  end
  
  # Helper Properties

  def login
    play.player.user.login
  end

  def color
    play.color
  end

  def correct_extension
    case self.image_content_type
      when 'image/jpeg' then 'jpg'
      when 'image/pjpeg' then 'jpg'
      when 'image/png' then 'png'
      when 'image/x-png' then 'png'
      when 'image/gif' then 'gif'
      else ''
    end
  end

  # Validation

  def validate_file_type_by_contents
    return if (errors.include? :image_content_type)
    file_path = image.queued_for_write[:original].path
    output = Cocaine::CommandLine.new('identify', '-format %m :file').run(:file => file_path)
    errors.add(:image_content_type, 'is corrupt or not the file type indicated by its extension') unless %w(PNG JPEG GIF).include? output.strip
  rescue => e
    errors.set(:image, ['could not be processed'])
    logger.error e.to_s
  end

  def append_errors(new_errors)
    if new_errors && new_errors.any?
      new_errors.each_pair { |key, key_errors| key_errors.each { |error| self.errors.add(key, error) } }
    end
  end

  def clean_errors
    if errors.include? :image
      errors.set(:image, ['could not be processed'])
    end
    if errors.include? :image_content_type
      errors.set(:image, errors[:image_content_type])
    end
    errors
  end

  # Mutating Methods

  def set_dimensions
    # Paperclip is supposed to only post-process if the model is valid, but that appears to not be the case.
    return unless valid?

    geometry = Paperclip::Geometry.from_file(image.queued_for_write[:original])
    self.original_width = geometry.width
    self.original_height = geometry.height
    
    geometry = Paperclip::Geometry.from_file(image.queued_for_write[:display])
    self.display_width = geometry.width
    self.display_height = geometry.height
	end
end

