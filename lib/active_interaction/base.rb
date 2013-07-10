module ActiveInteraction
  # @abstract Subclass and override {#execute} to implement
  #   a custom ActiveInteraction class.
  class Base
    extend  ::ActiveModel::Naming
    include ::ActiveModel::Conversion
    include ::ActiveModel::Validations

    # @private
    def new_record?
      true
    end

    # @private
    def persisted?
      false
    end

    attr_reader :response

    # @private
    def initialize(options = {})
      if options.has_key?(:response)
        raise ArgumentError, ':response is reserved and can not be used'
      end

      options.each do |attribute, value|
        if respond_to?("#{attribute}=")
          send("#{attribute}=", value)
        else
          instance_variable_set("@#{attribute}", value)
        end
      end
    end

    def execute
      raise NotImplementedError
    end

    def self.run(options = {})
      me = new(options)

      me.instance_variable_set(:@response, me.execute) if me.valid?

      me
    end

    def self.run!(options = {})
      outcome = run(options)
      raise InteractionInvalid if outcome.invalid?
      outcome
    end

    # @!method array
    #
    # @return [Array]

    # @!method boolean
    #
    # @return [Boolean]

    # @!method date
    #
    # @return [Date]

    # @!method date_time
    #
    # @return [DateTime]

    # @!method float
    #
    # @return [Float]

    # @!method hash
    #
    # @return [Hash]

    # @!method integer
    #
    # @return [Integer]

    # @!method model
    #
    # @return [Model]

    # @!method string
    #
    # @return [String]

    # @!method time
    #
    # @return [Time]

    # @private
    def self.method_missing(attr_type, *args, &block)
      klass = Attr.factory(attr_type)
      options = args.last.is_a?(Hash) ? args.pop : {}

      args.each do |attribute|
        validator = "_validate__#{attribute}__#{attr_type}"

        attr_accessor attribute

        validate validator

        define_method(validator) do
          begin
            klass.prepare(attribute, send(attribute), options, &block)
          rescue MissingValue
            errors.add(attribute, 'is required')
          rescue InvalidValue
            errors.add(attribute, 'is invalid')
          end
        end
        private validator
      end
    end
    private_class_method :method_missing
  end
end