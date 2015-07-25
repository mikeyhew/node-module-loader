chai = require 'chai'
chai.use require('sinon-chai')
expect = chai.expect
sinon = require 'sinon'
path = require 'path'

ModuleLoader = require './module-loader'

testDir = path.join(__dirname, 'test')

describe 'ModuleLoader', ->
  
  it 'new ModuleLoader({})', ->
    ml = new ModuleLoader({})

  it 'paths option to ModuleLoader constructor should work. Also tests load (promise based) and module cache.', (done) ->
    ml = new ModuleLoader({
      paths: {
        module1: path.join(testDir, 'module1.coffee')
      }
    })

    answer = ml.loadSync 'module1'

    expect answer, 'module should return the right value'
    .to.equal('this is module 1')

    ml.load 'module1'
    .then (answer) ->
      expect answer, 'promise should resolve with the right value'
      .to.equal 'this is module 1'
      done()

  it 'searchDirs (with no magic)', ->

    ml = new ModuleLoader {
      searchDirs: [''].map (searchDir) ->
        path.join(testDir, searchDir)
    }

    expect ml.loadSync('module1'), 'should get the module'
    .to.equal 'this is module 1'

  it 'nodeRequire', ->
    ml = new ModuleLoader {
      nodeRequire: require
    }

    expect ml.loadSync('chai'), 'should get the same chai'
    .to.equal(chai)
