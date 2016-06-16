module Zygote

  # Provides a hook for identifiers to alter boot-time behavior
  # To do so, extend this class with a new identify method, then
  # set the identifier to that method name.
  # module Zygote; module; Identifier
  # def my_identifier(params)
  #   mutate_params(params)
  # end
  # end; end
  # Zygote::Identifier.identifier = :my_identifier
  module Identifier
    extend self

    attr_accessor :identifier

    def identify(params)
      @identifier ||= :identify_none
      send(@identifier.to_sym, params)
    end

  private

    # By default, we won't mutate the params in any way
    def identify_none(params)
      params
    end
  end
end
