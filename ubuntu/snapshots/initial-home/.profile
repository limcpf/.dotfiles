# 로그인 셸에서 실행하는 ~/.profile입니다.
# ~/.bash_profile이나 ~/.bash_login이 있으면 Bash는 이 파일을 읽지 않습니다.
# 예제는 bash-doc 패키지의 /usr/share/doc/bash/examples/startup-files를 참고합니다.

# 기본 umask는 /etc/profile에서 설정합니다.
# SSH 로그인에도 적용하려면 libpam-umask 패키지를 설정합니다.
#umask 022

# Bash에서 실행한 경우입니다.
if [ -n "$BASH_VERSION" ]; then
    # .bashrc가 있으면 불러옵니다.
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# 사용자 bin 디렉터리가 있으면 PATH에 추가합니다.
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# 사용자 .local/bin 디렉터리가 있으면 PATH에 추가합니다.
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
