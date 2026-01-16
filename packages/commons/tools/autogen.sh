#!/bin/bash
set -e

if ! [ -d protos ]; then
    echo "You are in the wrong directory."
    echo "Call this script in 'packages/commons'."
    exit 1
fi

echo Generating protobuf code.

mkdir -p lib/src/generated
protoc --dart_out=grpc:lib/src/generated -Iprotos protos/*

echo Protobuf code generated
