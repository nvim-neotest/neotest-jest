local async = require("neotest.async").tests
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local stub = require("luassert.stub")
local types = require("neotest.types")
-- local util = require("neotest-jest.util")

---@type neotest.Adapter
local adapter = require("neotest-jest")({})

describe("adapter.results", function()
  local spec = {}
  local strategy_result = {
    output = "test_console_output",
  }

  local function discover_positions(test_path, json_path)
    local tree = adapter.discover_positions(test_path)
    local test_json = table.concat(vim.fn.readfile(json_path), "\n")

    stub(lib.files, "read", test_json)

    ---@cast tree -nil
    return tree
  end

  before_each(function()
    assert:set_parameter("TableFormatLevel", 10)

    -- local stream_data, stop_stream = util.stream("test_output.json")

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
    local path = "./spec/basic.test.ts"
    local tree = discover_positions(path, "./spec/basic.test.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::describe text::1"] = {
        status = types.ResultStatus.passed,
        short = "1: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::2"] = {
        status = types.ResultStatus.passed,
        short = "2: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::3"] = {
        status = types.ResultStatus.passed,
        short = "3: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::4"] = {
        status = types.ResultStatus.passed,
        short = "4: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::1"] = {
        status = types.ResultStatus.passed,
        short = "1: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::2"] = {
        status = types.ResultStatus.passed,
        short = "2: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::3"] = {
        status = types.ResultStatus.passed,
        short = "3: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::4"] = {
        status = types.ResultStatus.passed,
        short = "4: passed",
        output = strategy_result.output,
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- Tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for nested describes", function()
    local path = "./spec/nestedDescribe.test.ts"
    local tree = discover_positions(path, "./spec/nestedDescribe.test.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    assert.are.same(neotest_results, {
      [path .. "::outer::middle::inner::should do a thing"] = {
        status = types.ResultStatus.passed,
        short = "should do a thing: passed",
        output = strategy_result.output,
      },
      [path .. "::outer::middle::inner::this has a '"] = {
        status = types.ResultStatus.passed,
        short = "this has a ': passed",
        output = strategy_result.output,
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- Tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for parametrized tests 1", function()
    local path = "./spec/array.test.ts"
    local tree = discover_positions(path, "./spec/array.test.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    vim.print(vim.inspect(neotest_results))

    -- TODO: Does not work since test names are the same but the position is not
    assert.are.same(neotest_results, {
      [path .. "::describe text::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array1"] = {
        status = types.ResultStatus.passed,
        short = "Array1: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array2"] = {
        status = types.ResultStatus.passed,
        short = "Array2: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array3"] = {
        status = types.ResultStatus.passed,
        short = "Array3: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text 2::Array4"] = {
        status = types.ResultStatus.passed,
        short = "Array4: passed",
        output = strategy_result.output,
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- Tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results for parametrized tests 2", function()
    local path = "./spec/parameterized.test.ts"
    local tree = discover_positions(path, "./spec/parameterized.test.json")
    local neotest_results = adapter.results(spec, strategy_result, tree)

    vim.print(vim.inspect(neotest_results))

    assert.are.same(neotest_results, {
      [path .. "::describe text::test with percent %"] = {
        status = types.ResultStatus.passed,
        short = "test with percent %: passed",
        output = strategy_result.output,
      },
      [path .. '::describe text::test with all of the parameters "string" %s %d %i %f %j %o 0 % %p %s %d %i %f %j %o %# %'] = {
        status = types.ResultStatus.passed,
        short = 'test with all of the parameters "string" %s %d %i %f %j %o 0 % %p %s %d %i %f %j %o %# %: passed',
        output = strategy_result.output,
      },
      [path .. "::describe text::test with $namedParameter"] = {
        status = types.ResultStatus.passed,
        short = "test with $namedParameter: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::test with $namedParameter and $anotherNamedParameter"] = {
        status = types.ResultStatus.passed,
        short = "test with $namedParameter and $anotherNamedParameter: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::test with $variable.field.otherField"] = {
        status = types.ResultStatus.passed,
        short = "test with $variable.field.otherField: passed",
        output = strategy_result.output,
      },
      [path .. "::describe text::test with $variable.field.otherField and (parenthesis)"] = {
        status = types.ResultStatus.passed,
        short = "test with $variable.field.otherField and (parenthesis): passed",
        output = strategy_result.output,
      },
    })

    -- local expected_tree = require("./spec/basic.test.expected_tree")
    --
    -- -- Tree remains unchanged
    -- assert.are.same(tree:to_list(), expected_tree)

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was_not_called()

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  async.it("creates neotest results with failed and skipped results", function() end)

  it("handles failure to find parsed test result", function() end)

  it("handles failure to read json test output", function()
    stub(lib.files, "read", function()
      error("Could not read file", 0)
    end)

    local neotest_results = adapter.results(spec, strategy_result, tree)
    assert.are.same(neotest_results, {})

    assert.stub(lib.files.read).was.called_with(spec.context.results_path)
    assert.stub(logger.error).was.called_with("No test output file found ", "test_output.json")

    ---@diagnostic disable-next-line: undefined-field
    lib.files.read:revert()
  end)

  it("handles failure to decode json", function()
    stub(lib.files, "read", '{"a".}')

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
