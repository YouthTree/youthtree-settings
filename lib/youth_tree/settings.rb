require 'yaml'
require 'erb'

module YouthTree
  class Settings

    VERSION = "1.0.1".freeze

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

      def setup(value = nil, &blk)
        @@setup_callback = (blk || value)
      end

      def settings_path
        @@settings_path ||= Rails.root.join("config", "settings.yml").to_s
      end

      def load_from_file
        if !File.readable?(settings_path)
          $stderr.puts "Unable to load settings from #{settings_path} - Please check it exists and is readable."
          return {}
        end
        # Otherwise, try loading...
        contents = File.read(settings_path)
        contents = ERB.new(contents).result
        contents = YAML.load(contents)
        (contents["default"] || {}).deep_merge(contents[Rails.env] || {})
      end

      def default
        @@default ||= new(load_from_file)
      end

      def reset!
        @@default = nil
        default # Force us to reload the settings
        YouthTree::Settings.setup_mailer!
        # If a setup block is defined, call it post configuration.
        @setup_callback.call if defined?(@setup_callback) && @setup_callback
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
