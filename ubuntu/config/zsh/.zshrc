export LANG=ko_KR.UTF-8
export LANGUAGE=ko_KR:ko
export LC_ALL=ko_KR.UTF-8

eval "$(starship init zsh)"

# fzf: Ctrl-R 명령어 검색, Ctrl-T 파일 검색, Alt-C 디렉터리 검색
if command -v fzf >/dev/null 2>&1; then
  [ -r /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -r /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
fi

# zoxide: 자주 가는 디렉터리로 빠르게 이동하는 `z` 명령
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# eza: 보기 좋은 파일 목록
if command -v eza >/dev/null 2>&1; then
  # 검은 배경에서 잘 보이는 eza 색상
  export EZA_COLORS='di=38;5;117:fi=38;5;252:ln=38;5;213:ex=38;5;120:da=38;5;245'
  alias ls='eza --color=always'
  alias ll='eza -lah --git --icons --color=always'
  alias la='eza -a --icons --color=always'
fi

# bat: cat을 문법 강조·줄 번호가 있는 보기로 대체
if command -v batcat >/dev/null 2>&1; then
  export BAT_THEME='ansi'
  alias bat='batcat'
  alias cat='batcat'
elif command -v bat >/dev/null 2>&1; then
  export BAT_THEME='ansi'
  alias cat='bat'
fi

# 입력한 문자열로 시작하는 명령어만 검색
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# 일부 터미널에서 사용하는 방향키 코드
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# >>> Codex installer >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< Codex installer <<<
