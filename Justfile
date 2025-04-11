image:
    docker build -t dt-plugin-builder .

build:
    docker run \
        --rm \
        -t \
        --user "$(id -u):$(id -g)" \
        -v ./:/src/plugin \
        dt-plugin-builder \
        cargo build -Zbuild-std --target x86_64-pc-windows-msvc
