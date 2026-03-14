# frozen_string_literal: true

module Legion
  module Extensions
    module FreeEnergy
      class Client
        include Runners::FreeEnergy

        def initialize(engine: nil)
          @engine = engine
        end
      end
    end
  end
end
