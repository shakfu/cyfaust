#!/usr/bin/env python3

import os
import sys
import platform

PYTHON = sys.executable
PLATFORM = platform.system()

cmd = os.system

print("creating virtualenv 'venv' and installing cyfaust..")

get_ver = "from cyfaust import interp; print(interp.get_version())"

if PLATFORM in ["Linux", "Darwin"]:
	cmd(f"virtualenv venv && source venv/bin/activate && pip install -e . && python -c '{get_ver}' ")

elif PLATFORM == "Windows":
	cmd(f'virtualenv -p "{PYTHOON}" && venv\\bin\\activate && pip install -e .')

else:
	raise SystemExit("platform not supported")
