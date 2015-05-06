var parser = require("./doppl_grammar").parser;
var generator = require('./doppl_generator');
var cli = require('commander');
var fs = require('fs');
var util = require('util');

cli
  .version('0.0.1')
  .usage('<file>')
  .parse(process.argv);

if (!cli.args.length) {
    console.log(cli.args);
    console.log("dopplc:");
    console.log("Error: No input file");
    console.log("Manual: node dopplc.js --help");
} else {
    var dopplSource = fs.readFileSync(cli.args[0], "utf8");
    if(parser.parse(dopplSource)) {
        var ast = require('./ast').ast;

        console.log('AST**************************\n');
        console.log(util.inspect(ast, {showHidden: false, depth: null}));
        console.log('');
        console.log('AST-Analyzed**************************\n');
        
        var cpp = generator.generate(ast);

        console.log('');
        console.log(util.inspect(ast, {showHidden: false, depth: null}));
        console.log('');
        console.log('CPP***********************************\n');

        if(cpp.error) console.log("Compile error.");
        else {
          //console.log(cpp.output);
          console.log("Successfully compiled.");
        }
        
        // TODO : write cpp to a file
    }
}
