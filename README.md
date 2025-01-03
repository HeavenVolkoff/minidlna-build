# MiniDLNA static builds

This project provides "mostly" static builds of [Minidlna](https://github.com/NathanaelA/minidlna) which is a fork with additional functionality of [ReadyMedia](https://sourceforge.net/projects/minidlna) for Linux and macOS.

## License

The MiniDLNA executables are licensed under GPL-2.0 and as such if you download them you agreeing with it's terms:
https://www.gnu.org/licenses/gpl-2.0.en.html

The scripts used to build the executables are licensed under AGPL-3.0, which you can read [here](./LICENSE)

## Why "mostly" static?

This is because while all runtime dependencies for MiniDLNA that are compiled alongside it are statically linked, some system dependecies remains dynamically linked. On Apple builds, the project is dynamically linked against the MacOS SDK with a minimum supported version for macOS Catalina (10.15) on x86_64 targets and macOS Big Sur (11.0) on arm64 targets. On Glibc targets the resulting binary is dynamically linked against Glibc, due to how Glibc works, the executable should work on any system newer than CentOS 7. The Musl binaries are truly static linked executables.

## Build instructions

To build the minidlna statically a `docker` or `podman` installation is required.
It is recomended to enable [`BuildKit`](https://docs.docker.com/build/buildkit/#getting-started) in docker.

Then run the following command inside the repository root directory:

```sh
$> docker build --build-arg TARGET=<TARGET> -o . .
```

or

```sh
$> podman build --jobs 4 --format docker --build-arg TARGET=<TARGET> -o . .
```

Where `<TARGET>` is one of:

- x86_64-darwin-apple
- aarch64-darwin-apple
- x86_64-linux-gnu
- aarch64-linux-gnu
- x86_64-linux-musl
- aarch64-linux-musl

After some time (it takes aroung 1~2 hours in Github CI) a directory named `out` will show up in the current directory containing the MiniDLNA executables.

## Acknowledgments

This build system is based on Spacedrive's native-deps:

- https://github.com/spacedriveapp/native-deps
