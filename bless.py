import subprocess
import tempfile
import os, sys
import time

bqn_pid = os.getppid()

# find stdin and stdout of parent process

lsof = subprocess.Popen(["lsof", "-Ffn", f"-p{bqn_pid}"], stdout=subprocess.PIPE)
data, _ = lsof.communicate()
data_lines = data.split(b"\n")

# parse lines
stdin_file = None
stdout_file = None
for thing, data in zip(data_lines[:-1], data_lines[1:]):
    if thing == b"f0": # fd0 = stdin
        assert data[0:1] == b"n" # n = name
        stdin_file = data[1:]
    if thing == b"f1": # fd1 = stdout
        assert data[0:1] == b"n" # n = name
        stdout_file = data[1:]

if stdin_file is None:
    print("Could not find stdin!", file=sys.stderr)
    exit()

if stdout_file is None:
    print("Could not find stdout!", file=sys.stderr)
    exit()

temp_dir = tempfile.mkdtemp()
# boci = bqn out, curses in
boci = os.path.join(temp_dir, "boci")
bico = os.path.join(temp_dir, "bico")
log = os.path.join(temp_dir, "log")

os.mkfifo(bico)
os.mkfifo(boci)

with open(log, "w") as logf:
    logf.write(f"[start.py] Started\n")
    logf.write(f"[start.py] stdin_file = {stdin_file!r}\n")
    logf.write(f"[start.py] stdout_file = {stdout_file!r}\n")
    logf.write(f"[start.py] temp_dir = {temp_dir!r}\n")
    logf.write(f"[start.py] boci = {boci!r}\n")
    logf.write(f"[start.py] bico = {bico!r}\n")

sys.stdout.write(boci + '\x00' + bico + '\x00' + log)

p = subprocess.Popen(
    ["python3", "bless_server.py", str(bqn_pid), boci, bico, log, stdin_file.decode(), stdout_file.decode()],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
)
