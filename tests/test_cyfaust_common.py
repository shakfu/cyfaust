import os, sys
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

from cyfaust.common import ParamArray

from testutils import print_section, print_entry


def test_param_array():
	ps = ("a", "b", "c")
	p = ParamArray(ps)
	assert p.as_list() == ["a", "b", "c"]


if __name__ == '__main__':
    print_section("testing cyfaust.common")
    test_param_array()
