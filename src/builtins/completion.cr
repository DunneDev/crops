module Builtins
  class Completion < Builtin
    def run
      shell = @args[0]? || "bash"
      rest = @args[1..-1]? || [] of String

      parsed = parse_args(rest)
      curr = parsed["curr"]? || ""
      prev = parsed["prev"]? || ""

      prev_tokens = prev.split

      active_ops_yml = resolve_ops_yml(prev_tokens)

      last_token = prev_tokens.last?

      if last_token && (active_ops_yml.actions.has_key?(last_token) || BUILTINS.has_key?(last_token))
        complete_files(curr)
        return true
      end

      BUILTINS.each_key do |c|
        puts c
      end

      active_ops_yml.forwards.each_key do |c|
        puts c
      end

      active_ops_yml.actions.each_key do |c|
        puts c
      end
      true
    end

    private def parse_args(args : Array(String))
      result = {} of String => String

      if args[0]? == "--"
        args = args.skip(1) # skip -- and command name
      end

      args.each do |arg|
        if index = arg.index('=')
          result[arg[0...index]] = arg[(index + 1)..-1]
        end
      end

      result
    end

    private def complete_files(curr : String)
      Dir.children(Dir.current).each do |entry|
        unless curr.empty? || entry.starts_with?(curr)
          next
        end

        puts entry
      end
    end

    private def resolve_ops_yml(prev_tokens : Array(String))
      current_yml = @ops_yml

      prev_tokens.skip(1).each do |token|
        forward_dir = current_yml.forwards[token]?
        unless forward_dir
          return current_yml
        end

        root_dir = File.dirname(current_yml.absolute_path)
        absolute_forward_dir = File.expand_path(forward_dir, root_dir)

        ops_file = resolve_ops_file(absolute_forward_dir)

        unless ops_file
          return current_yml
        end

        current_yml = OpsYml.new(ops_file)
      end

      current_yml
    end

    private def resolve_ops_file(dir : String)
      yml_path = File.join(dir, "ops.yml")
      yaml_path = File.join(dir, "ops.yaml")

      if File.exists?(yml_path)
        return yml_path
      elsif File.exists?(yaml_path)
        return yaml_path
      end

      nil
    end
  end
end
