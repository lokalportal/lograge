module Lograge
  module LogSubscribers
    class ActionCable < Base
      ACTIONS = [
        :transmit_subscription_confirmation,
        :transmit_subscription_rejection,
        :perform_action,
        :subscribe,
        :unsubscribe,
        :connect,
        :disconnect,
        :message
      ]

      ACTIONS.each do |method_name|
        define_method(method_name) do |event|
          event.payload[:action] ||= method_name.to_s
          process_main_event(event)
        end
      end

      private

      def initial_data(payload)
        {
          method: {},
          path: {},
          format: {},
          params: payload[:params],
          data: payload[:data],
          controller: payload[:channel_class] || payload[:connection_class],
          action: payload[:action]
        }
      end

      def default_status
        200
      end

      def extract_runtimes(event, _payload)
        { duration: event.duration.to_f.round(2) }
      end
    end
  end
end
