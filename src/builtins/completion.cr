require "builtins/helpers/completion_scripts"

module Builtins
  class Completion < Builtin
    def run
      shell = @args[0]? || "bash"
      rest = @args[1..-1]? || [] of String

      if rest[0]? == "--install"
        script = completion_scripts[shell]?
        if script
          puts script
        else
          STDERR.puts "No completion script available for shell: #{shell}"
          return false
        end
        return true
      end

      parsed = parse_args(rest)
      curr = parsed["curr"]? || ""
      prev = parsed["prev"]? || ""

      prev_tokens = prev.split

      active_ops_yml = resolve_ops_yml(prev_tokens)

      # Check if past commands in order to provide file completions
      past_subcommands = false
      prev_tokens.each do |token|
        if active_ops_yml.actions.has_key?(token) || BUILTINS.has_key?(token)
          past_subcommands = true
          break
        end
      end

      completions = [] of String

      if past_subcommands
        completions = complete_files(curr)
      else
        BUILTINS.each_key do |c|
          completions << c
        end

        active_ops_yml.forwards.each_key do |c|
          completions << c
        end

        active_ops_yml.actions.each_key do |c|
          completions << c
        end
      end

      completions
        .select { |c| curr.empty? || c.starts_with?(curr) }
        .sort
        .each { |c| puts c }

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
      files = [] of String

      Dir.children(Dir.current).each do |entry|
        unless curr.empty? || entry.starts_with?(curr)
          next
        end

        files << entry
      end

      files
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

    private def completion_scripts
      Builtins::Helpers::CompletionScripts::COMPLETION_SCRIPTS
    end
  end
end
