module Builtins
  module Helpers
    module CompletionScripts
      COMPLETION_SCRIPTS = { "bash" => BASH_COMPLETION_SCRIPT, "zsh" => ZSH_COMPLETION_SCRIPT, "fish" => FISH_COMPLETION_SCRIPT }

      BASH_COMPLETION_SCRIPT = <<-BASH_COMPLETION_SCRIPT
      __ops_completion() {
        local curr prev
        curr="${COMP_WORDS[COMP_CWORD]}"

        prev="${COMP_WORDS[*]:0:COMP_CWORD}"

        local suggestions
        suggestions=$(ops completion bash -- "curr=$curr" "prev=$prev" 2>/dev/null)

        COMPREPLY=()
        while read line; do
          [ -n "$line" ] && COMPREPLY+=("$line")
        done <<< "$suggestions"
      }

      complete -F __ops_completion ops
      BASH_COMPLETION_SCRIPT

      ZSH_COMPLETION_SCRIPT = <<-ZSH_COMPLETION_SCRIPT
      autoload -Uz compinit && compinit

      __ops_completion() {
        local curr
        curr="${words[CURRENT]}"

        local prev=""
        local i=1
        for ((i=1; i < CURRENT; i++)); do
          prev="${prev} ${words[i]}"
        done

        local suggestions
        suggestions=$(ops completion zsh -- "curr=$curr" "prev=$prev" 2>/dev/null)

        local -a compadd_args
        compadd_args=("${(f)suggestions}")
        compadd -- "${compadd_args[@]}"
      }

      compdef __ops_completion ops
      ZSH_COMPLETION_SCRIPT

      FISH_COMPLETION_SCRIPT = <<-FISH_COMPLETION_SCRIPT
      function __ops_completion
        set -l curr (commandline -ct)
        set -l prev (commandline -cx)

        ops completion fish -- "curr=$curr" "prev=$prev" 2>/dev/null
      end

      complete -c ops -f -a "(__ops_completion)"
      FISH_COMPLETION_SCRIPT
    end
  end
end
