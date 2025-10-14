local nio = require("nio")
local async = nio.tests
local test_utils = require("neotest-jest.test-utils")
local neotest_types = require("neotest.types")

local PositionType = neotest_types.PositionType

test_utils.prepare_vim_treesitter()

describe("adapter.discover_positions", function()
  assert:set_parameter("TableFormatLevel", 10)

  assert:set_parameter("TableFormatLevel", 10)

  async.it("provides meaningful names from a basic spec", function()
    package.loaded["neotest-jest"] = nil

    local path = vim.fs.normalize(vim.fs.abspath("./spec/tests/basic.test.ts"))
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
    local positions = adapter.discover_positions("./spec/templateStrings.test.ts"):to_list()

    local expected_output = {
      {
        name = "templateStrings.test.ts",
        type = "file",
      },
      {
        {
          name = "describe text",
          type = "namespace",
        },
        {
          name = "1",
          type = "test",
        },
        {
          name = "2",
          type = "test",
        },
        {
          name = "3",
          type = "test",
        },
        {
          name = "4",
          type = "test",
        },
        {
          name = "5",
          type = "test",
        },
      },
      {
        {
          name = "describe text 2",
          type = "namespace",
        },
        {
          name = "1",
          type = "test",
        },
        {
          name = "2",
          type = "test",
        },
        {
          name = "3",
          type = "test",
        },
        {
          name = "4",
          type = "test",
        },
        {
          name = "5",
          type = "test",
        },
      },
    }

    assert.equals(expected_output[1].name, positions[1].name)
    assert.equals(expected_output[1].type, positions[1].type)
    assert.equals(expected_output[2][1].name, positions[2][1].name)
    assert.equals(expected_output[2][1].type, positions[2][1].type)

    assert.equals(positions[2][1].is_parameterized, false)
    assert.equals(6, #positions[2])

    for i, value in ipairs(expected_output[2][2]) do
      assert.is.truthy(value)
      local position = positions[2][i + 1][1]
      assert.is.truthy(position)
      assert.equals(value.name, position.name)
      assert.equals(value.type, position.type)
      assert.equals(position.is_parameterized, false)
    end

    assert.equals(expected_output[3][1].name, positions[3][1].name)
    assert.equals(expected_output[3][1].type, positions[3][1].type)

    assert.equals(6, #positions[2])
    assert_test_positions_match(expected_output[2][2], positions[2])

    assert.equals(6, #positions[3])
    assert_test_positions_match(expected_output[3][2], positions[3])
  end)

  async.it("provides meaningful names from a spec with backticks in test names", function()
    local path = "./spec/backtickInTestNames.test.ts"
    local positions = adapter.discover_positions(path):to_list()

    local expected_output = {
      {
        id = path,
        name = "backtickInTestNames.test.ts",
        path = path,
        range = { 0, 0, 17, 0 },
        type = "file",
      },
      {
        {
          id = path .. "::test names ` containing backticks",
          is_parameterized = false,
          name = "test names ` containing backticks",
          path = path,
          range = { 0, 0, 16, 2 },
          type = "namespace",
        },
        {
          {
            id = path .. "::test names ` containing backticks::` 1",
            is_parameterized = false,
            name = "` 1",
            path = path,
            range = { 1, 2, 3, 4 },
            type = "test",
          },
        },
        {
          {
            id = path .. "::test names ` containing backticks::2`",
            is_parameterized = false,
            name = "2`",
            path = path,
            range = { 5, 2, 7, 4 },
            type = "test",
          },
        },
        {
          {
            id = path .. "::test names ` containing backticks::`` 3",
            is_parameterized = false,
            name = "`` 3",
            path = path,
            range = { 9, 2, 11, 4 },
            type = "test",
          },
        },
        {
          {
            id = path .. "::test names ` containing backticks::` 4`",
            is_parameterized = false,
            name = "` 4`",
            path = path,
            range = { 13, 2, 15, 4 },
            type = "test",
          },
        },
      },
    }

    assert.are.same(positions, expected_output)
  end)

  async.it("provides meaningful names for parametric tests", function()
    package.loaded["neotest-jest"] = nil

    local path = vim.fs.normalize(vim.fs.abspath("./spec/tests/array.test.ts"))
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

  async.it(
    "provides meaningful names for parametric tests with parametric test discovery",
    function()
      package.loaded["neotest-jest"] = nil

      local path = vim.fs.normalize(vim.fs.abspath("./spec/tests/array.test.ts"))
      local adapter = require("neotest-jest")({ jestCommand = "jest", jest_test_discovery = true })

      nio.fn.chdir("./spec")
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

      nio.fn.chdir("..")
    end
  )

  async.it("provides meaningful names for parametric describe", function()
    package.loaded["neotest-jest"] = nil

    local path = vim.fs.normalize(vim.fs.abspath("./spec/tests/parametric-describes-only.test.ts"))
    local adapter = require("neotest-jest")({ jestCommand = "jest", jest_test_discovery = true })

    nio.fn.chdir("./spec")
    local positions = adapter.discover_positions(path):to_list()

    local expected_output = {
      {
        id = path,
        name = "parametric-describes-only.test.ts",
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

    nio.fn.chdir("..")
  end)
end)
