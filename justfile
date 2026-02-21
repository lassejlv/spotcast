set shell := ["zsh", "-cu"]

run:
    ./run.sh

build:
    swift build

build-release:
    swift build -c release

dmg version="1.0" arch=`uname -m`:
    ./build-dmg.sh {{version}} {{arch}}

clean:
    rm -rf .build/debug .build/release

clean-all:
    rm -rf .build
