# Mikeyhew's Module Loader

An asynchronous (sort-of) module loader for node.js. Tries to implement most of the AMD specification, but right now it falls short in some areas:
- No relative module paths, except when it falls back to node's require
- It's not actually asynchronous right now, but at least the public api allows for it to be.
- no magic `exports`, `require`, and `module` modules (`exports` and `module.exports` may be included later to make underscore and backbone work. `require` might be supported in the future if it's actually useful.)
- It hasn't even run or tested yet, and it won't until later today because I'm going to bed. **UPDATE** I wrote tests today and they pass. To test, install mocha (`npm install -g mocha`) and run `npm test`

The main goals of ModuleLoader are best shown in this note I wrote today (well, yesterday) before I wrote this program:

>I just want a server-side module loader, like requirejs, but that does the following things:
>
>1. you can configure the loader with *search paths*. Ideally, the module loader follows the following rules when an absolute dependency is asked for: 1) if the path for that dependency is set, use that file, 2) look in one of the search paths for a file with that name + extension .js or .coffee. [or a folder in future], 3) does require(moduleName) using the require function passed in.
>2. you can create a {moduleName: url} hash for use on the client;
>3. **Important:** When there is an exception on the server, the exception is printed out, with a proper stack trace with the right file names.
>4. Can compile .coffee and .litcoffee files, and output the right file and line:column numbers on error.


# Sample Usage:

```javascript
var ModuleLoader = require('mikeyhew-module-loader');
var path = require('path');

var ml = new ModuleLoader({
  paths: {
    myModule: path.join(__dirname, 'path/to/myModule')
  },
  searchDirs: ['amd', 'can/use/**/globs/'],
  nodeRequire: require
});

ml.load('myModule').then(function(myModule) {
  //... do stuff with myModule
});
```

# LICENSE
MIT