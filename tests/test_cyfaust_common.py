import os, sys



try:
    from cyfaust.common import ParamArray, PACKAGE_RESOURCES
except (ModuleNotFoundError, ImportError):
    from cyfaust.cyfaust import ParamArray, PACKAGE_RESOURCES

from testutils import print_section, print_entry


def test_param_array():
	ps = ("a", "b", "c")
	p = ParamArray(ps)
	assert p.as_list() == ["a", "b", "c"] + list(PACKAGE_RESOURCES)


if __name__ == '__main__':
    print_section("testing cyfaust.common")
    test_param_array()
