#!/bin/bash

if ! [ -d protos ]; then
    echo "You are in the wrong directory."
    echo "Call this script in 'packages/commons'."
    exit 1
fi

if [ -d /usr/local/include/google/protobuf ]; then
    include_google=/usr/local/include/google/protobuf/
elif [ -d /usr/include/google/protobuf ]; then
    include_google=/usr/include/google/protobuf/
else
    echo Cannot find google protobuf includes.
    exit 1
fi

mkdir -p lib/src/generated
protoc --dart_out=grpc:lib/src/generated -I/usr/include $include_google/*.proto -Iprotos protos/*

echo Protobugs generated
