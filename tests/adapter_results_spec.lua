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

  before_each(function()
    assert:set_parameter("TableFormatLevel", 10)

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
    local adapter = require("neotest-jest")({})
    local path = "./spec/basic.test.ts"
    local tree = discover_positions(adapter, path, "./spec/basic.test.json")
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
        status = types.ResultStatus.passed,
        short = "3: passed",
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
          line = 14,
          column = 3,
        },
      },
      [path .. "::describe text 2::1"] = {
        status = types.ResultStatus.passed,
        short = "1: passed",
        output = strategy_result.output,
        location = {
          line = 20,
          column = 3,
        },
      },
      [path .. "::describe text 2::2"] = {
        status = types.ResultStatus.passed,
        short = "2: passed",
        output = strategy_result.output,
        location = {
          line = 24,
          column = 3,
        },
      },
      [path .. "::describe text 2::3"] = {
        status = types.ResultStatus.passed,
        short = "3: passed",
        output = strategy_result.output,
        location = {
          line = 28,
          column = 3,
        },
      },
      [path .. "::describe text 2::4"] = {
        status = types.ResultStatus.passed,
        short = "4: passed",
        output = strategy_result.output,
        location = {
          line = 32,
          column = 3,
        },
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for nested describes", function()
    local adapter = require("neotest-jest")({})
    local path = "./spec/nestedDescribe.test.ts"
    local tree = discover_positions(adapter, path, "./spec/nestedDescribe.test.json")
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

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for tests using template strings", function()
    local adapter = require("neotest-jest")({})
    local path = "./spec/template-strings.test.ts"
    local tree = discover_positions(adapter, path, "./spec/template-strings.test.json")
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

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for tests with backticks in test names", function()
    local adapter = require("neotest-jest")({})
    local path = "./spec/backtick-in-test-names.test.ts"
    local tree = discover_positions(adapter, path, "./spec/backtick-in-test-names.test.json")
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

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for parametrized tests 1", function()
    local adapter = require("neotest-jest")({ jest_test_discovery = true })
    local path = "./spec/array.test.ts"
    local tree = discover_positions(adapter, path, "./spec/array.test.json")
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

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for parametrized tests 2", function()
    local adapter = require("neotest-jest")({ jest_test_discovery = true })
    local path = "./spec/parameterized.test.ts"
    local tree = discover_positions(adapter, path, "./spec/parameterized.test.json")
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

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results with failed and skipped results", function()
    local adapter = require("neotest-jest")({})
    local path = "./spec/basic-skipped-failed.test.ts"
    local tree = discover_positions(adapter, path, "./spec/basic-skipped-failed.test.json")
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

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("handles failure to find parsed test result", function()
    local path = "./spec/basic.test.ts"
    local adapter = require("neotest-jest")({})
    local tree = discover_positions(adapter, path, "./spec/basic-parse-fail.test.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)
    assert.are.same(neotest_results, {})

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
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

    local adapter = require("neotest-jest")({})
    local neotest_results = adapter.results(spec, strategy_result)
    assert.are.same(neotest_results, {})

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was.called_with("No test output file found ", "test_output.json")

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  it("handles failure to decode json", function()
    stub(lib.files, "read", '{"a".}')

    local adapter = require("neotest-jest")({})

    ---@diagnostic disable-next-line: missing-parameter
    local neotest_results = adapter.results(spec, strategy_result)

    assert.are.same(neotest_results, {})
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert
      .stub(logger.error).was
      .called_with("Failed to parse test output json ", "test_output.json")
    assert.stub(lib.files.read).was.called_with(spec.context.results_path)

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)
end)
