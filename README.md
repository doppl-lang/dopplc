# dopplc

Doppl is a new programming language that aims to provide a natural syntax for implementing parallel algorithms, designing data structures for shared memory applications and automated message passing among multiple tasks. The name is an abbreviation of "data oriented parallel programming language". 

Official compiler source code is stored in this repository.

##Dependencies
* [Node.js](https://nodejs.org/)
* [Jison](http://jison.org/)

##Test
Run following commands in your terminal to generate the parser and compile the test source
```
jison doppl_grammar.jison 
node dopplc.js test.doppl 
```

##References
* [Language Site](http://www.doppl.org)
* [Presentation from CppNow 2014 conference](https://github.com/diegoperini/cppnow2014-doppl)

##Why GPLv2 as Licence?
Since this project is too immature to be used in production, any modifications made should serve to its improvement. Once we have a stable release of dopplc, this license will be replaced with a less strict alternative such as MIT License.
