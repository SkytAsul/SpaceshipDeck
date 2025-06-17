#!/bin/bash

if ! [ -d protos ]; then
    echo "You are in the wrong directory."
    echo "Call this script in 'packages/commons'."
    exit 1
fi

mkdir -p lib/src/generated
protoc --dart_out=grpc:lib/src/generated -I/usr/include /usr/local/include/google/protobuf/*.proto -Iprotos protos/*
