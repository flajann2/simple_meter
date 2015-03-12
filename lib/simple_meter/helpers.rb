module SimpleMeter
  module Helpers
    ABC = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    def random_string(length = 128)
      (0...length).map{ ABC[rand(ABC.length)] }.join
    end
  end
end
