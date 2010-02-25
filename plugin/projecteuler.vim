"=============================================================================
" File: Projecteuler.vim
" Author: mfumi
" Email: m.fumi760@gmail.com
" Last Change: 25-02-2010 
" Version: 1.01
" Usage:
"
" 	:ProjectEuler [id]
" 		Problem <id> の解答をProjectEulerに投稿します。
"		idが指定されなかった場合はファイル名から推測、
"		それでも分らなかった場合尋ねます。
"
" 	:ProjectEuler -l [pagenr]
" 		問題のリストの1ページ目を表示します。
" 		pagenrを指定すればそのページのリストを表示します。
"
"	:ProjectEuler -p [id]
"		Probrem <id> の問題を表示します。
"		idが指定されなかった場合はファイル名から推測、
"		それでも分らなかった場合尋ねます。
"
"	:ProjectEuler -s
"		自分のプロファイルを表示します。
"
"	:ProjectEuler -c
"		現在開いている問題の言語を入れ替えます。
"
"	:ProjectEuler -o [id]
"		Probrem <id> の問題のページをブラウザで開きます。
"		idが指定されなかった場合はファイル名から推測、
"		それでも分らなかった場合尋ねます。
"
"	:ProjectEuler -u [username]
"		<username>にユーザーを切り替えます。
"		<username>が指定されなければ現在のユーザー名を表示します。
"
"	:ProjectEuler -r
"		現在のユーザーで強制的に再ログインします。
"		Vimを使用中にCookieの有効期限が切れてしまった時に行って下さい。
"
" 
" Variables:
" 	g:projecteuler_user
" 		ProjectEulerにログインするデフォルトのユーザー名
"
" 	g:projecteuler_base_dir
" 		ProjectEulerの問題およびCookieを保存するためのディレクトリ
" 		let g:projectuler_base_dir = "path-to/projecteuler/"
" 		みたいに設定して下さい。最後の/を忘れると正しく動作しません。
" 		デフォルトではプラグインのおかれたディレクトリから../projecteulerとなります
" 		このディレクトリはあらかじめ作成する必要があります
" 	
" 	g:projecteuler_browser_command
" 		ProjectEulerの問題等を閲覧するブラウザ
" 		let g:projecteuler_browser_command = "コマンド名 %URL% &"
" 		みたいに設定して下さい
" 		%URL%をを抜かすと正しく動作しません
"
" 	g:projecteuler_audio_play_command
" 		CAPTCHAの音声を再生するためのコマンド
" 		let g:projecteuler_audio_play_command = "コマンド名 %AUDIO% &"
" 		みたいに設定して下さい
" 		%AUDIO%をを抜かすと正しく動作しません
"
" 	g:projecteuler_hold_cookie
" 		ProjectEulerのCookieを保存するかどうか。
" 		0:保存しない	1:保存する
" 		デフォルトでは保存します
"
" 	g:projecteuler_see_next
" 		問題を正解したあと次の問題を表示するかどうか。
" 		0:表示しない	1:表示する
" 		デフォルトでは尋ねます
"
" 	g:projecteuler_open_forum
" 		問題を正解したあとフォーラムをブラウザで開くかどうか。
" 		0:開かない		1:開く
" 		デフォルトでは開きません
"
"	g:projecteuler_problem_lang
"		問題を取得・閲覧する際の言語を設定します。
"		let g:projecteuler_problem_lang = "ja"
"		とすれば日本語の問題文を取得・閲覧します
"		デフォルトでは英語です
"
"
"
"
" Bug:
" 	すでに正解している問題でも解答を送信できる(そのまま成否が判定される)

scriptencoding utf-8

"スクリプトの設定
if &cp || (exists('g:loaded_projecteuler_vim') && g:loaded_projecteuler_vim) "{{{
	finish
endif
let g:loaded_projecteuler_vim = 1


"curlの確認
if !executable('curl')
	echoerr "Projecteuler.vim: 'curl required'"
	finish
endif 


"ホームページを閲覧するブラウザ 
if !exists('g:projecteuler_browser_command')
	if has('win32')
		let g:projecteuler_browser_command = "!start rundll32 url.dll,FileProtocolHandler %URL%"
	elseif has('mac')
		let g:projecteuler_browser_command = "open %URL%"
	elseif executable('xdg-open')
		let g:projecteuler_browser_command = "xdg-open %URL%"
	else
		let g:projecteuler_browser_command = "firefox %URL% &"
	endif
endif


