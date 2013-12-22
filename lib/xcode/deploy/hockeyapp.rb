require 'rest-client'

module Xcode
  module Deploy
    class Hockeyapp
      attr_accessor :app_id, :api_token, :notify, :proxy, :notes, :builder, :status, :notes_type
      @@defaults = {}

      def self.defaults(defaults={})
        @@defaults = defaults
      end

      def initialize(builder, options={})
        @builder = builder
        @api_token = options[:api_token]||@@defaults[:api_token]
        @app_id = options[:app_id]||@@defaults[:app_id]
        @status = options[:status]||@@defaults[:status]
        @notify = options.has_key?(:notify) ? options[:notify] : true
        @notes_type = options[:notes_type]||@@defaults[:notes_type]
        @notes = options[:notes]
        @proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
      end

      def deploy
        puts "Uploading to HockeyApp..."

        cmd = Xcode::Shell::Command.new 'curl'
        cmd << "--proxy #{@proxy}" unless @proxy.nil? or @proxy==''
        cmd << "-X POST https://rink.hockeyapp.net/api/2/apps/#{app_id}/app_versions/upload"
        cmd << "-F status=\"#{status}\""
        cmd << "-F notes_type=\"#{notes_type}\""
        cmd << "-F ipa=@\"#{@builder.ipa_path}\""
        cmd << "-F dsym=@\"#{@builder.dsym_zip_path}\"" unless @builder.dsym_zip_path.nil?
        cmd << "-H 'X-HockeyAppToken: #{@api_token}'"
        cmd << "-F notes=\"#{@notes}\"" unless @notes.nil?
        cmd << "-F notify=#{@notify ? 'True' : 'False'}"

        response = cmd.execute

        json = MultiJson.load(response.join(''))
        puts " + Done, got: #{json.inspect}"

        yield(json) if block_given?

        json
      end
    end
  end
end
