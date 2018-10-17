# dopplc

## DISCLAIMER
This project is **discontinued** until further notice. I plan to migrate it to a new grammar written in Nearley with modern capabilities like file watchers and language servers. I also want to do some research on new language primitives about declaring memory layout for data oriented collections in Doppl. Current specification have no such feature thus, should not really be called data oriented. See my progress [here](https://github.com/diegoperini/compiler-demo) if you are interested this kind of stuff.

## Introduction

Doppl is a new programming language that aims to provide a natural syntax for implementing parallel algorithms, designing data structures for shared memory applications and automated message passing among multiple tasks. The name is an abbreviation of "data oriented parallel programming language". 

Official compiler source code is stored in this repository.

## Dependencies
* [Clang](http://clang.llvm.org/get_started.html)
* [Node.js](https://nodejs.org/)
* [Coffeescript](http://coffeescript.org/)
* [Jison](http://jison.org/)

## Test
Run following command in your terminal to generate the parser and print AST of `test.doppl` to your console.
```
./test.sh test.doppl
```

## References
* [Language Site](http://www.doppl.org)
* [Presentation from CppNow 2014 conference](https://github.com/diegoperini/cppnow2014-doppl)

## Why GPLv2 as Licence?
Since this project is too immature to be used in production, any modifications made should serve to its improvement. Once we have a stable release of dopplc, this license will be replaced with a less strict alternative such as MIT License.