"音声を再生するコマンド(CAPTCHA用) 
if !exists('g:projecteuler_audio_play_command')
	if has('win32')
		let g:projecteuler_audio_play_command = '!start  "C:\Program Files\Windows Media Player\wmplayer.exe"  %AUDIO%'
	elseif has('mac')
		let g:projecteuler_audio_play_command = "open %AUDIO%"
	elseif executable('paplay')
		let g:projecteuler_audio_play_command = "paplay %AUDIO% &"
	endif
endif


"クッキーを保存するかどうか (1: 保存 0: Vim終了時に削除)
if !exists('g:projecteuler_hold_cookie')
	let g:projecteuler_hold_cookie = 1
endif


"問題文の言語 ("ja": 日本語  それ以外: 英語)
if !exists('g:projecteuler_problem_lang')
	let g:projecteuler_problem_lang = ""
endif


"解答正解後次の問題を見るかどうか (1: 見る 0: 見ない それ以外: 尋ねる)
if !exists('g:projecteuler_see_next')
	let g:projecteuler_see_next = -1
endif


"解答正解後フォーラムを開くがどうか (1:開く 0:開かない)
if !exists('g:projecteuler_open_forum')
	let g:projecteuler_open_forum = 0
endif


"問題の保存・クッキーの保存に使われるディレクトリ
"デフォルトではプラグインのおいてあるディレクトリから../projecteulerとなる
if !exists('g:projecteuler_dir')
	let g:projecteuler_dir = substitute(expand('<sfile>:p:h'), '[/\\]plugin$', '', '') 
	if has('win32')
		let g:projecteuler_dir = g:projecteuler_dir . '\projecteuler\'
	else
		let g:projecteuler_dir = g:projecteuler_dir . '/projecteuler/'
	endif
endif


"その他変数
let s:projecteuler_base_url = 'http://projecteuler.net/index.php?section='
let s:projecteuler_base_url_ja = 'http://odz.sakura.ne.jp/projecteuler/index.php?Problem\\%20'
let s:projecteuler_captcha_url = 'http://projecteuler.net/captcha/image_play.php'
let s:projecteuler_txt_url = 'http://projecteuler.net/project/'
let s:projecteuler_login = 0
let s:projecteuler_cookie_file = ''
let s:curl_cmd = 'curl --silent'
let s:projecteuler_login_user = []


"クッキーを削除するかどうか
if !g:projecteuler_hold_cookie
	autocmd VimLeave * call s:ProjectEulerDeleteCookie(s:projecteuler_login_user)
endif
" }}}


"ProjectEulerにログイン
"ログイン成功:クッキーファイルを返す
"ログイン失敗:空文字列を返す
function! s:ProjectEulerLogin() "{{{
	if !exists('g:projecteuler_user') 
		let g:projecteuler_user = input("ユーザー名を入力して下さい(Username): ")
	endif


	" クッキーを保存するファイル
	let cookie_file = g:projecteuler_dir . 'cookie_' . g:projecteuler_user


	" クッキーがある場合はクッキーでログインを試みる
	if filereadable(cookie_file)
		let reply = system(s:curl_cmd . ' "' . s:projecteuler_base_url . 'login" ' . ' -b "'.  cookie_file .'"')
		if reply =~ 'Logged in as'
			echo  g:projecteuler_user . 'でログインしてます '
			let s:projecteuler_login = 1
			call s:ProjectEulerAddUser()
			let s:projecteuler_cookie_file = cookie_file
			return 
		else
			call delete(cookie_file)
		endif
	endif

	" パスワードでログイン
	let password = inputsecret('パスワードを入力して下さい(Password): ')

	if !strlen(password)
		echo 'キャンセルしました(Cancelled)'
		return
	endif

	let content = system(s:curl_cmd . ' "' . s:projecteuler_base_url . 'login"' . ' -d "username=' . g:projecteuler_user . '" -d "password=' . password . '" -d "login=Login"'.  ' -c "' . cookie_file .'"')

	if content =~ 'Login successful'
		echo 'ログインしました(Login successful)'
		let s:projecteuler_login = 1
		call s:ProjectEulerAddUser()
		let s:projecteuler_cookie_file = cookie_file
	else
		echo 'ログインに失敗しました(Login failed)',"utf-8"
		let s:projecteuler_cookie_file = ''
		call delete(cookie_file)
	endif
endfunction "}}}


