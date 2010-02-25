syn case ignore
syn match ProjectEulerSolved		"Solved[^:]"
syn match ProjectEulerUnsolved		"Unsolved[^:]"
syn match ProjectEulerCategory		"^.\{-1,15}:"he=e-1
syn match ProjectEulerID			"\d\+\t"he=e-1
syn match ProjectEulerSolvedBy		"\t\d\+"


hi link ProjectEulerSolved			Special
hi link ProjectEulerUnsolved		Constant
hi link ProjectEulerCategory		Label
hi link ProjectEulerID				Underlined
hi link ProjectEulerSolvedBy		Special
hi link ProjectEulerProblem			Constant
hi link ProjectEulerDate			Underlined
hi link ProjectEulerText			Constant
hi link ProjectEulerNote			Todo
hi link ProjectEulerHint			Todo

"vim : fileencoding = utf8 : ts = 4
