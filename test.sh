#!/bin/sh
clear
coffee -b --output bin --compile src
cd src
jison doppl_grammar.jison 
mv doppl_grammar.js ../bin/doppl_grammar.js
cp doppl.cpp.mustache ../bin/doppl.cpp.mustache
cp state_bodies.mustache ../bin/state_bodies.mustache
cp task_state_bodies.mustache ../bin/task_state_bodies.mustache
cd ..
npm i
cd bin
node --stack-size=64 dopplc.js ../$1 ../doppl_main
cd ..
rm -rf node_modules
rm -rf bin
make clean
make
rm ./doppl_main.cpp
clear
./doppl_main
echo ' '