"ユーザーリストにユーザーを追加
"一度ログインしたユーザーはs:projecteuler_login_userに保存されます
"このリストはCookieの削除等に使われます
function! s:ProjectEulerAddUser() "{{{
	let user_exist = 0
	for i in s:projecteuler_login_user
		if i == g:projecteuler_user
			let user_exist = 1 | break
		endif
	endfor
	if user_exist == 0
		call add(s:projecteuler_login_user,g:projecteuler_user)
	endif
endfunction "}}}


"ProjectEulerに問題の回答を投稿
function! s:ProjectEulerPost(id) "{{{
	"ログイン処理
	if s:projecteuler_login == 0
		call s:ProjectEulerLogin()
		if strlen(s:projecteuler_cookie_file) == 0 |return| endif
	endif

	let id = s:ProjectEulerID(a:id , "回答する")
	if strlen(id) == 0 |return |endif

	"CAPTCHAの音声ファイルをダウンロード&再生
	let audio_file_save = g:projecteuler_dir . 'audio.wav'
	let audio_file = '"' . audio_file_save . '"'

	if !exists('g:projecteuler_audio_play_command')
		echo "CAPTCHA音声を再生するコマンドが指定されていません "
		echo "g:projecteuler_audio_play_command を設定して下さい "
		return
	endif

	"CAPTCHAの音声ファイルをダウンロード
	call system(s:curl_cmd . ' "' . s:projecteuler_captcha_url . '" -b "' . s:projecteuler_cookie_file . '" -c "' . s:projecteuler_cookie_file . '" -o' . audio_file )

	"音声ファイルを再生するためのコマンド
	"CAPTCHAの音声ファイルをダウンロード&再生
	if has('win32')
		let audio_file = substitute(audio_file,'\\','\\\\','g')
	endif
	let cmd = substitute(g:projecteuler_audio_play_command, '%AUDIO%',audio_file,'g')
	echo "問題" . id . "に解答します"
	"CAPTCHAの入力
	let confirm = ''
	while strlen(confirm) == 0
		"音声ファイルの再生
		"入力が空の場合再生&入力を繰り返す
		if cmd =~ '^!'
			silent! exec cmd
		else
			call system(cmd)
		endif
		let confirm = input("数字を入力して下さい(CAPTCHA): ")
	endwhile
	"解答の入力
	"入力が空の場合入力を繰り返す
	let guess = ''
	while strlen(guess) == 0
		let guess = input("解答を入力して下さい(GUESS): ")
	endwhile

	"解答を送信
	let reply = system(s:curl_cmd . ' "' . s:projecteuler_base_url . 'problems&id=' . id . '" -d "guess=' . guess . '" -d "confirm=' . confirm . '" -d "check=true"' . ' -b "' . s:projecteuler_cookie_file . '" -c "' . s:projecteuler_cookie_file . '"')

	call delete(audio_file_save)

	redraw!
	"成否を判定
	if reply =~ 'Congratulations'
		echo "\n正解です "
		"フォーラムをブラウザで開く
		if  g:projecteuler_open_forum == 1
			let url = '"' . s:projecteuler_base_url . 'forum\&id=' . id  . '"'
			call s:OpenURL(url)
		endif
		"次の問題文を見る
		if  g:projecteuler_see_next == 1
			call s:ProjectEulerProblem(id+1)
		elseif g:projecteuler_see_next != 0
			let next = input("次の問題を見ますか? [yes]: ")
			if strlen(next) == 0 || next =~ "^y"
				call s:ProjectEulerProblem(id+1)
			endif
		endif
	elseif reply =~ 'Sorry'
		echo guess . ' は不正解です '
	elseif reply =~ 'WARNING'
		echo '30秒待ってから投稿して下さい '
	else
		echo '入力したCAPTCHA用の数字が正しくありませんでした '
	endif
	return
endfunction "}}}


