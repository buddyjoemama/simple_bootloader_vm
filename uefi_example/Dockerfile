# Dockerfile for building UEFI applications on macOS
FROM ubuntu:22.04

# Install build dependencies
RUN apt-get update && \
    apt-get install -y \
    gnu-efi \
    gcc \
    binutils \
    mtools \
    make \
    qemu-system-x86 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# Default command shows help
CMD ["make", "help"]
