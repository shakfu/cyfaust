import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build'))



try:
    from cyfaust.common import ParamArray, PACKAGE_RESOURCES
except ImportError:
    from cyfaust import ParamArray, PACKAGE_RESOURCES

from testutils import print_section, print_entry


def test_param_array():
	ps = ("a", "b", "c")
	p = ParamArray(ps)
	assert p.as_list() == ["a", "b", "c"] + list(PACKAGE_RESOURCES)


if __name__ == '__main__':
    print_section("testing cyfaust.common")
    test_param_array()
