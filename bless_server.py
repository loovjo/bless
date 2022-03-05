from typing import Optional

import sys
import time
import tty
import termios
import os
import platform
import subprocess
import signal

IS_ON_DARWIN = platform.system() == "Darwin"

_, bqn_pid_s, boci_path, bico_path, log_path, stdin_file, stdout_file = sys.argv
bqn_pid = int(bqn_pid_s)

log = open(log_path, "a")

log.write(f"[curs.py] Curs launched\n")
log.flush()

sys.stdout = open("/tmp/stdout", "w")
sys.stderr = open("/tmp/stderr", "w")

log.write(f"[curs.py] Redirected std{{out,err}}\n")
log.flush()

stdout = open(stdout_file, "w")
log.write(f"[curs.py] Acquired stdout\n")
log.flush()

stdin_no = os.open(stdin_file, os.O_RDONLY|os.O_NONBLOCK)

log.write(f"[curs.py] Acquired stdin\n")
log.flush()

boci = open(boci_path, "r")

log.write(f"[curs.py] Opened fifos\n")
log.flush()

current_cmd = ""

initial_stdin_state = termios.tcgetattr(stdin_no)


def read_ch() -> Optional[str]:
    ch = b''
    while True:
        try:
            ch += os.read(stdin_no, 1)
            if ch == b"\r":
                ch = b"\n"
            if ch == b'\x1a': # CTRL-Z, suspend
                os.kill(bqn_pid, signal.SIGSTOP)
            try:
                return ch.decode()
            except UnicodeDecodeError:
                continue
        except BlockingIOError:
            return None

def read_ch_blocking() -> str:
    while True:
        ch = read_ch()
        if ch is not None:
            return ch

def read_until_end() -> str:
    buf = ""
    while True:
        ch = read_ch()
        if ch is None:
            return buf
        buf += ch

in_buffer = ""

try:
    while True:
        inp = read_until_end()
        in_buffer += inp
        if len(inp) > 0:
            log.write(f"[curs.py] Got input {inp!r}. Buffer: {in_buffer!r}\n")


        data = boci.read()
        if data == "":
            try:
                os.kill(bqn_pid, 0)
            except ProcessLookupError:
                log.write(f"[curs.py] BQN died\n")
                break
            time.sleep(0.001)
            continue

        log.write(f"[curs.py] Got data {data!r}\n")
        log.flush()

        current_cmd += data

        if current_cmd.count("\x00") == 0:
            continue

        cmds = current_cmd.split("\x00")
        current_cmd = cmds[-1]
        cmds = cmds[:-1]

        for cmd in cmds:
            log.write(f"[curs.py] Running command {cmd!r}\n")
            parts = cmd.split(" ")
            if parts[0] == "write_bytes":
                stdout.write("".join(map(lambda x: chr(int(x)), parts[1:])))
                stdout.flush()

            if parts[0] == "start":
                tty.setraw(stdin_no)
                tty.setcbreak(stdin_no)
                log.write(f"[curs.py] Rawed stdin\n")

            if parts[0] == "clear":
                log.write(f"[curs.py] Clearing screen\n")
                stdout.write("\x1b[2J")
                stdout.flush()

            if parts[0] == "getsize":
                if IS_ON_DARWIN: # most compliant darwin command
                    proc = subprocess.Popen(["stty", "-f", stdin_file, "size"], stdout=subprocess.PIPE)
                else:
                    proc = subprocess.Popen(["stty", "-F", stdin_file, "size"], stdout=subprocess.PIPE)

                size_st, _ = proc.communicate()
                print(size_st, stdin_file)
                width, height = [int(s.decode()) for s in size_st.split(b" ")]
                with open(bico_path, "w") as bico:
                    bico.write(f"{width} {height}")

                log.write(f"[curs.py] Dimensions: {width}x{height}\n")

            if parts[0] == "puttext":
                x = int(parts[1])
                y = int(parts[2])
                text = "".join(map(lambda x: chr(int(x)), parts[3:]))
                log.write(f"[curs.py] Putting text at {(x, y)}: {text!r}\n")
                stdout.write(f"\x1b[{y+1};{x+1}H{text}")
                stdout.flush()

            if parts[0] == "readchar_block":
                if len(in_buffer) > 0:
                    ch = in_buffer[0]
                    in_buffer = in_buffer[1:]
                else:
                    ch = read_ch_blocking()

                log.write(f"[curs.py] Got char {ch!r}\n")
                log.flush()
                with open(bico_path, "w") as bico:
                    bico.write(str(ord(ch)))

            if parts[0] == "readstr":
                log.write(f"[curs.py] Sending {in_buffer!r} \n")
                log.flush()
                with open(bico_path, "w") as bico:
                    bico.write(" ".join(str(int(ord(ch))) for ch in in_buffer))
                in_buffer = ""
finally:
    log.write(f"[curs.py] Resetting STDIN\n")
    termios.tcsetattr(stdin_no, termios.TCSADRAIN, initial_stdin_state)

log.write(f"[curs.py] Done\n")
