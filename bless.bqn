# Converts an array of numbers to a space separated string
Arr2Msg ← 1⊸↓ ∘ ∾ ∘ ((" "˙∾•Fmt)¨)

# Inverts Arr2Msg
Msg2Arr ← •BQN¨ ∘ ((⊢-˜+`×¬)∘(' '⊸=) ⊔ ⊢)


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
        boci •FBytes 𝕩∾<@
    }
    Recv ← {𝕤
        •FChars bico
    }

    # Sets terminal mode to raw + cbreak
    Start ⇐ Send⟜"start"

    # Clears screen
    Clear ⇐ Send⟜"clear"

    PutText ⇐ {x‿y F text:
        Send "puttext " ∾ (Arr2Msg x‿y) ∾ " " ∾ (Arr2Msg @-˜text)
    }

    MoveCursor ⇐ {F x‿y:
        Send "puttext " ∾ (Arr2Msg x‿y)
    }

    # Reads one char. Blocks if no character is available.
    # Input is buffered, so if mulitple chars are typed before this function is called, only the first one will be returned, then the second one etc.
    ReadChar ⇐ {𝕤
        Send "readchar_block"
        @+•BQN Recv @
    }

    # Dumps the entire input buffer
    ReadText ⇐ {𝕤
        Send "readstr"
        @+Msg2Arr Recv @
    }
}
