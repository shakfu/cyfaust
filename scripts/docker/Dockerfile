FROM debian:bookworm-slim

RUN apt update && apt install -y \
	cmake \
	build-essential \
	git \
    python3 \
	python3-dev \
    python3-pip \
    # debian-linux requirements
    libasound2-dev \
    patchelf \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /
RUN git clone --depth 1 https://github.com/shakfu/cyfaust.git

WORKDIR /cyfaust
RUN pip3 install --break-system-packages -r requirements.txt
RUN make && rm -rf build/downloads

RUN echo "alias ls='ls --color=auto'" > /root/.bashrc && \
    echo "alias ls='ls --color=auto -lh'" >> /root/.bashrc && \
    echo "alias la='ls --color=auto -a'" >> /root/.bashrc

CMD ["bash"]

# build: docker build -t cyfaust:bookworm .
# run: docker run -it --rm cyfaust:bookworm