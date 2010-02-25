"問題表示用syntax
scriptencoding utf-8
syn case ignore
syn match ProjectEulerProblem		"^Problem \d\+\s*$"
syn match ProjectEulerDate			"^\d\d \u\l\+ \d\d\d\d$"
syn match ProjectEulerDate			".*\d\d\d\d-\d\d-\d\d.*"
syn match ProjectEulerText			"\w\+\.txt"
syn match ProjectEulerNote			"^Note:"he=e-1
syn match ProjectEulerNote			"^注:"he=e-1
syn match ProjectEulerHint			"^HINT:"he=e-1
syn match ProjectEulerHint			"^ヒント:"he=e-1


hi link ProjectEulerProblem			Constant
hi link ProjectEulerDate			Underlined
hi link ProjectEulerText			Constant
hi link ProjectEulerNote			Todo
hi link ProjectEulerHint			Todo


"vim : fileencoding = utf8 : ts = 4
