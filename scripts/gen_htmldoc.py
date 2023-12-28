import pydoc

import cyfaust


with open("cyfaust.html", "w") as f:
	html = pydoc.render_doc(cyfaust, renderer=pydoc.html)
	f.write(html)


