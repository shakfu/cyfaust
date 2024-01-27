#!/usr/bin/env python3

import os
import sys
import pydoc
from pathlib import Path

BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "build")
sys.path.insert(0, BUILD_PATH)

def write_html_doc(variant, module):
	name = module.__name__
	folder = Path("docs/tmp")
	if not folder.exists():
		folder.mkdir()
	out_file = folder / f"{variant}.{name}.html"
	with open(out_file, "w") as f:
		html = pydoc.render_doc(module, renderer=pydoc.html)
		f.write(html)

try:
    from cyfaust import cyfaust
    write_html_doc("static", cyfaust)
except (ModuleNotFoundError, ImportError):
    from cyfaust import interp
    from cyfaust import signal
    from cyfaust import box
    for mod in [interp, signal, box]:
        write_html_doc("dynamic", mod)
