require 'yaml'
require 'erb'

module YouthTree
  class Settings

    VERSION = "0.3.0".freeze

    cattr_reader :settings_path
    def self.settings_path
      @@settings_path ||= Rails.root.join("config", "settings.yml")
    end

    def initialize(hash = {})
      @hash = Hash.new { |h,k| h[k] = self.class.new }
      hash.each_pair { |k, v| self[k] = v }
    end

    def to_hash
      unpack_attr @hash
    end

    def []=(k, v)
      @hash[k.to_sym] = normalize_attr(v)
    end

    def [](k)
      @hash[k.to_sym]
    end

    def has?(key)
      key = key.to_sym
      @hash.has_key?(key) && @hash[key].present?
    end

    def fetch(key, default = nil)
      has?(key) ? self[key] : default
    end

    def blank?
      @hash.blank?
    end

    def present?
      !blank?
    end

    def method_missing(name, *args, &blk)
      name = name.to_s
      key, modifier = name[0..-2], name[-1, 1]
      case modifier
      when '?'
        has?(key)
      when '='
        send(:[]=, key, *args)
      else
        self[name]
      end
    end

    def respond_to?(name, key = false)
      true
    end

    class << self

      def load_from_file
        contents = File.read(self.settings_path)
        contents = ERB.new(contents).result
        contents = YAML.load(contents)
        (contents["default"] || {}).deep_merge(contents[Rails.env] || {})
      end

      def default
        @@__default ||= begin
          groups = [load_from_file]
          self.new(groups.inject({}) { |a,v| a.deep_merge(v) })
        end
      end

      def reset!
        @@__default = nil
        default # Force us to reload the settings
        YouthTree::Settings.setup_mailer!
        true
      end

      def method_missing(name, *args, &blk)
        default.send(name, *args, &blk)
      end

      def respond_to?(name, key = false)
        true
      end

      def ssl?
        !disable_ssl? && (force_ssl? || Rails.env.production?)
      end

      def ssl_protocol
        ssl? ? "https" : "http"
      end

      # Sets up ActionMailer to use settings from Settings.
      def setup_mailer!
        return unless mailer?
        s = mailer
        ActionMailer::Base.default_url_options[:host] = s.host
        ActionMailer::Base.delivery_method            = s.delivery_method.to_sym
        ActionMailer::Base.smtp_settings              = s.smtp_settings.to_hash     if s.smtp_settings?
        ActionMailer::Base.sendmail_settings          = s.sendmail_settings.to_hash if s.sendmail_settings?
        ActionMailer::Base.default              :from => s.from

        # Setup sendgrid if present, sort of a faux-sendgrid helper.
        if s.delivery_method.to_sym == :sendgrid
          ActionMailer::Base.delivery_method = :smtp
          ActionMailer::Base.smtp_settings   = {
            :address        => "smtp.sendgrid.net",
            :port           => "25",
            :authentication => :plain,
            :user_name      => s.sendgrid.username,
            :password       => s.sendgrid.password,
            :domain         => s.sendgrid.domain
          }
        end
      end

    end

    protected

    def normalize_attr(value)
      case value
      when Hash
        self.class.new(value)
      when Array
        value.map { |v| normalize_attr(v) }
      else
        value
      end
    end

    def unpack_attr(value)
      case value
      when self.class
        value.to_hash
      when Hash
        Hash.new.tap do |h|
          value.each_pair { |k,v| h[k] = unpack_attr(v) }
        end
      when Array
        value.map { |v| unpack_attr(v) }
      else
        value
      end
    end

  end

  if defined?(Rails::Railtie)
    class Railtie < Rails::Railtie
      config.to_prepare { YouthTree::Settings.reset! }
    end
  end

end
