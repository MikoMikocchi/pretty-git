# bash completion for pretty-git
# Install: source this file or copy to /etc/bash_completion.d/

_pretty_git()
{
    local cur prev words cword
    _init_completion -n : || return

    local reports="summary activity authors files heatmap languages hotspots churn ownership"
    local formats="console json csv md yaml xml"
    local metrics="bytes files loc"
    local themes="basic bright mono"

    # Options
    local opts="--help --version --verbose --repo --branch --since --until \
                --author --exclude-author --time-bucket --path --exclude-path \
                --limit --format --out --no-color --theme --metric \
                -l -f -o"

    case ${prev} in
        --repo|--out)
            # file path completion
            COMPREPLY=( $(compgen -o plusdirs -f -- "$cur") )
            return
            ;;
        --branch|--author|--exclude-author|--since|--until|--path|--exclude-path)
            # free-form values or globs
            COMPREPLY=( $(compgen -W "${cur}" -- "$cur") )
            return
            ;;
        --time-bucket)
            COMPREPLY=( $(compgen -W "day week month" -- "$cur") )
            return
            ;;
        --format)
            COMPREPLY=( $(compgen -W "${formats}" -- "$cur") )
            return
            ;;
        --metric)
            COMPREPLY=( $(compgen -W "${metrics}" -- "$cur") )
            return
            ;;
        --theme)
            COMPREPLY=( $(compgen -W "${themes}" -- "$cur") )
            return
            ;;
        --limit)
            COMPREPLY=( $(compgen -W "all" -- "$cur") )
            return
            ;;
        -f)
            COMPREPLY=( $(compgen -W "${formats}" -- "$cur") )
            return
            ;;
        -o)
            COMPREPLY=( $(compgen -o plusdirs -f -- "$cur") )
            return
            ;;
        -l)
            COMPREPLY=( $(compgen -W "all" -- "$cur") )
            return
            ;;
    esac

    if [[ ${cword} -eq 1 ]]; then
        # complete report as first positional arg
        COMPREPLY=( $(compgen -W "${reports}" -- "$cur") )
        return
    fi

    if [[ ${cword} -eq 2 ]]; then
        # complete repo path as second positional arg
        COMPREPLY=( $(compgen -o plusdirs -f -- "$cur") )
        return
    fi

    # complete options
    COMPREPLY=( $(compgen -W "${opts}" -- "$cur") )
}

complete -F _pretty_git pretty-git
