" 별도 Vim 프로세스의 빈 버퍼에서 사용자가 실제 쓰는 기능을 점검합니다.
set nomore
set noswapfile
set nobackup
set nowritebackup
enew
setfiletype markdown
call assert_equal(2, exists(':MarkdownPreview'), '미리보기 명령이 없습니다.')
call assert_equal(':MarkdownPreview<CR>', maparg(' p', 'n'), 'Space p 연결이 다릅니다.')
call assert_equal('en_us,cjk', &l:spelllang, '한글 예외가 설정되지 않았습니다.')
call assert_equal(2, exists(':Tabularize'), '표 정렬 명령이 없습니다.')
call setline(1, ['| a | b |', '| longer | c |'])
1,2Tabularize /|
call assert_equal(stridx(getline(1), '|', 1), stridx(getline(2), '|', 1), '표의 두 번째 구분선이 정렬되지 않았습니다.')
if !empty(v:errors)
  for dotfiles_error in v:errors
    echomsg dotfiles_error
  endfor
  cquit 1
endif
qa!
