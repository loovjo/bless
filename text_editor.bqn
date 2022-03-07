bless←•Import "bless.bqn"

c ← bless.Curses@
c.Start@
c.Clear@

lines ← ⟨"line 1", "line 2", "more text", "last line"⟩
cursor ← 0‿0


Redraw ← {𝕤
    c.Clear @
    c.CursorHide@
    c.Style "bold"

    ⟨w,h⟩ ← c.Size @
    {𝕩‿0 c.PutText "-"⋄𝕩‿(h-1) c.PutText "-"}¨ 1+↕(w-2)
    {0‿𝕩 c.PutText "|"⋄(w-1)‿𝕩 c.PutText "|"}¨ 1+↕(h-2)
    0‿0 c.PutText "+"
    (w-1)‿0 c.PutText "+"
    0‿(h-1) c.PutText "+"
    (w-1)‿(h-1) c.PutText "+"

    x_offset ← 6
    y_offset ← 1

    {F l‿y:
        lineNo ← (•Fmt y+1)∾" ~"
        c.Style "bold"
        (x_offset-1+≠lineno)‿(y+1) c.PutText lineNo
        c.Style "reset"
        6‿(y+y_offset) c.PutText l
    }˘ lines∾˘↕≠lines

    c.MoveCursor cursor+x_offset‿y_offset
    c.CursorHide⁼@
}

ReAlign ← {𝕤
    ⟨x,y⟩ ← cursor
    y ↩ 0⌈(1-˜≠lines)⌊y
    x ↩ 0⌈(≠y⊑lines)⌊x
    cursor ↩ ⟨x,y⟩
}

RunKey ← {
    F c : c > ¯1 ?
        ⟨x,y⟩ ← cursor
        lines ((x⊸↑)∾(@+c)˙∾(x⊸↓))⌾(y⊸⊑)↩
        cursor +⟜1‿0↩
    ;
    F k : (k = bless.keys.backspace) ∧ (0 = ⊑cursor) ?
        ⟨x,y⟩ ← cursor
        line_here ← y⊑lines
        prev_line ← (y-1)⊑lines
        lines ↩ ((y-1)↑lines) ∾ (⋈ prev_line ∾ line_here) ∾ ((y+1)↓lines)
        cursor ↩ (≠prev_line)‿(y-1)
    ;
    F k : k = bless.keys.backspace ?
        ⟨x,y⟩ ← cursor
        lines (((x-1)⊸↑)∾(x⊸↓))⌾(y⊸⊑)↩
        cursor +⟜¯1‿0↩
    ;
    F k : k = bless.keys.return ?
        ⟨x,y⟩ ← cursor
        line ← y⊑lines
        lines ↩ (y↑lines) ∾ (⋈x↑line) ∾ (⋈x↓line) ∾ ((y+1)↓lines)
        cursor ↩ 0‿(y+1)
    ;
    F k : k = bless.keys.up    ? cursor +⟜0‿¯1↩ ⋄ ReAlign @;
    F k : k = bless.keys.down  ? cursor +⟜0‿ 1↩ ⋄ ReAlign @;
    F k : k = bless.keys.left  ? cursor +⟜¯1‿0↩ ⋄ ReAlign @;
    F k : k = bless.keys.right ? cursor +⟜ 1‿0↩ ⋄ ReAlign @;
    F x : @
}

# Main loop
{𝕤
    Redraw @
    c.Flush@

    k ← c.ReadKey@

    RunKey k

    𝕊⍟(k≠bless.keys.esc)@
}@

c.Stop@
