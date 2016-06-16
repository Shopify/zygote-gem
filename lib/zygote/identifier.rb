module Zygote
  # Provides a hook for identifiers to alter boot-time behavior
  # To do so, extend this class with a new identify method.
  # You may NOT define more than one identifier - the last one wins.
  # class MyIdentifier < Zygote::Identifier
  #   def identify
  #     mutate_params(@params)
  #   end
  # end
  class Identifier
    class << self
      def inherited(subclass)
        @identifier = subclass
      end

      def identify(params)
        @identifier ||= self
        @identifier.new(params).identify
      end

      def reset!
        @identifier = self
      end
    end

    def initialize(params)
      @params = params
    end

    # Called only if this class is never subclassed
    def identify
      @params
    end
  end
end
