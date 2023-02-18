#!/bin/sh
exec zig build -Drelease-fast=true #-Dtarget=x86_64-linux-musl
