CYAN="\x1b[36m"
GREEN="\x1b[32m"
GREEN="\x1b[32m"
BOLD="\x1b[1m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_CYAN="\033[1;36m"
RESET="\x1b[0m"

line="-"*79

import os

def print_line():
    print(f"{BOLD}{line}{RESET}")

def print_section(msg):
    print_line()
    print(f"{BOLD_CYAN}>> {msg}{RESET}")

def print_entry(msg):
    print_line()
    print(f"{BOLD}{msg}{RESET}")

def save_to_output_dir(filename, content):
    output_dir = os.path.join('tests', 'output')
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
    target = os.path.join(output_dir, filename)
    with open(target, 'w') as f:
        f.write(content)