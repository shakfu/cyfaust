FROM debian:bookworm-slim

RUN apt update && apt install -y \
	cmake \
	build-essential \
	git \
	python3-dev


WORKDIR /
RUN git clone --depth 1 https://github.com/shakfu/cyfaust.git
WORKDIR /cyfaust
RUN pip install -r requirements.txt
RUN make

CMD ["/usr/env bash"]
