# Converts an array of numbers to a space separated string
Arr2Msg ← 1⊸↓ ∘ ∾ ∘ ((" "˙∾•Fmt)¨)

# Inverts Arr2Msg
Msg2Arr ← •BQN¨ ∘ ((⊢-˜+`×¬)∘(' '⊸=) ⊔ ⊢)

keys ⇐ {
    broken ⇐ ¯1
    esc ⇐ ¯2
    return ⇐ ¯3
    backspace ⇐ ¯4
    up ⇐ ¯101
    down ⇐ ¯102
    left ⇐ ¯103
    right ⇐ ¯104
}

Key2Str ⇐ {
    F x : x > ¯1 ? @+x ;
    F ¯1 : "BROKEN" ;
    F ¯2 : "ESC" ;
    F ¯3 : "RETURN" ;
    F ¯4 : "BACKSPACE" ;
    F ¯101 : "UP" ;
    F ¯102 : "DOWN" ;
    F ¯103 : "LEFT" ;
    F ¯104 : "RIGHT" ;
    F x : "(unknown)"
}

Curses ⇐ {𝕤
    ⟨exit_status, stdout, stderr⟩ ← •SH "python3"‿"bless.py"
    •Delay 0.05 # hopefully the fifos will be opened and stuff

    {𝕤
        •Out "bless.py error"
        •Out "== stderr =="
        •Out stderr
        •Out "== =="
        "internal bless.py error" ! 1
    }⍟(exit_status≠0)@

    null ← stdout=@
    boci ⇐ (0=+`null)/stdout
    bico ⇐ (1=null-˜+`null)/stdout
    logf ⇐ (2=null-˜+`null)/stdout

    Send ← {
        boci •FBytes 𝕩∾⋈@
    }
    Recv ← {𝕤
        •FChars bico
    }

    # Sets terminal mode to raw + cbreak
    Start ⇐ Send⟜"start"
    Stop ⇐ {𝕤
        Send "stop"
        Recv @
    }

    Flush ⇐ Send⟜"flush"

    # Clears screen
    Clear ⇐ Send⟜"clear"

    PutText ⇐ {
    x‿y F ⟨⟩:
        Send "puttext " ∾ (Arr2Msg x‿y)
    ;
    x‿y F text:
        Send "puttext " ∾ (Arr2Msg x‿y) ∾ " " ∾ (Arr2Msg @-˜text)
    }

    MoveCursor ⇐ {F x‿y:
        Send "puttext " ∾ (Arr2Msg x‿y)
    }

    # Defaults to setting foreground. If 𝕨 = 1, sets background
    Foreground ⇐ {
    F r‿g‿b:
        Send "style color_foreground " ∾ (Arr2Msg r‿g‿b)
    ;
    0 F r‿g‿b:
        Send "style color_foreground " ∾ (Arr2Msg r‿g‿b)
    ;
    1 F r‿g‿b:
        Send "style color_background " ∾ (Arr2Msg r‿g‿b)
    }

    Style ⇐ {
    F "reset":
        Send "style reset"
    ;
    F "bold":
        Send "style bold"
    ;
    F "underline":
        Send "style underline"
    }

    # Run inveres to show cursor
    CursorHide ⇐ {
    𝕊:
        Send "style nocursor"
    ;
    𝕊⁼:
        Send "style recursor"
    }

    Size ⇐ {𝕤
        Send "getsize"
        Msg2Arr Recv @
    }

    # Reads one char. Blocks if no character is available.
    # Input is buffered, so if mulitple chars are typed before this function is called, only the first one will be returned, then the second one etc.
    ReadKey ⇐ {𝕤
        Send "readchar_block"
        •BQN Recv @
    }

    # Dumps the entire input buffer. Non-blocked
    ReadKeys ⇐ {𝕤
        Send "readstr"
        Msg2Arr Recv @
    }
}
