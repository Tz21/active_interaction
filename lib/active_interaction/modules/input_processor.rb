# coding: utf-8
# frozen_string_literal: true

module ActiveInteraction
  # Groups inputs ending in "(*N*i)" into {GroupedInput}.
  #
  # @since 1.2.0
  #
  # @private
  module InputProcessor
    class << self
      GROUPED_INPUT_PATTERN = /\A(.+)\((\d+)i\)\z/
      private_constant :GROUPED_INPUT_PATTERN

      def reserved?(name)
        name.to_s.start_with?('_interaction_') ||
          Base.method_defined?(name) ||
          Base.private_method_defined?(name)
      end

      def process(inputs)
        inputs.stringify_keys.sort.each_with_object({}) do |(k, v), h|
          next if reserved?(k)

          if (match = GROUPED_INPUT_PATTERN.match(k))
            assign_to_group!(h, *match.captures, v)
          else
            h[k.to_sym] = v
          end
        end
      end

      private

      def assign_to_group!(inputs, key, index, value)
        key = key.to_sym

        inputs[key] = GroupedInput.new unless inputs[key].is_a?(GroupedInput)
        inputs[key][index] = value
      end
    end
  end
end
