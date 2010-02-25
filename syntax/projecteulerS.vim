"プロファイル表示用syntax
syn match ProjectEulerCategory		"^.\{-1,15}:"he=e-1
syn match ProjectEulerSolved		"Solved[^:]"
syn match ProjectEulerUnsolved		"Unsolved[^:]"
syn match ProjectEulerID			"\d\+\t"he=e-1


hi link ProjectEulerSolved			Special
hi link ProjectEulerUnsolved		Constant
hi link ProjectEulerID				Underlined
hi link ProjectEulerCategory		Label
