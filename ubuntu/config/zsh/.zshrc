# 개인 경로(Starship 사용자 설치 및 기존 CLI)를 먼저 찾습니다.
typeset -U path PATH
path=("$HOME/.local/bin" $path)

# 아직 한국어 로케일을 생성하지 않은 PC에서도 셸이 시작되도록 합니다.
if locale -a 2>/dev/null | command grep -Eqi '^ko_KR\.(utf8|UTF-8)$'; then
  export LANG=ko_KR.UTF-8
  export LANGUAGE=ko_KR:ko
  export LC_ALL=ko_KR.UTF-8
else
  export LANG=C.UTF-8
  export LC_ALL=C.UTF-8
fi

# fzf Ctrl+R에서 이전 셸의 기록도 검색할 수 있도록 합니다.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# Ubuntu는 시스템 zshrc에서 compinit을 실행합니다. 다른 구성에서는 보완합니다.
if (( ! $+functions[compdef] )); then
  autoload -Uz compinit
  compinit
fi

# fzf 0.48 이상은 --zsh, 이전 배포판 패키지는 제공된 스크립트를 사용합니다.
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for _dotfiles_fzf_file in \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/doc/fzf/examples/completion.zsh; do
      [[ -r "$_dotfiles_fzf_file" ]] && source "$_dotfiles_fzf_file"
    done
    unset _dotfiles_fzf_file
  fi
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v eza >/dev/null 2>&1; then
  export EZA_COLORS='di=38;5;117:fi=38;5;252:ln=38;5;213:ex=38;5;120:da=38;5;245'
  alias ls='eza --color=always'
  alias ll='eza -lah --git --icons --color=always'
  alias la='eza -a --icons --color=always'
fi

if command -v batcat >/dev/null 2>&1; then
  export BAT_THEME='ansi'
  alias bat='batcat'
  alias cat='batcat'
elif command -v bat >/dev/null 2>&1; then
  export BAT_THEME='ansi'
  alias cat='bat'
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# PC별 설정은 이 파일에 넣고 Git에 올리지 않습니다.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# 선택적 파일이 없어도 source ~/.zshrc가 성공하도록 합니다.
true
