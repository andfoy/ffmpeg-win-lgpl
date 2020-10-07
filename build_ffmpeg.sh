#! /bin/bash
set -exou

# Create output folder
mkdir -p ffmpeg_output

# Set MXE environment variables
export PATH=$(pwd)/mxe/usr/bin:$(pwd)/mxe/usr/x86_64-pc-linux-gnu/bin:$PATH
MXE_DIR = $(pwd)/mxe/usr/x86_64-w64-mingw32.shared

# Download FFmpeg
wget https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.gz
tar -xvzf ffmpeg-$FFMPEG_VERSION.tar.gz
pushd ffmpeg-$FFMPEG_VERSION

# Configure FFmpeg
./configure \
--arch=x86_64 \
--target-os=mingw32 \
--cross-prefix=x86_64-w64-mingw32.shared- \
--disable-doc \
--disable-openssl \
--enable-avresample \
--enable-gnutls \
--enable-hardcoded-tables \
--enable-libfreetype \
--enable-libopenh264 \
--enable-pic \
--disable-w32threads \
--enable-shared \
--disable-static \
--enable-version3 \
--enable-zlib \
--enable-libmp3lame

# Compile FFmpeg
make

# Install FFmpeg to output folder
make DESTDIR=../ffmpeg_output install
popd

# Rearrange binary distribution
pushd ffmpeg_output
mv usr/local/* .
rm -rf usr
mv bin/*.lib lib/

# Copy all dependent DLLs
cd bin/
for f in *.{dll,exe}; do
    for d in $(peldd $f); do
        echo "$f: $d"
        if [[ -f "$(pwd)/$d" ]]; then
            echo "Library $d is already part of FFmpeg"
        else
            for l in $(find $MXE_DIR -name $d); do
                echo "Library $d found at: $l"
                cp $l .
            done
        fi
    done
done
