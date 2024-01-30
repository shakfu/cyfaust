#!/usr/bin/env python3

import os
import sys
import platform

PYTHON = sys.executable
PLATFORM = platform.system()

cmd = os.system

print("creating virtualenv 'venv' and installing cyfaust..")

if PLATFORM in ["Linux", "Darwin"]:
	cmd("virtualenv venv && source venv/bin/activate && pip install -e .")

elif PLATFORM == "Windows":
	cmd(f'virtualenv -p "{PYTHOON}" && venv\\bin\\activate && pip install -e .')

else:
	raise SystemExit("platform not supported")
