#!/bin/bash
if [ -z "$1" ]; then
	echo "Provide C++ (Qt) source project folder as argument"
	exit 1
fi
if [ ! -d "$1" ]; then
    echo "Argument is not a directory."
    echo "Provide C++ (Qt) source project folder as argument"
    exit 1
fi

g++ "$1"/*.cpp -o "$1"/mylibrary.so -fPIC -llua5.3 -lQt5Core \
-I/usr/include/x86_64-linux-gnu/qt5 -I/usr/include/x86_64-linux-gnu/qt5/QtCore -shared -I/usr/include/lua5.3/
