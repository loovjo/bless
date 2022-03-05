bless←•Import "bless.bqn"


c ← bless.Curses@
c.Start @
c.Clear @

⟨w,h⟩ ← c.Size@

4‿4 c.PutText "terminal is " ∾ (•Fmt w) ∾ "x" ∾ (•Fmt h) ∾ " in size :3"

4‿5 c.PutText "please enter char nya∾"
c.MoveCursor 0‿0
ch ← c.ReadKey @
4‿6 c.PutText "you entered " ∾ bless.Key2Str ch
c.MoveCursor 4‿7
•Delay 1

4‿7 c.PutText "now type a lot of text! "
c.MoveCursor 4‿8
•Delay 3

typed ← c.ReadKeys @
4‿8 c.PutText "you typed " ∾ (bless.Key2Str¨ typed) ∾ "!!!!"
c.MoveCursor 4‿10

•Delay 1

c.Clear @

0‿0 c.PutText "key logger "
y ← 1
{𝕤
    ch ← c.ReadKey @

    0‿y c.PutText "key: " ∾ (•Fmt bless.Key2Str ch) ∾ " = dec " ∾ (•Fmt ch)
    y 1⊸+↩

    𝕊⍟(ch≠bless.keys.esc)@
}@
