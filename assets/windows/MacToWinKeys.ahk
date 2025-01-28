#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
SetNumLockState, On

; Remap to Ctrl
Capslock::Ctrl
LWin::Ctrl
; RWin::Ctrl

; Windows Key Combinations
#a::Send, ^a  ; Select all
#c::Send, ^c  ; Copy
#d::Send, ^d  ; Exit
#f::Send, ^f  ; Find
#s::Send, ^s  ; Save
#v::Send, ^v  ; Paste
#x::Send, ^x  ; Cut
#z::Send, ^z  ; Undo
#+z::Send, ^+z ; Redo
#/::Send, ^/  ; Comment
#+p::Send, ^+p ; Ctrl + Shift + p
#+i::Send, ^+i ; Ctrl + Shift + i


#Space::Send, #.  ; Emoji shortcut

; Arrow Key Enhancements
#Up::Send {PgUp}
#Down::Send {PgDn}
#Left::Send {Home}
#Right::Send {End}



return
