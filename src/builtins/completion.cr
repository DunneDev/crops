module Builtins
  class Completion < Builtin
    def initialize(args : Array(String), ops_yml : OpsYml)
      @args = args
      @ops_yml = ops_yml
    end

    def run
      ["countdown", "down", "env", "envdiff", "exec", "help", "init", "up", "version"].each do |c|
        puts c
      end
      true
    end
  end
end
