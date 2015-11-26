#!/bin/sh
clear
rm -rf bin
coffee -b --output bin --compile src
cd src
jison doppl_grammar.jison 
mv doppl_grammar.js ../bin/doppl_grammar.js
cp doppl.cpp.mustache ../bin/doppl.cpp.mustache
cp state_bodies.mustache ../bin/state_bodies.mustache
cd ..
npm i
cd bin
node dopplc.js ../$1
cd ..
rm -rf node_modules

