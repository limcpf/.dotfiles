# 로그인 셸이 아닌 대화형 Bash에서 실행하는 ~/.bashrc입니다.
# 예제는 bash-doc 패키지의 /usr/share/doc/bash/examples/startup-files를 참고합니다.

# 대화형 셸이 아니면 여기서 종료합니다.
case $- in
    *i*) ;;
      *) return;;
esac

# 중복 명령과 공백으로 시작하는 명령은 기록하지 않습니다.
# 다른 옵션은 bash(1) 설명서를 참고합니다.
HISTCONTROL=ignoreboth

# 기존 기록을 덮어쓰지 않고 뒤에 추가합니다.
shopt -s histappend

# 메모리와 파일에 저장할 기록 개수입니다. 자세한 내용은 bash(1)을 참고합니다.
HISTSIZE=1000
HISTFILESIZE=2000

# 명령 실행 후 창 크기를 확인하고 필요하면 LINES와 COLUMNS를 갱신합니다.
shopt -s checkwinsize

# globstar를 켜면 경로 확장에서 **가 하위 디렉터리를 포함해 일치합니다.
#shopt -s globstar

# 텍스트가 아닌 파일도 less로 보기 쉽게 처리합니다. lesspipe(1)을 참고합니다.
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# 현재 chroot를 식별하는 값을 설정해 아래 프롬프트에서 사용합니다.
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# 터미널이 색상을 지원하는 경우에 사용할 프롬프트를 설정합니다.
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# 색상 지원 터미널에서 색상 프롬프트를 강제로 쓰려면 다음 줄의 주석을 해제합니다.
# 기본값은 명령 출력을 쉽게 읽도록 강제 색상을 사용하지 않습니다.
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # setaf를 지원하면 표준 터미널 색상 제어를 지원한다고 간주합니다.
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# xterm 계열에서는 제목에 사용자·호스트·경로를 표시합니다.
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# ls 색상 표시와 자주 쓰는 별칭을 설정합니다.
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# GCC 경고와 오류의 색상 표시 예제입니다.
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# 추가 ls 별칭입니다.
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# 오래 걸린 명령 뒤에 알림을 띄우는 별칭입니다. 사용 예:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# 추가 별칭은 ~/.bash_aliases에 분리할 수 있습니다.
# 예제는 bash-doc 패키지의 /usr/share/doc/bash-doc/examples를 참고합니다.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# 프로그래밍 가능한 자동완성을 활성화합니다.
# /etc/bash.bashrc에서 이미 활성화했다면 별도 설정이 필요하지 않을 수 있습니다.
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Codex 설치 프로그램이 추가한 사용자 실행 파일 경로 시작
export PATH="$HOME/.local/bin:$PATH"
# Codex 설치 프로그램이 추가한 사용자 실행 파일 경로 끝
