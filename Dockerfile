# syntax=docker.io/docker/dockerfile:1
FROM --platform=linux/riscv64 cartesi/python:3.10-slim-jammy

ARG MACHINE_EMULATOR_TOOLS_VERSION=0.14.1
ADD https://github.com/cartesi/machine-emulator-tools/releases/download/v${MACHINE_EMULATOR_TOOLS_VERSION}/machine-emulator-tools-v${MACHINE_EMULATOR_TOOLS_VERSION}.deb /
RUN dpkg -i /machine-emulator-tools-v${MACHINE_EMULATOR_TOOLS_VERSION}.deb \
  && rm /machine-emulator-tools-v${MACHINE_EMULATOR_TOOLS_VERSION}.deb

LABEL io.cartesi.rollups.sdk_version=0.6.2
LABEL io.cartesi.rollups.ram_size=128Mi


ARG DEBIAN_FRONTEND=noninteractive
RUN <<EOF
set -e
apt-get update
apt-get install -y --no-install-recommends \
  build-essential \
  busybox-static=1:1.30.1-7ubuntu3 \
  tesseract-ocr \
  libopenblas-dev 
rm -rf /var/lib/apt/lists/* /var/log/* /var/cache/*
useradd --create-home --user-group dapp
apt-get clean
EOF



ENV PATH="/opt/cartesi/bin:${PATH}"

WORKDIR /opt/cartesi/dapp
COPY ./requirements.txt .




COPY aadhar.jpg .


#pip install ninja==1.11.1.1 --index-url https://think-and-dev.github.io/riscv-python-wheels/pip-index
#pip install opencv_python==4.8.1.78 --index-url https://think-and-dev.github.io/riscv-python-wheels/pip-index

RUN <<EOF
set -e
pip install -r requirements.txt --no-cache
pip install numpy==1.26.2 --index-url https://think-and-dev.github.io/riscv-python-wheels/pip-index
pip install pillow==10.1.0 --index-url https://think-and-dev.github.io/riscv-python-wheels/pip-index
pip install pytesseract==0.3.10 --index-url https://think-and-dev.github.io/riscv-python-wheels/pip-index


find /usr/local/lib -type d -name __pycache__ -exec rm -r {} +
EOF


COPY ./dapp.py .

ENV ROLLUP_HTTP_SERVER_URL="http://127.0.0.1:5004"

ENTRYPOINT ["rollup-init"]
CMD ["python3", "dapp.py"]
