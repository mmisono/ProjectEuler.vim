"リスト表示用syntax
syn case ignore
syn match ProjectEulerID			"^\d\+\t"he=e-1
syn match ProjectEulerSolvedBy		"\d\+$"
syn match projectEulerPage			"^Page:"he=e-1


hi link ProjectEulerPage			Label
hi link ProjectEulerSolvedBy		Special
hi link ProjectEulerID				Underlined

"vim : fileencoding = utf8 : ts = 4
