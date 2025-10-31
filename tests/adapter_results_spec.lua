local async = require("neotest.async").tests
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local stub = require("luassert.stub")
local types = require("neotest.types")
local test_utils = require("neotest-jest.test-utils")

test_utils.prepare_vim_treesitter()

describe("adapter.results", function()
  local spec = {}
  local strategy_result = {
    output = "test_console_output",
  }

  local function discover_positions(adapter, test_path, json_path)
    local tree = adapter.discover_positions(test_path)
    local test_json = lib.files.read(json_path)

    stub(lib.files, "read", test_json)

    ---@cast tree -nil
    return tree
  end

  assert:set_parameter("TableFormatLevel", 10)

  before_each(function()
    spec = {
      context = {
        results_path = "test_output.json",
        stop_stream = function() end,
      },
    }

    stub(logger, "error")
  end)

  after_each(function()
    ---@diagnostic disable-next-line: undefined-field
    logger.error:revert()
  end)

  async.it("creates neotest results", function()
    package.loaded["neotest-jest"] = nil
    local adapter = require("neotest-jest")({})
    local path = "./spec/tests/basic.test.ts"
    local tree = discover_positions(adapter, path, "./spec/json/basic.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::describe text::1"] = {
        status = types.ResultStatus.passed,
        short = "1: passed",
        output = strategy_result.output,
        location = {
          line = 6,
          column = 3,
        },
      },
      [path .. "::describe text::2"] = {
        status = types.ResultStatus.passed,
        short = "2: passed",
        output = strategy_result.output,
        location = {
          line = 10,
          column = 3,
        },
      },
      [path .. "::describe text::3"] = {
        status = types.ResultStatus.passed,
        short = "3: passed",
        output = strategy_result.output,
        location = {
          line = 14,
          column = 3,
        },
      },
      [path .. "::describe text::4"] = {
        status = types.ResultStatus.passed,
        short = "4: passed",
        output = strategy_result.output,
        location = {
          line = 18,
          column = 3,
        },
      },
      [path .. "::describe text::5"] = {
        status = types.ResultStatus.passed,
        short = "5: passed",
        output = strategy_result.output,
        location = {
          line = 22,
          column = 3,
        },
      },
      [path .. "::describe text 2::1"] = {
        status = types.ResultStatus.passed,
        short = "1: passed",
        output = strategy_result.output,
        location = {
          line = 28,
          column = 3,
        },
      },
      [path .. "::describe text 2::2"] = {
        status = types.ResultStatus.passed,
        short = "2: passed",
        output = strategy_result.output,
        location = {
          line = 32,
          column = 3,
        },
      },
      [path .. "::describe text 2::3"] = {
        status = types.ResultStatus.passed,
        short = "3: passed",
        output = strategy_result.output,
        location = {
          line = 36,
          column = 3,
        },
      },
      [path .. "::describe text 2::4"] = {
        status = types.ResultStatus.passed,
        short = "4: passed",
        output = strategy_result.output,
        location = {
          line = 40,
          column = 3,
        },
      },
      [path .. "::describe text 2::5"] = {
        status = types.ResultStatus.passed,
        short = "5: passed",
        output = strategy_result.output,
        location = {
          line = 44,
          column = 3,
        },
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for nested describes", function()
    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({})
    local path = "./spec/tests/nestedDescribe.test.ts"
    local tree = discover_positions(adapter, path, "./spec/json/nestedDescribe.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::outer::middle::inner::should do a thing"] = {
        status = types.ResultStatus.passed,
        short = "should do a thing: passed",
        output = strategy_result.output,
        location = {
          line = 5,
          column = 7,
        },
      },
      [path .. "::outer::middle::inner::this has a '"] = {
        status = types.ResultStatus.passed,
        short = "this has a ': passed",
        output = strategy_result.output,
        location = {
          line = 8,
          column = 7,
        },
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for tests using template strings", function()
    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({})
    local path = "./spec/tests/templateStrings.test.ts"
    local tree = discover_positions(adapter, path, "./spec/json/templateStrings.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::describe text::1"] = {
        status = types.ResultStatus.passed,
        short = "1: passed",
        output = strategy_result.output,
        location = {
          line = 6,
          column = 3,
        },
      },
      [path .. "::describe text::2"] = {
        status = types.ResultStatus.passed,
        short = "2: passed",
        output = strategy_result.output,
        location = {
          line = 10,
          column = 3,
        },
      },
      [path .. "::describe text::3"] = {
        status = types.ResultStatus.passed,
        short = "3: passed",
        output = strategy_result.output,
        location = {
          line = 14,
          column = 3,
        },
      },
      [path .. "::describe text::4"] = {
        status = types.ResultStatus.passed,
        short = "4: passed",
        output = strategy_result.output,
        location = {
          line = 18,
          column = 3,
        },
      },
      [path .. "::describe text::5"] = {
        status = types.ResultStatus.passed,
        short = "5: passed",
        output = strategy_result.output,
        location = {
          line = 22,
          column = 3,
        },
      },
      [path .. "::describe text 2::1"] = {
        status = types.ResultStatus.passed,
        short = "1: passed",
        output = strategy_result.output,
        location = {
          line = 28,
          column = 3,
        },
      },
      [path .. "::describe text 2::2"] = {
        status = types.ResultStatus.passed,
        short = "2: passed",
        output = strategy_result.output,
        location = {
          line = 32,
          column = 3,
        },
      },
      [path .. "::describe text 2::3"] = {
        status = types.ResultStatus.passed,
        short = "3: passed",
        output = strategy_result.output,
        location = {
          line = 36,
          column = 3,
        },
      },
      [path .. "::describe text 2::4"] = {
        status = types.ResultStatus.passed,
        short = "4: passed",
        output = strategy_result.output,
        location = {
          line = 40,
          column = 3,
        },
      },
      [path .. "::describe text 2::5"] = {
        status = types.ResultStatus.passed,
        short = "5: passed",
        output = strategy_result.output,
        location = {
          line = 44,
          column = 3,
        },
      },
    })

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for tests with backticks in test names", function()
    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({})
    local path = "./spec/tests/backtickInTestNames.test.ts"
    local tree = discover_positions(adapter, path, "./spec/json/backtickInTestNames.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::test names ` containing backticks::` 1"] = {
        status = types.ResultStatus.passed,
        short = "` 1: passed",
        output = strategy_result.output,
        location = {
          line = 2,
          column = 3,
        },
      },
      [path .. "::test names ` containing backticks::2`"] = {
        status = types.ResultStatus.passed,
        short = "2`: passed",
        output = strategy_result.output,
        location = {
          line = 6,
          column = 3,
        },
      },
      [path .. "::test names ` containing backticks::`` 3"] = {
        status = types.ResultStatus.passed,
        short = "`` 3: passed",
        output = strategy_result.output,
        location = {
          line = 10,
          column = 3,
        },
      },
      [path .. "::test names ` containing backticks::` 4`"] = {
        status = types.ResultStatus.passed,
        short = "` 4`: passed",
        output = strategy_result.output,
        location = {
          line = 14,
          column = 3,
        },
      },
    })

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for parametrized tests", function()
    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({ jest_test_discovery = true })
    local path = "./spec/tests/array.test.ts"
    local tree = discover_positions(adapter, path, "./spec/json/array.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    -- TODO: does not work since test names and positions are the same
    assert.are.same(neotest_results, {
      [path .. "::describe text::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
        location = {
          line = 2,
          column = 21,
        },
      },
      [path .. "::describe text::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
        location = {
          line = 6,
          column = 21,
        },
      },
      [path .. "::describe text::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
        location = {
          line = 2,
          column = 21,
        },
      },
      [path .. "::describe text::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
        location = {
          line = 6,
          column = 21,
        },
      },
      [path .. "::describe text::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
        location = {
          line = 6,
          column = 21,
        },
      },
      [path .. "::describe text::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
        location = {
          line = 6,
          column = 21,
        },
      },
      [path .. "::describe text::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
        location = {
          line = 10,
          column = 23,
        },
      },
      [path .. "::describe text::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
        location = {
          line = 10,
          column = 23,
        },
      },
      [path .. "::describe text::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
        location = {
          line = 10,
          column = 23,
        },
      },
      [path .. "::describe text::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
        location = {
          line = 14,
          column = 23,
        },
      },
      [path .. "::describe text::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
        location = {
          line = 14,
          column = 23,
        },
      },
      [path .. "::describe text::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
        location = {
          line = 14,
          column = 23,
        },
      },
      [path .. "::describe text 2::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
        location = {
          line = 20,
          column = 21,
        },
      },
      [path .. "::describe text 2::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
        location = {
          line = 20,
          column = 21,
        },
      },
      [path .. "::describe text 2::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
        location = {
          line = 20,
          column = 21,
        },
      },
      [path .. "::describe text 2::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
        location = {
          line = 24,
          column = 21,
        },
      },
      [path .. "::describe text 2::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
        location = {
          line = 24,
          column = 21,
        },
      },
      [path .. "::describe text 2::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
        location = {
          line = 24,
          column = 21,
        },
      },
      [path .. "::describe text 2::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
        location = {
          line = 28,
          column = 23,
        },
      },
      [path .. "::describe text 2::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
        location = {
          line = 28,
          column = 23,
        },
      },
      [path .. "::describe text 2::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
        location = {
          line = 28,
          column = 23,
        },
      },
      [path .. "::describe text 2::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
        location = {
          line = 32,
          column = 23,
        },
      },
      [path .. "::describe text 2::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
        location = {
          line = 32,
          column = 23,
        },
      },
      [path .. "::describe text 2::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
        location = {
          line = 32,
          column = 23,
        },
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for parametrized tests with placeholders", function()
    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({ jest_test_discovery = true })
    local path = "./spec/tests/parameterized.test.ts"
    local tree = discover_positions(adapter, path, "./spec/json/parameterized.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::describe text::test with percent %"] = {
        status = types.ResultStatus.passed,
        short = "test with percent %: passed",
        output = strategy_result.output,
        location = {
          line = 2,
          column = 22,
        },
      },
      [path .. '::describe text::test with all of the parameters "string" %s %d %i %f %j %o 0 % %p %s %d %i %f %j %o %# %'] = {
        status = types.ResultStatus.passed,
        short = 'test with all of the parameters "string" %s %d %i %f %j %o 0 % %p %s %d %i %f %j %o %# %: passed',
        output = strategy_result.output,
        location = {
          line = 6,
          column = 22,
        },
      },
      [path .. "::describe text::test with $namedParameter"] = {
        status = types.ResultStatus.passed,
        short = "test with $namedParameter: passed",
        output = strategy_result.output,
        location = {
          line = 13,
          column = 22,
        },
      },
      [path .. "::describe text::test with $namedParameter and $anotherNamedParameter"] = {
        status = types.ResultStatus.passed,
        short = "test with $namedParameter and $anotherNamedParameter: passed",
        output = strategy_result.output,
        location = {
          line = 17,
          column = 22,
        },
      },
      [path .. "::describe text::test with $variable.field.otherField"] = {
        status = types.ResultStatus.passed,
        short = "test with $variable.field.otherField: passed",
        output = strategy_result.output,
        location = {
          line = 24,
          column = 22,
        },
      },
      [path .. "::describe text::test with $variable.field.otherField and (parenthesis)"] = {
        status = types.ResultStatus.passed,
        short = "test with $variable.field.otherField and (parenthesis): passed",
        output = strategy_result.output,
        location = {
          line = 28,
          column = 22,
        },
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for parametrized describes", function()
    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({ jest_test_discovery = true })
    local path = "./spec/tests/parametricDescribesOnly.test.ts"
    local tree = discover_positions(adapter, path, "./spec/json/parametricDescribesOnly.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::is it enabled? [true]::how many?: 1::test 1"] = {
        status = types.ResultStatus.passed,
        short = "test 1: passed",
        output = strategy_result.output,
        location = {
          line = 3,
          column = 5,
        },
      },
      [path .. "::is it enabled? [true]::how many?: 1::test 2"] = {
        status = types.ResultStatus.passed,
        short = "test 2: passed",
        output = strategy_result.output,
        location = {
          line = 7,
          column = 5,
        },
      },
      [path .. "::is it enabled? [true]::how many?: 1::test 3"] = {
        status = types.ResultStatus.failed,
        short = "test 3: failed\nError: I have failed you",
        output = strategy_result.output,
        location = {
          line = 11,
          column = 5,
        },
        errors = {
          {
            line = 10,
            column = 0,
            message = "Error: I have failed you",
          },
        },
      },
      [path .. "::is it enabled? [true]::how many?: 2::test 1"] = {
        status = types.ResultStatus.passed,
        short = "test 1: passed",
        output = strategy_result.output,
        location = {
          line = 3,
          column = 5,
        },
      },
      [path .. "::is it enabled? [true]::how many?: 2::test 2"] = {
        status = types.ResultStatus.passed,
        short = "test 2: passed",
        output = strategy_result.output,
        location = {
          line = 7,
          column = 5,
        },
      },
      [path .. "::is it enabled? [true]::how many?: 2::test 3"] = {
        status = types.ResultStatus.failed,
        short = "test 3: failed\nError: I have failed you",
        output = strategy_result.output,
        location = {
          line = 11,
          column = 5,
        },
        errors = {
          {
            line = 10,
            column = 0,
            message = "Error: I have failed you",
          },
        },
      },
      [path .. "::is it enabled? [false]::how many?: 1::test 1"] = {
        status = types.ResultStatus.passed,
        short = "test 1: passed",
        output = strategy_result.output,
        location = {
          line = 3,
          column = 5,
        },
      },
      [path .. "::is it enabled? [false]::how many?: 1::test 2"] = {
        status = types.ResultStatus.passed,
        short = "test 2: passed",
        output = strategy_result.output,
        location = {
          line = 7,
          column = 5,
        },
      },
      [path .. "::is it enabled? [false]::how many?: 1::test 3"] = {
        status = types.ResultStatus.failed,
        short = "test 3: failed\nError: I have failed you",
        output = strategy_result.output,
        location = {
          line = 11,
          column = 5,
        },
        errors = {
          {
            line = 10,
            column = 0,
            message = "Error: I have failed you",
          },
        },
      },
      [path .. "::is it enabled? [false]::how many?: 2::test 1"] = {
        status = types.ResultStatus.passed,
        short = "test 1: passed",
        output = strategy_result.output,
        location = {
          line = 3,
          column = 5,
        },
      },
      [path .. "::is it enabled? [false]::how many?: 2::test 2"] = {
        status = types.ResultStatus.passed,
        short = "test 2: passed",
        output = strategy_result.output,
        location = {
          line = 7,
          column = 5,
        },
      },
      [path .. "::is it enabled? [false]::how many?: 2::test 3"] = {
        status = types.ResultStatus.failed,
        short = "test 3: failed\nError: I have failed you",
        output = strategy_result.output,
        location = {
          line = 11,
          column = 5,
        },
        errors = {
          {
            line = 10,
            column = 0,
            message = "Error: I have failed you",
          },
        },
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for parametrized describes and tests", function()
    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({ jest_test_discovery = true })
    local path = "./spec/tests/parametricDescribeAndTest.test.ts"
    local tree = discover_positions(adapter, path, "./spec/json/parametricDescribeAndTest.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::greeting Alice::should greet using Hello!"] = {
        status = types.ResultStatus.passed,
        short = "should greet using Hello!: passed",
        output = strategy_result.output,
        location = {
          line = 9,
          column = 5,
        },
      },
      [path .. "::greeting Alice::should greet using Hi!"] = {
        status = types.ResultStatus.passed,
        short = "should greet using Hi!: passed",
        output = strategy_result.output,
        location = {
          line = 9,
          column = 5,
        },
      },
      [path .. "::greeting Bob::should greet using Hello!"] = {
        status = types.ResultStatus.passed,
        short = "should greet using Hello!: passed",
        output = strategy_result.output,
        location = {
          line = 9,
          column = 5,
        },
      },
      [path .. "::greeting Bob::should greet using Hi!"] = {
        status = types.ResultStatus.passed,
        short = "should greet using Hi!: passed",
        output = strategy_result.output,
        location = {
          line = 9,
          column = 5,
        },
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results with failed and skipped results", function()
    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({})
    local path = "./spec/tests/basic-skipped-failed.test.ts"
    local tree = discover_positions(adapter, path, "./spec/json/basic-skipped-failed.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::describe text::1"] = {
        status = types.ResultStatus.passed,
        short = "1: passed",
        output = strategy_result.output,
        location = {
          line = 2,
          column = 3,
        },
      },
      [path .. "::describe text::2"] = {
        status = types.ResultStatus.passed,
        short = "2: passed",
        output = strategy_result.output,
        location = {
          line = 6,
          column = 3,
        },
      },
      [path .. "::describe text::3"] = {
        errors = {
          {
            line = 9,
            column = 0,
            message = "ReferenceError: assert is not defined",
          },
        },
        status = types.ResultStatus.failed,
        short = "3: failed\nReferenceError: assert is not defined",
        output = strategy_result.output,
        location = {
          line = 10,
          column = 3,
        },
      },
      [path .. "::describe text::4"] = {
        status = types.ResultStatus.passed,
        short = "4: passed",
        output = strategy_result.output,
        location = {
          line = 15,
          column = 3,
        },
      },
      [path .. "::describe text 2::1"] = {
        status = types.ResultStatus.passed,
        short = "1: passed",
        output = strategy_result.output,
        location = {
          line = 21,
          column = 3,
        },
      },
      [path .. "::describe text 2::2"] = {
        status = types.ResultStatus.skipped,
        short = "2: skipped",
        output = strategy_result.output,
        location = {
          line = 25,
          column = 6,
        },
      },
      [path .. "::describe text 2::3"] = {
        status = types.ResultStatus.passed,
        short = "3: passed",
        output = strategy_result.output,
        location = {
          line = 29,
          column = 3,
        },
      },
      [path .. "::describe text 2::4"] = {
        status = types.ResultStatus.passed,
        short = "4: passed",
        output = strategy_result.output,
        location = {
          line = 33,
          column = 3,
        },
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("handles failure to find parsed test result", function()
    package.loaded["neotest-jest"] = nil

    local path = "./spec/tests/basic.test.ts"
    local adapter = require("neotest-jest")({})
    local tree = discover_positions(adapter, path, "./spec/json/basic-parse-fail.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)
    assert.are.same(neotest_results, {})

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(logger.error).was.called_with("Failed to find parsed test result ", {
      ancestorTitles = {
        "describe text",
      },
      duration = 18,
      failureDetails = {},
      failureMessages = {},
      fullName = "describe text 1",
      invocations = 1,
      location = {
        column = 3,
        line = 2,
      },
      numPassingAsserts = 0,
      retryReasons = {},
      status = "passed",
    })
  end)

  it("handles failure to read json test output", function()
    stub(lib.files, "read", function()
      error("Could not read file", 0)
    end)

    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({})
    local neotest_results = adapter.results(spec, strategy_result)
    assert.are.same(neotest_results, {})

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(logger.error).was.called_with("No test output file found ", "test_output.json")

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  it("handles failure to decode json", function()
    stub(lib.files, "read", '{"a".}')

    package.loaded["neotest-jest"] = nil
    local adapter = require("neotest-jest")({})

    ---@diagnostic disable-next-line: missing-parameter
    local neotest_results = adapter.results(spec, strategy_result)

    assert.are.same(neotest_results, {})

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)

    assert
      ---@diagnostic disable-next-line: param-type-mismatch
      .stub(logger.error)
      .was
      .called_with("Failed to parse test output json ", "test_output.json")

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)
end)
