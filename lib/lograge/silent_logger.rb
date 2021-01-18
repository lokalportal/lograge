module Lograge
  class SilentLogger < SimpleDelegator
    COMMANDS = {
      "subscribe" => "subscribe",
      "unsubscribe" => "unsubscribe",
      "message" => "perform_action"
    }

    def initialize(logger)
      super
    end

    %i(debug info warn fatal unknown).each do |method_name|
      define_method(method_name) { |*_args| }
    end

    #
    # TODO: In later rails versions, action cable supports ActiveSupport::Rescuable. Exceptions
    # should then be logged inside the application and this can be removed.
    #
    def error(msg, *args)
      details = extract_details(msg)
      payload = {
        channel_class: details[:identifier]&.[]("channel"),
        data: details[:data],
        params: details[:identifier],
        exception: [Exception, details[:error_message]]
      }

      ActiveSupport::Notifications.instrument("#{COMMANDS[details[:command]] || "message"}.action_cable", payload)
    end

    private

    def extract_details(message)
      {
        command: message.scan(/"command"=>"(?<command>\w+)"/).flatten.first,
        identifier: json_unescaped_parse(message.scan(/"identifier"=>"(?<identifier>{.+})",/).flatten.first),
        data: json_unescaped_parse(message.scan(/"data"=>"(?<data>{.+})"/).flatten.first),
        error_message: message.scan(/\[(.+)\]/).flatten.first
      }
    end

    def extract_exception_caller
      caller.drop_while do |l|
        !l.match?("action_cable") || l.match?("tagged_logger_proxy")
      end
    end

    def execute_command_error?
      extract_exception_caller.first.match?(/rescue in execute_command/)
    end

    def json_unescaped_parse(str)
      return if str.blank?
      JSON.parse(str.gsub('\\"', '"'))
    rescue StandardError
      nil
    end
  end
end