"ProjectEulerの問題のリストを表示
function! s:ProjectEulerList(pagenr) "{{{
	if strlen(a:pagenr) == 0
		let pagenr = 1
	else
		let pagenr = a:pagenr
	endif

	"ウィンドウを生成
	let winnum = bufwinnr(bufnr('ProjectEuler:List'))
	if winnum != -1
		if winnum != bufwinnr('%')
			exe "normal \<c-w>".winnum."w"
		endif
	else
		exec 'silent split ProjectEuler:List'
	endif
	setl modifiable
	setl noreadonly

	"問題のリストを取得
	silent %d _
	exec 'silent 0r!' . s:curl_cmd . ' "' . s:projecteuler_base_url . 'problems&page=' . pagenr . '"' 
	silent! %s/<\/b>/\t/g
	silent! %s/\(\d\+\)<\/div>/\t\1/g
	silent! %s/<sup>/^/g
	silent! %s/<.\{-}>//g
	silent! %s/&gt;/</g
	silent! %s/&lt;/</g
	silent! %s/&le;/<=/g
	silent! %s/&ge;/>=/g
	silent! %s/&times;/x/g
	silent! %s/&#8805;/>=/g
	silent! %s/&#8804;/<=/g
	silent! %s/&#8722;/-/g
	silent! %s/&#996;/phi/g
	silent! %s/&phi;/phi/g
	silent! %s/&#39;/'/g
	silent! %s/&rsquo;/'/g
	silent! %s/&quot;/"/g
	silent! %s/&minus;/-/g
	silent! %s/\^\(\w\+\/\)/\1/g
	silent! g/project/d
	silent! g/about/d
	silent! g/register/d
	silent! g/problems/d
	silent! g/login/d
	silent! g/title/d
	silent! g/-->/d
	silent! %s/\r//g
	silent! g/^\s*$/d
	silent! $s/\(\d\)/\1 /g
	silent! nohl
	normal gg
	setl ft=projecteuler
	setl nomodified
	setl nomodifiable
	setl readonly
	setl bufhidden=delete
	nnoremap <buffer> <silent> <CR> :call <SID>ProjectEulerOpenProblemFromList()<CR>
	return
endfunction "}}}


