local nio = require("nio")
local async = nio.tests
local test_utils = require("neotest-jest.test-utils")
local neotest_types = require("neotest.types")

local PositionType = neotest_types.PositionType

test_utils.prepare_vim_treesitter()

describe("adapter.discover_positions", function()
  assert:set_parameter("TableFormatLevel", 10)

  ---@param testname string
  ---@return string
  local function get_test_absolute_path(testname)
    -- vim.fs.abspath is 0.11.0+ so use vim.fs.find to get an absolute path. Do not use the
    -- 'path' option since then it returns a relative path
    return vim.fs.find(testname, { type = "file", limit = 1, upward = false })[1]
  end

  async.it("provides meaningful names from a basic spec", function()
    package.loaded["neotest-jest"] = nil

    local path = vim.fs.normalize("./spec/tests/basic.test.ts")
    local adapter = require("neotest-jest")({ jestCommand = "jest", jest_test_discovery = false })
    local positions = adapter.discover_positions(path):to_list()

    local expected_output = {
      {
        id = path,
        name = "basic.test.ts",
        path = path,
        range = { 0, 0, 47, 0 },
        type = PositionType.file,
      },
      {
        {
          id = path .. "::describe text",
          is_parameterized = false,
          name = "describe text",
          path = path,
          range = { 4, 0, 24, 2 },
          type = PositionType.namespace,
        },
        {
          {
            id = path .. "::describe text::1",
            is_parameterized = false,
            name = "1",
            path = path,
            range = { 5, 2, 7, 4 },
            test_name_range = { 5, 6, 5, 7 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::2",
            is_parameterized = false,
            name = "2",
            path = path,
            range = { 9, 2, 11, 4 },
            test_name_range = { 9, 6, 9, 7 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::3",
            is_parameterized = false,
            name = "3",
            path = path,
            range = { 13, 2, 15, 4 },
            test_name_range = { 13, 8, 13, 9 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::4",
            is_parameterized = false,
            name = "4",
            path = path,
            range = { 17, 2, 19, 4 },
            test_name_range = { 17, 8, 17, 9 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::5",
            is_parameterized = false,
            name = "5",
            path = path,
            range = { 21, 2, 23, 5 },
            test_name_range = { 21, 6, 21, 7 },
            type = PositionType.test,
          },
        },
      },
      {
        {
          id = path .. "::describe text 2",
          is_parameterized = false,
          name = "describe text 2",
          path = path,
          range = { 26, 0, 46, 2 },
          type = PositionType.namespace,
        },
        {
          {
            id = path .. "::describe text 2::1",
            is_parameterized = false,
            name = "1",
            path = path,
            range = { 27, 2, 29, 4 },
            test_name_range = { 27, 6, 27, 7 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::2",
            is_parameterized = false,
            name = "2",
            path = path,
            range = { 31, 2, 33, 4 },
            test_name_range = { 31, 6, 31, 7 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::3",
            is_parameterized = false,
            name = "3",
            path = path,
            range = { 35, 2, 37, 4 },
            test_name_range = { 35, 8, 35, 9 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::4",
            is_parameterized = false,
            name = "4",
            path = path,
            range = { 39, 2, 41, 4 },
            test_name_range = { 39, 8, 39, 9 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::5",
            is_parameterized = false,
            name = "5",
            path = path,
            range = { 43, 2, 45, 5 },
            test_name_range = { 43, 6, 43, 7 },
            type = PositionType.test,
          },
        },
      },
    }

    assert.are.same(positions, expected_output)
  end)

  async.it("provides meaningful names from a spec with template strings", function()
    package.loaded["neotest-jest"] = nil

    local path = "./spec/tests/templateStrings.test.ts"
    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local positions = adapter.discover_positions(path):to_list()

    local expected_output = {
      {
        id = path,
        name = "templateStrings.test.ts",
        path = path,
        range = { 0, 0, 47, 0 },
        type = PositionType.file,
      },
      {
        {
          id = path .. "::describe text",
          is_parameterized = false,
          name = "describe text",
          path = path,
          range = { 4, 0, 24, 2 },
          type = PositionType.namespace,
        },
        {
          {
            id = path .. "::describe text::1",
            is_parameterized = false,
            name = "1",
            path = path,
            range = { 5, 2, 7, 4 },
            test_name_range = { 5, 6, 5, 7 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::2",
            is_parameterized = false,
            name = "2",
            path = path,
            range = { 9, 2, 11, 4 },
            test_name_range = { 9, 6, 9, 7 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::3",
            is_parameterized = false,
            name = "3",
            path = path,
            range = { 13, 2, 15, 4 },
            test_name_range = { 13, 8, 13, 9 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::4",
            is_parameterized = false,
            name = "4",
            path = path,
            range = { 17, 2, 19, 4 },
            test_name_range = { 17, 8, 17, 9 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::5",
            is_parameterized = false,
            name = "5",
            path = path,
            range = { 21, 2, 23, 5 },
            test_name_range = { 21, 6, 21, 7 },
            type = PositionType.test,
          },
        },
      },
      {
        {
          id = path .. "::describe text 2",
          is_parameterized = false,
          name = "describe text 2",
          path = path,
          range = { 26, 0, 46, 2 },
          type = PositionType.namespace,
        },
        {
          {
            id = path .. "::describe text 2::1",
            is_parameterized = false,
            name = "1",
            path = path,
            range = { 27, 2, 29, 4 },
            test_name_range = { 27, 6, 27, 7 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::2",
            is_parameterized = false,
            name = "2",
            path = path,
            range = { 31, 2, 33, 4 },
            test_name_range = { 31, 6, 31, 7 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::3",
            is_parameterized = false,
            name = "3",
            path = path,
            range = { 35, 2, 37, 4 },
            test_name_range = { 35, 8, 35, 9 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::4",
            is_parameterized = false,
            name = "4",
            path = path,
            range = { 39, 2, 41, 4 },
            test_name_range = { 39, 8, 39, 9 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::5",
            is_parameterized = false,
            name = "5",
            path = path,
            range = { 43, 2, 45, 5 },
            test_name_range = { 43, 6, 43, 7 },
            type = PositionType.test,
          },
        },
      },
    }

    assert.are.same(positions, expected_output)
  end)

  async.it("provides meaningful names from a spec with backticks in test names", function()
    package.loaded["neotest-jest"] = nil

    local adapter = require("neotest-jest")({ jestCommand = "jest" })
    local path = "./spec/tests/backtickInTestNames.test.ts"
    local positions = adapter.discover_positions(path):to_list()

    local expected_output = {
      {
        id = path,
        name = "backtickInTestNames.test.ts",
        path = path,
        range = { 0, 0, 17, 0 },
        type = PositionType.file,
      },
      {
        {
          id = path .. "::test names ` containing backticks",
          is_parameterized = false,
          name = "test names ` containing backticks",
          path = path,
          range = { 0, 0, 16, 2 },
          type = PositionType.namespace,
        },
        {
          {
            id = path .. "::test names ` containing backticks::` 1",
            is_parameterized = false,
            name = "` 1",
            path = path,
            range = { 1, 2, 3, 4 },
            test_name_range = { 1, 6, 1, 9 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::test names ` containing backticks::2`",
            is_parameterized = false,
            name = "2`",
            path = path,
            range = { 5, 2, 7, 4 },
            test_name_range = { 5, 8, 5, 10 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::test names ` containing backticks::`` 3",
            is_parameterized = false,
            name = "`` 3",
            path = path,
            range = { 9, 2, 11, 4 },
            test_name_range = { 9, 6, 9, 10 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::test names ` containing backticks::` 4`",
            is_parameterized = false,
            name = "` 4`",
            path = path,
            range = { 13, 2, 15, 4 },
            test_name_range = { 13, 8, 13, 12 },
            type = PositionType.test,
          },
        },
      },
    }

    assert.are.same(positions, expected_output)
  end)

  async.it("provides meaningful names for parametric tests", function()
    package.loaded["neotest-jest"] = nil

    local path = vim.fs.normalize("./spec/tests/array.test.ts")
    local adapter = require("neotest-jest")({ jestCommand = "jest", jest_test_discovery = false })
    local positions = adapter.discover_positions(path):to_list()

    local expected_output = {
      {
        id = path,
        name = "array.test.ts",
        path = path,
        range = { 0, 0, 35, 0 },
        type = PositionType.file,
      },
      {
        {
          id = path .. "::describe text",
          is_parameterized = false,
          name = "describe text",
          path = path,
          range = { 0, 0, 16, 2 },
          type = PositionType.namespace,
        },
        {
          {
            id = path .. "::describe text::Array1 %d",
            is_parameterized = true,
            name = "Array1 %d",
            path = path,
            range = { 1, 2, 3, 4 },
            test_name_range = { 1, 22, 1, 31 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::Array2",
            is_parameterized = true,
            name = "Array2",
            path = path,
            range = { 5, 2, 7, 4 },
            test_name_range = { 5, 22, 5, 28 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::Array3 %d",
            is_parameterized = true,
            name = "Array3 %d",
            path = path,
            range = { 9, 2, 11, 4 },
            test_name_range = { 9, 24, 9, 33 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text::Array4 %d",
            is_parameterized = true,
            name = "Array4 %d",
            path = path,
            range = { 13, 2, 15, 4 },
            test_name_range = { 13, 24, 13, 33 },
            type = PositionType.test,
          },
        },
      },
      {
        {
          id = path .. "::describe text 2",
          is_parameterized = false,
          name = "describe text 2",
          path = path,
          range = { 18, 0, 34, 2 },
          type = PositionType.namespace,
        },
        {
          {
            id = path .. "::describe text 2::Array1 %d",
            is_parameterized = true,
            name = "Array1 %d",
            path = path,
            range = { 19, 2, 21, 4 },
            test_name_range = { 19, 22, 19, 31 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::Array2 %d",
            is_parameterized = true,
            name = "Array2 %d",
            path = path,
            range = { 23, 2, 25, 4 },
            test_name_range = { 23, 22, 23, 31 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::Array3 %d",
            is_parameterized = true,
            name = "Array3 %d",
            path = path,
            range = { 27, 2, 29, 4 },
            test_name_range = { 27, 24, 27, 33 },
            type = PositionType.test,
          },
        },
        {
          {
            id = path .. "::describe text 2::Array4",
            is_parameterized = true,
            name = "Array4",
            path = path,
            range = { 31, 2, 33, 4 },
            test_name_range = { 31, 24, 31, 30 },
            type = PositionType.test,
          },
        },
      },
    }

    assert.are.same(positions, expected_output)
  end)

  describe("parametric tests with test discovery", function()
    local old_package_path

    before_each(function()
      -- Tell plenary where to look for the neotest-jest module after we change directory
      old_package_path = package.path
      package.path = package.path .. ";../lua/neotest-jest/?.lua;../lua/neotest-jest/init.lua"

      -- Required as jest is installed in the spec directory
      nio.fn.chdir("./spec")
    end)

    after_each(function()
      package.path = old_package_path
      nio.fn.chdir("..")
    end)

    async.it("provides meaningful names for parametric tests", function()
      package.loaded["neotest-jest"] = nil

      local path = get_test_absolute_path("array.test.ts")
      local adapter = require("neotest-jest")({ jestCommand = "jest", jest_test_discovery = true })
      local positions = adapter.discover_positions(path):to_list()

      -- NOTE: This does not work when the parametric test does not use the
      -- parameters as the position id for the generated runtime positions will
      -- be the same as the existing source-level test and will overwrite the
      -- existing position. Consequently, there are "missing" tests below.
      local expected_output = {
        {
          id = path,
          name = "array.test.ts",
          path = path,
          range = { 0, 0, 35, 0 },
          type = PositionType.file,
        },
        {
          {
            id = path .. "::describe text",
            is_parameterized = false,
            name = "describe text",
            path = path,
            range = { 0, 0, 16, 2 },
            type = PositionType.namespace,
          },
          {
            {
              id = path .. "::describe text::Array1 %d",
              is_parameterized = true,
              name = "Array1 %d",
              path = path,
              range = { 1, 2, 3, 4 },
              test_name_range = { 1, 22, 1, 31 },
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array2",
              is_parameterized = true,
              name = "Array2",
              path = path,
              range = { 5, 2, 7, 4 },
              test_name_range = { 5, 22, 5, 28 },
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array3 %d",
              is_parameterized = true,
              name = "Array3 %d",
              path = path,
              range = { 9, 2, 11, 4 },
              test_name_range = { 9, 24, 9, 33 },
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array4 %d",
              is_parameterized = true,
              name = "Array4 %d",
              path = path,
              range = { 13, 2, 15, 4 },
              test_name_range = { 13, 24, 13, 33 },
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array1 1",
              name = "Array1 1",
              path = path,
              source_pos_id = path .. "::describe text::Array1 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array1 2",
              name = "Array1 2",
              path = path,
              source_pos_id = path .. "::describe text::Array1 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array1 3",
              name = "Array1 3",
              path = path,
              source_pos_id = path .. "::describe text::Array1 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array3 1",
              name = "Array3 1",
              path = path,
              source_pos_id = path .. "::describe text::Array3 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array3 2",
              name = "Array3 2",
              path = path,
              source_pos_id = path .. "::describe text::Array3 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array3 3",
              name = "Array3 3",
              path = path,
              source_pos_id = path .. "::describe text::Array3 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array4 1",
              name = "Array4 1",
              path = path,
              source_pos_id = path .. "::describe text::Array4 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array4 2",
              name = "Array4 2",
              path = path,
              source_pos_id = path .. "::describe text::Array4 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text::Array4 3",
              name = "Array4 3",
              path = path,
              source_pos_id = path .. "::describe text::Array4 %d",
              type = PositionType.test,
            },
          },
        },
        {
          {
            id = path .. "::describe text 2",
            is_parameterized = false,
            name = "describe text 2",
            path = path,
            range = { 18, 0, 34, 2 },
            type = PositionType.namespace,
          },
          {
            {
              id = path .. "::describe text 2::Array1 %d",
              is_parameterized = true,
              name = "Array1 %d",
              path = path,
              range = { 19, 2, 21, 4 },
              test_name_range = { 19, 22, 19, 31 },
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array2 %d",
              is_parameterized = true,
              name = "Array2 %d",
              path = path,
              range = { 23, 2, 25, 4 },
              test_name_range = { 23, 22, 23, 31 },
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array3 %d",
              is_parameterized = true,
              name = "Array3 %d",
              path = path,
              range = { 27, 2, 29, 4 },
              test_name_range = { 27, 24, 27, 33 },
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array4",
              is_parameterized = true,
              name = "Array4",
              path = path,
              range = { 31, 2, 33, 4 },
              test_name_range = { 31, 24, 31, 30 },
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array1 1",
              name = "Array1 1",
              path = path,
              source_pos_id = path .. "::describe text 2::Array1 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array1 2",
              name = "Array1 2",
              path = path,
              source_pos_id = path .. "::describe text 2::Array1 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array1 3",
              name = "Array1 3",
              path = path,
              source_pos_id = path .. "::describe text 2::Array1 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array2 1",
              name = "Array2 1",
              path = path,
              source_pos_id = path .. "::describe text 2::Array2 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array2 2",
              name = "Array2 2",
              path = path,
              source_pos_id = path .. "::describe text 2::Array2 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array2 3",
              name = "Array2 3",
              path = path,
              source_pos_id = path .. "::describe text 2::Array2 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array3 1",
              name = "Array3 1",
              path = path,
              source_pos_id = path .. "::describe text 2::Array3 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array3 2",
              name = "Array3 2",
              path = path,
              source_pos_id = path .. "::describe text 2::Array3 %d",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::describe text 2::Array3 3",
              name = "Array3 3",
              path = path,
              source_pos_id = path .. "::describe text 2::Array3 %d",
              type = PositionType.test,
            },
          },
        },
      }

      assert.are.same(positions, expected_output)
    end)

    async.it("provides meaningful names for parametric describe", function()
      package.loaded["neotest-jest"] = nil

      local path = get_test_absolute_path("parametricDescribesOnly.test.ts")
      local adapter = require("neotest-jest")({ jestCommand = "jest", jest_test_discovery = true })
      local positions = adapter.discover_positions(path):to_list()

      local expected_output = {
        {
          id = path,
          name = "parametricDescribesOnly.test.ts",
          path = path,
          range = { 0, 0, 15, 0 },
          type = PositionType.file,
        },
        {
          {
            id = path .. "::is it enabled? [%s]",
            is_parameterized = true,
            name = "is it enabled? [%s]",
            path = path,
            range = { 0, 0, 14, 2 },
            type = PositionType.namespace,
          },
          {
            {
              id = path .. "::is it enabled? [%s]::how many?: %d",
              is_parameterized = true,
              name = "how many?: %d",
              path = path,
              range = { 1, 2, 13, 4 },
              type = PositionType.namespace,
            },
            {
              {
                id = path .. "::is it enabled? [%s]::how many?: %d::test 1",
                is_parameterized = false,
                name = "test 1",
                path = path,
                range = { 2, 4, 4, 6 },
                test_name_range = { 2, 8, 2, 14 },
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [%s]::how many?: %d::test 2",
                is_parameterized = false,
                name = "test 2",
                path = path,
                range = { 6, 4, 8, 6 },
                test_name_range = { 6, 8, 6, 14 },
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [%s]::how many?: %d::test 3",
                is_parameterized = false,
                name = "test 3",
                path = path,
                range = { 10, 4, 12, 6 },
                test_name_range = { 10, 8, 10, 14 },
                type = PositionType.test,
              },
            },
          },
        },
        {
          {
            id = path .. "::is it enabled? [true]",
            name = "is it enabled? [true]",
            path = path,
            type = PositionType.namespace,
          },
          {
            {
              id = path .. "::is it enabled? [true]::how many?: 1",
              name = "how many?: 1",
              path = path,
              type = PositionType.namespace,
            },
            {
              {
                id = path .. "::is it enabled? [true]::how many?: 1::test 1",
                name = "test 1",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 1",
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [true]::how many?: 1::test 2",
                name = "test 2",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 2",
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [true]::how many?: 1::test 3",
                name = "test 3",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 3",
                type = PositionType.test,
              },
            },
          },
          {
            {
              id = path .. "::is it enabled? [true]::how many?: 2",
              name = "how many?: 2",
              path = path,
              type = PositionType.namespace,
            },
            {
              {
                id = path .. "::is it enabled? [true]::how many?: 2::test 1",
                name = "test 1",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 1",
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [true]::how many?: 2::test 2",
                name = "test 2",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 2",
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [true]::how many?: 2::test 3",
                name = "test 3",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 3",
                type = PositionType.test,
              },
            },
          },
        },
        {
          {
            id = path .. "::is it enabled? [false]",
            name = "is it enabled? [false]",
            path = path,
            type = PositionType.namespace,
          },
          {
            {
              id = path .. "::is it enabled? [false]::how many?: 1",
              name = "how many?: 1",
              path = path,
              type = PositionType.namespace,
            },
            {
              {
                id = path .. "::is it enabled? [false]::how many?: 1::test 1",
                name = "test 1",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 1",
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [false]::how many?: 1::test 2",
                name = "test 2",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 2",
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [false]::how many?: 1::test 3",
                name = "test 3",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 3",
                type = PositionType.test,
              },
            },
          },
          {
            {
              id = path .. "::is it enabled? [false]::how many?: 2",
              name = "how many?: 2",
              path = path,
              type = PositionType.namespace,
            },
            {
              {
                id = path .. "::is it enabled? [false]::how many?: 2::test 1",
                name = "test 1",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 1",
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [false]::how many?: 2::test 2",
                name = "test 2",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 2",
                type = PositionType.test,
              },
            },
            {
              {
                id = path .. "::is it enabled? [false]::how many?: 2::test 3",
                name = "test 3",
                path = path,
                source_pos_id = path .. "::is it enabled? [%s]::how many?: %d::test 3",
                type = PositionType.test,
              },
            },
          },
        },
      }

      assert.are.same(positions, expected_output)
    end)

    async.it("provides meaningful names for parametric describes and tests", function()
      package.loaded["neotest-jest"] = nil

      local path = get_test_absolute_path("parametricDescribeAndTest.test.ts")
      local adapter = require("neotest-jest")({ jestCommand = "jest", jest_test_discovery = true })
      local positions = adapter.discover_positions(path):to_list()

      local expected_output = {
        {
          id = path,
          name = "parametricDescribeAndTest.test.ts",
          path = path,
          range = { 0, 0, 12, 0 },
          type = PositionType.file,
        },
        {
          {
            id = path .. "::greeting %s",
            is_parameterized = true,
            name = "greeting %s",
            path = path,
            range = { 4, 0, 11, 2 },
            type = PositionType.namespace,
          },
          {
            {
              id = path .. "::greeting %s::should greet using %s!",
              is_parameterized = true,
              name = "should greet using %s!",
              path = path,
              range = { 5, 2, 10, 4 },
              test_name_range = { 8, 6, 8, 28 },
              type = PositionType.test,
            },
          },
        },
        {
          {
            id = path .. "::greeting Alice",
            name = "greeting Alice",
            path = path,
            type = PositionType.namespace,
          },
          {
            {
              id = path .. "::greeting Alice::should greet using Hello!",
              name = "should greet using Hello!",
              path = path,
              source_pos_id = path .. "::greeting %s::should greet using %s!",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::greeting Alice::should greet using Hi!",
              name = "should greet using Hi!",
              path = path,
              source_pos_id = path .. "::greeting %s::should greet using %s!",
              type = PositionType.test,
            },
          },
        },
        {
          {
            id = path .. "::greeting Bob",
            name = "greeting Bob",
            path = path,
            type = PositionType.namespace,
          },
          {
            {
              id = path .. "::greeting Bob::should greet using Hello!",
              name = "should greet using Hello!",
              path = path,
              source_pos_id = path .. "::greeting %s::should greet using %s!",
              type = PositionType.test,
            },
          },
          {
            {
              id = path .. "::greeting Bob::should greet using Hi!",
              name = "should greet using Hi!",
              path = path,
              source_pos_id = path .. "::greeting %s::should greet using %s!",
              type = PositionType.test,
            },
          },
        },
      }

      assert.are.same(positions, expected_output)
    end)
  end)
end)
