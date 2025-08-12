# LED Matrix System Info

This is a (very) basic Rust program to display CPU and RAM usage on the Framework 16 LED Matrix modules.

Because this is such a simple project, it makes two assumtions:

1. Two LED matrices are in use
2. The left one is /dev/ttyACM1 and the right one is /dev/ttyACM0

If you're using Nix/NixOS (like I do), the provided flake should give you all the tools you need, and be automatically activated by direnv with the provided .envrc
