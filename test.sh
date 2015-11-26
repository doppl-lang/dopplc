#!/bin/sh
clear
rm bin/*
coffee -b --output bin --compile src
cd src
jison doppl_grammar.jison 
mv doppl_grammar.js ../bin/doppl_grammar.js
cp doppl.cpp.mustache ../bin/doppl.cpp.mustache
cp state_bodies.mustache ../bin/state_bodies.mustache
cd ../bin
node dopplc.js ../test.doppl

