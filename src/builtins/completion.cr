module Builtins
  class Completion < Builtin
    def run
      BUILTINS.each_key do |c|
        puts c
      end
      true
    end
  end
end
