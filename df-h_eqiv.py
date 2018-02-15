import shlex
import subprocess
cmd = "df -h"
subprocess.check_call(shlex.split(cmd))