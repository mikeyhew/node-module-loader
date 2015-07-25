    path = require('path')
    fs = require('fs')
    vm = require('vm')
    _ = require('underscore')
    coffee = require('coffee-script')
    globber = require('glob')


This function is supposed to do a try/catch and give you more information about what happened than simply letting the exception through would tell you. We'll come back to this.

    doNodeRequire = (nodeRequire, moduleName) ->
        nodeRequire(moduleName)

Modules store the filename of the module, the dependency names, and cache the module creator function or its return value (unsure as of right now).
    
    class Module
        constructor: (options) ->
            {@filename, @depNames, @creator} = _.defaults options, {
                depNames: []
            }
            throw new Error 'filename required' unless @filename
            throw new Error 'module requires a creator' unless @creator


ModuleLoader is the main class. A module loader is used to load modules.
    
    class ModuleLoader
        constructor: (options) ->
            options = _.defaults options, {
                paths: {}
                searchPaths: []
            }
            {@paths, @searchDirs, @nodeRequire} = options
            _.each @searchDirs, (dir) ->
                unless path.isAbsolute(dir)
                    throw new Error 'searchDirs passed to ModuleLoader must be absolute paths. Got "' + dir + '".'
            
The module loader keeps track of its modules in a hash of **absoluteModuleName: module** pairs.
            
            @modules = {}

        define: (a0, a1, a2, filename, moduleName) ->

Figure out what argument's what
            
            args = [a0, a1, a2]

If a module name is passed, it trumps whatever was asked for in load. This is so you can have multiple modules in a file.

            if _.isString(args[0])
                moduleName = args.shift()

            if _.isArray(args[0])
                depNames = args.shift()
            else
                depNames = []

            creator = args.shift()

Now that we have all the right arguments, let's make the module! Let's stop short of evaluating the creator function though.
            
            if @modules.hasOwnProperty moduleName
                throw new Error(moduleName+' is already defined!')
            
            theModule = new Module {filename, depNames, creator}
            @modules[moduleName] = theModule

We've made a new Module object and added it to the @modules hash, and that's all we need to do in this function.



Load a module by its absolute module name. The module may have to load its dependencies if they have not already been loaded. Although the implementation under the hood is synchronous, this function returns a promise so that we can go async in the future. The promise is resolved with the module once created (the return value of the module's creator).

        load: (moduleName) ->
            Promise.resolve(@loadSync(moduleName))

Synchronous version of load. Returns the value of the created module.

        loadSync: (moduleName) ->
            
            if @modules.hasOwnProperty(moduleName)

                # Circular dependency check:
                theModule = @modules[moduleName]
                if theModule._loadingDeps
                    throw new Error 'Circular dependency detected when loading module "' + moduleName + '".'

                return theModule.cachedValue

            filename = @getFilenameSync(moduleName)
            if not filename
                if @nodeRequire
                    return doNodeRequire(@nodeRequire, moduleName)
                else
                    throw new Error 'could not find module "' + moduleName + '".'

Compile Coffeescript. If coffee.register has already been called, then we won't need to hold onto the source map because stack traces will already have been implemented.

            code = fs.readFileSync filename, 'utf-8'
            if path.extname(filename) in ['.coffee', '.litcoffee']
                js = coffee.compile code, {
                    filename: filename
                }
            else
                js = code

Run the code, with the define function exposed to it. If there are multiple modules in the file, this will add them all to @modules.

            define = @define.bind(this)
            localdefine = (a0, a1, a2) ->
                define(a0, a1, a2, filename, moduleName)
            localdefine.amd = {}
            sandbox = {
                define: localdefine
            }
            vm.createContext(sandbox)
            vm.runInContext(js, sandbox, {filename: filename})

The unevaluated (uncreated) module should have been been added to @modules. Do a check to make sure.

            unless @modules.hasOwnProperty(moduleName)
                throw new Error 'the module file was loaded, but the module "' + moduleName +  '" still isn\'t showing up.'

Now we can get its dependencies. I'll even check for circular dependencies for you.
            
            theModule = @modules[moduleName]
            theModule._loadingDeps = true
            deps = _.map theModule.depNames, (depName) ->
                @loadSync(depName)
            delete theModule._loadingDeps

This is the moment we've all been waiting for! Create the module!
            
            return theModule.cachedValue = theModule.creator.apply(null, deps)



        getFilenameSync: (moduleName) ->

Find the module, checking for it first in @paths, then in @searchDirs. Does not use nodeRequire - we only try that if we don't get a file name.
            
            if @paths.hasOwnProperty(moduleName)
                @paths[moduleName]
            else
                _.reduce @searchDirs, ((memo, dirGlob) ->
                    memo or
                        glob = path.join(dirGlob, moduleName) + '.@(coffee|js)'
                        results = globber.sync(glob)
                        results[0] or false
                ), false

Export the ModuleLoader class, with Module added onto it.
    
    ModuleLoader.Module = Module
    module.exports = ModuleLoader