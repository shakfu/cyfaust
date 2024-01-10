CWD=`pwd`
BUILD=${CWD}/build
DOWNLOADS=${BUILD}/downloads
PYTHON=${CWD}/python # local destination
PYTHON_URL=https://www.python.org/ftp/python/3.11.7/Python-3.11.7.tar.xz
PYTHON_ARCHIVE=`basename ${PYTHON_URL}`
PYTHON_FOLDER=`basename -s .tar.xz ${PYTHON_ARCHIVE}`
CONFIG_OPTS="--enable-shared --disable-test-modules --without-static-libpython --with-ensurepip=no"

mkdir -p ${PYTHON} && \
	mkdir -p ${DOWNLOADS} && \
	cd ${DOWNLOADS} && \
	wget ${PYTHON_URL} && \
	tar xvf ${PYTHON_ARCHIVE} && \
	cd ${PYTHON_FOLDER} && \
	mkdir debug && \
	cd debug && \
	../configure --prefix ${PYTHON} \
				 --with-pydebug \
				 --enable-shared \
				 --disable-test-modules \
				 --without-static-libpython && \
	make EXTRA_CFLAGS="-DPy_DEBUG" && \
	make altinstall && \
	./python/bin/pip3 install cython memray pytest delocate