"ProjectEulerの問題を表示
"問題はg:projecteuler_dirに保存する
function! s:ProjectEulerProblem(id) "{{{
	let id = s:ProjectEulerID(a:id,"表示する ")
	if strlen(id) == 0 | return | endif

	"問題文の言語を決める
	if  g:projecteuler_problem_lang == "ja"
		let lang = "_ja"
		let url = s:projecteuler_base_url_ja . id
	else
		let lang = ""
		let url = s:projecteuler_base_url . 'problems&id=' . id
	endif

	"ウィンドウを生成
	exec 'silent! 15split ' 

	let problem = g:projecteuler_dir . 'Problem' . id . l:lang . '.txt'

	exec 'edit ' . problem

	"問題文がなければ取得
	if !filereadable(problem)
		silent %d _
		exec 'silent 0r!' . s:curl_cmd . ' "' . url .  '"'
		echo url
		if g:projecteuler_problem_lang == "ja"
			silent! %s/<\/td>\s*\n*/\t/g
			silent! %s/<\/tr>/\r/g
			silent! %s/<span[^>]\{-}super;">\(\d\+\)/^\1/g 
			silent! %s/<span[^>]\{-}sub;">\(\d\+\)/_\1/g 
			silent! g/<h5>/d
			silent! %s/<.\{-}>//g
			silent! g/^\s*$/d
			silent! g/Site/d
			silent! g/Puki/d
			silent! g/Power/d
			silent! g/Link/d
			silent! g/&nbsp/d
			silent! g/^\d\d\d\d-\d\d-\d\d/d
			silent! g/[[|]/d
			silent! g/http/d
			silent! %s/&dagger;//g
			silent! %s/&quot;/"/g
			silent! %s/&sup\(\w\);/^\1/g
			silent! %s/&amp;/\&/g
			silent! %s/^\s*//g
			silent! %s/&gt;/>/g
			silent! %s/&lt;/</g
			silent! %s/&le;/<=/g
			silent! %s/&ge;/>=/g
			silent! 0,21:d
		else
			silent! %s/<\/td>\s*\n*/\t/g
			silent! %s/<\/tr>/\r/g
			silent! %s/<sup>/^/g
			silent! %s/<sub>/_/g
			silent! %s/&nbsp;/ /g
			silent! %s/&amp;/\&/g
			silent! %s/&\([lg][et]\);/>\&\1;</g
			silent! %s/&times;/>x</g
			silent! %s/&minus;/>-</g
			silent! %s/<.\{-}>//g
			silent! %s/&gt;/>/g
			silent! %s/&lt;/</g
			silent! %s/&le;/<=/g
			silent! %s/&ge;/>=/g
			silent! %s/&sup2;/^2/g
			silent! %s/\^\(\w\+\/\)/\1/g
			silent! %s/\r//g
			silent! g/Project/d
			silent! g/About/d
			silent! g/Register/d
			silent! g/Login/d
			silent! g/Problems/d
			silent! g/--/d
			silent! g/^\s*$/d
		endif
		silent! write 
		silent! nohl
		normal! gg
	endif
	setl ft=projecteulerP
	setl nomodifiable
	setl readonly
	setl bufhidden=delete
	nohl
	nnoremap <buffer> <silent> <CR> :call <SID>ProjectEulerGetText()<CR>
	return
endfunction "}}}


"ProjectEulerの問題に必要なテキストを取得 
function! s:ProjectEulerGetText() "{{{
	let txt = matchstr(getline("."),'\w\+\.txt')
	let txtpos = match(getline("."),'\w\+\.txt')
	if txtpos != -1
		if col(".") > txtpos && col(".") <= txtpos + len(txt)
			call system( s:curl_cmd . ' "' . s:projecteuler_txt_url . txt . '" -o "' . g:projecteuler_dir . txt . '"')
			echo txt . "をダウンロードしました"
		endif
	endif
endfunction
"}}}


"ProjectEulerの問題をブラウザで開く
function! s:ProjectEulerOpen(id) "{{{
	let id = s:ProjectEulerID(a:id,"ブラウザで開く ")
	if strlen(id) == 0 | return | endif

	let url = '"' . s:projecteuler_base_url . 'problems\&id=' . id  . '"'
	call s:OpenURL(url)
	return
endfunction "}}}


"問題番号を特定する関数
function! s:ProjectEulerID(id,str) "{{{
	"idはファイル名から推測
	"推測できなかった場合は尋ねる
	if strlen(a:id) == 0
		let id = substitute(expand("%:r"),'\D','','g')
		if strlen(id) == 0
			let str = a:str . "問題番号を入力して下さい: "
			let id = input(str)
			if strlen(id) == 0
				echo "キャンセルしました"
			endif
		endif
		return id
	else
		return a:id
	endif
endfunction "}}}


"URLをブラウザで開く
function! s:OpenURL(url) "{{{
	let cmd = substitute(g:projecteuler_browser_command, '%URL%', a:url, 'g')
	if cmd =~ '^!'
		silent! exec  cmd
	else
		call system(cmd)
	endif
	return
endfunction "}}}


"プロファイルを表示
function! s:ProjectEulerProfile() "{{{
	"ログイン処理
	if s:projecteuler_login == 0
		call s:ProjectEulerLogin()
		if strlen(s:projecteuler_cookie_file) == 0 | return |endif
	endif

	"ウィンドウを生成
	let winnum = bufwinnr(bufnr('ProjectEuler:Profile'))
	if winnum != -1
		if winnum != bufwinnr('%')
			exe "normal \<c-w>".winnum."w"
		endif
	else
		exec 'silent split ProjectEuler:Profile'
	endif

	setl modifiable
	setl noreadonly

	silent %d _
	"プロファイルを取得
	exec 'silent 0r!' . s:curl_cmd . ' "' . s:projecteuler_base_url . 'profile"' . ' -b"' . s:projecteuler_cookie_file . '"'
	"整形 (結構強引…)
	silent! %s/<select[^>]*>.*<\/select>//g		"とりあえずセレクトタグ内を取り除く
	silent! %s/"\(Solved\|Unsolved\)"/>\1</g	"Solved / Unsolved をエスケープ
	silent! %s/&nbsp;/\r/g						"&nbspを改行に置換
	silent! %s/<\/t[rh]>/\r/g					"</tr>,</th>を改行に置換
	silent! %s/<.\{-}>//g						"タグを消去
	silent! %s/User Details\s*//g				"いらない行/文字を削除
	silent! %s/^\s*$//g
	silent! %s/&gt;/>/g
	silent! %s/&lt;/</g
	silent! g/^$/d
	silent! g/About/d
	silent! g/Problems/d
	silent! g/Contact/d
	silent! g/Scores/d
	silent! g/Profile/d
	silent! g/News/d
	silent! g/Statistics/d
	silent! g/Content/d
	silent! g/Log/d
	silent! g/Password/d
	silent! g/Country/d
	silent! g/--/d
	silent! g/Project/d
	silent! %s/\(Solved\)\s*$/\1\t\t/gI
	silent! %s/\(Unsolved\)\s*$/\1\t/gI
	silent! %s/:\n/:/g
	silent! %s/^\(\d\+\)/\1\t/g					
	call cursor(3,1)
	let l = (line("$") - 3) / 5
	let i = 0
	while i <= l+1
		normal! jJJJJ
		let i += 1 
	endwhile
	silent! %s/\(Level\)\s*\(\d\+\)/\r\1:\2/g
	normal! gg
	nohl
	setl nomodified
	setl nomodifiable
	setl readonly
	setl bufhidden=delete
	setl ft=projecteuler
	nnoremap <buffer> <silent> <CR> :call <SID>ProjectEulerOpenProblemFromProfile()<CR>
	return
endfunction "}}}


"プロファイル表示時にカーソル下、もしくは一番左に近い数字の問題文を開く関数
function! s:ProjectEulerOpenProblemFromProfile() "{{{
	let line = getline(".")
	if line !~ '^\d\+' 
		return
	endif

	while matchstr(getline("."),".",col(".")-1) !~  '\d\+'
		normal! B
	endwhile
	let id = matchstr(getline("."),'\d\+',col(".")-3)
	call s:ProjectEulerProblem(id)
	return
endfunction "}}}

"リスト表示時にカーソル位置にある行の問題番号の問題を表示する
"ページ番号の位置でこれを呼び出した場合そのページ番号に移動する
function! s:ProjectEulerOpenProblemFromList() "{{{
	let line = getline(".")
	if line !~ '^\d\+' && line !~ '^Page:'
		return
	endif

	if line =~ '^Page:'
		let pagenr = matchstr(getline("."),".",col(".")-1)
		if pagenr =~ '\d'
			call s:ProjectEulerList(pagenr)
		endif
	elseif line =~ '^\d'
		let id = matchstr(getline("."),'\d\+')
		echo id
		call s:ProjectEulerProblem(id)
	endif
	return
endfunction "}}}

"現在開いている問題文の言語を切り換える関数
function! s:ProjectEulerChangeProblem() "{{{
	let buflist = filter(range(1,bufnr("$")),'bufexists(v:val)')
	let bufexist = 0
	for bufnr in buflist
		if bufname(bufnr) =~ 'Problem\d\+'
			let winnum = bufwinnr(bufnr)
			if winnum != -1
				if winnum != bufwinnr('%')
					exe "normal \<c-w>".winnum."w"
				endif
				let bufexist = 1
				break
			endif
		endif
	endfor
	if bufexist == 0
		echo "問題が開かれてません"
		return
	endif

	let id = substitute(expand("%:r"),'\D','','g')
	let lang = g:projecteuler_problem_lang
	let g:projecteuler_problem_lang = (expand("%:r") =~ "ja" ? "" : "ja")
	call s:ProjectEulerProblem(id)
	let g:projecteuler_problem_lang = l:lang
endfunction "}}}


"クッキーを削除
function! s:ProjectEulerDeleteCookie(login_user) "{{{
	let cookie = g:projecteuler_dir . 'cookie_'

	for i in a:login_user
		let cookie_file = cookie . i
		call delete(cookie_file)
	endfor
endfunction "}}}


"関数本体
function! s:ProjectEuler(...) "{{{

	let arg  = a:0 > 1 ? a:2 : ''

	if(a:0 == 0)
		call s:ProjectEulerPost(arg)
	elseif(a:1 =~ '^\d\+$')
		call s:ProjectEulerPost(a:1)
	elseif(a:1 =~ '^-l$')
		call s:ProjectEulerList(arg)
	elseif(a:1 =~ '^-p$')
		call s:ProjectEulerProblem(arg)
	elseif(a:1 =~ '^-o$')
		call s:ProjectEulerOpen(arg)
	elseif(a:1 =~ '^-s$')
		call s:ProjectEulerProfile()
	elseif(a:1 =~ '^-c$')
		call s:ProjectEulerChangeProblem()
	elseif(a:1 =~ '^-r$')
		call s:ProjectEulerLogin()
	elseif(a:1 =~ '^-u$')
		if exists('g:projecteuler_user')
			if strlen(arg) == 0
				echo g:projecteuler_user
			else
				"ユーザーの切り替え
				"すでに一度ログインしてあればログイン処理は行わない
				let g:projecteuler_user = arg
				for i in s:projecteuler_login_user
					if i == g:projecteuler_user
						let s:projecteuler_cookie_file = g:projecteuler_dir . 'cookie_' . g:projecteuler_user
						return
					endif
				endfor
				let s:projecteuler_login = 0
			endif
		endif
	else
		echo "無効な引数です"
		return 
	endif
endfunction "}}}


"コマンドの定義
command! -nargs=* -range=% ProjectEuler :call s:ProjectEuler(<f-args>)

"vim: foldmethod=marker : fileencoding=utf-8 
