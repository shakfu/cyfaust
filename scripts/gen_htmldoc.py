#!/usr/bin/env python3

import os
import sys
import pydoc
from pathlib import Path

BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "build")
sys.path.insert(0, BUILD_PATH)


head = """\
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>{}</title>
	<link rel="stylesheet" href="styles.css">
</head>
<body>
"""

footer = """\
</body>
</html>
"""

css = """\
body {
	font-family: monospace;
}
"""


def get_folder(variant, base="docs/api"):
	folder = Path(base) / variant
	if not folder.exists():
		folder.mkdir(parents=True)
	return folder

def cleanup(text):
	text = text.replace(BUILD_PATH, ".")
	build_path = str(Path(BUILD_PATH)) # normalize it
	text = text.replace(build_path, '.')
	return text

def write_css(variant):
	folder = get_folder(variant)
	css_file = folder / "styles.css"
	with open(css_file, "w") as f:
		f.write(css)

def write_html_doc(variant, module):
	name = module.__name__
	folder = get_folder(variant)
	html_file = folder / f"{name}.html"
	with open(html_file, "w") as f:
		body = pydoc.render_doc(module, title='<h2>%s</h2>', renderer=pydoc.html)
		html = head.format(name) + body + footer
		html = cleanup(html)
		f.write(html)

try:
    from cyfaust import cyfaust
    write_css("static")
    write_html_doc("static", cyfaust)
    print("generated static api docs")
except (ModuleNotFoundError, ImportError):
    from cyfaust import common
    from cyfaust import interp
    from cyfaust import signal
    from cyfaust import box
    write_css("dynamic")
    for mod in [common, interp, signal, box]:
        write_html_doc("dynamic", mod)
    print("generated dynamic api docs")

