#!/usr/bin/env python3

"""install_deps.py: a cyfaust dependency installation script
"""
import os
import platform

# ----------------------------------------------------------------------------
# constants

PLATFORM = platform.system()


# ----------------------------------------------------------------------------
# helper funcs

def getenv(key: str, default=False) -> bool:
    """convert '0','1' env values to bool {True, False}"""
    return bool(int(os.getenv(key, default)))

cmd = os.system

def mk_installer(prefix, install_cmd="install", update=True):
	def _installer(*pkgs):
		_pkgs = " ".join(pkgs)
		if update:
			cmd(f"{prefix} update")
		cmd(f"{prefix} install {_pkgs}")
	return _installer

pip_install = mk_installer(prefix="pip", install_cmd="install --upgrade", update=False)
brew_install = mk_installer(prefix="brew")
apt_install = mk_installer(prefix="sudo apt")

# ----------------------------------------------------------------------------
# options

sys_pkgs = []

py_pkgs = [
	"cython",
	"pytest",
	"wheel",
]


if PLATFORM == "Darwin":
	sys_pkgs.extend(["python", "cmake"])
	py_pkgs.append("delocate")

	print("install macos system dependencies")
	brew_install(*sys_pkgs)
	pip_install(*py_pkgs)

elif PLATFORM == "Linux":

	sys_pkgs.append("patchelf")
	py_pkgs.append("auditwheel")

	ALSA = getenv('ALSA', default=True)
	PULSE = getenv('PULSE')
	JACK = getenv('JACK')

	if ALSA:
		sys_pkgs.append("libasound2-dev")

	if PULSE:
		sys_pkgs.append("libpulse-dev")

	if JACK:
		sys_pkgs.append("libjack-jackd2-dev")

	print("install linux system dependencies")
	apt_install(*sys_pkgs)
	pip_install(*py_pkgs)

