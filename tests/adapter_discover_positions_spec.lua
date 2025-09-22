local adapter = require("neotest-jest")({ jestCommand = "jest" })
local async = require("nio").tests
local stub = require("luassert.stub")
local test_utils = require("neotest-jest.test-utils")

test_utils.prepare_vim_treesitter()

describe("adapter.discover_positions", function()
  local assert_test_positions_match = function(expected_output, positions)
    for i, value in ipairs(expected_output) do
      assert.is.truthy(value)
      local position = positions[i + 1][1]
      assert.is.truthy(position)
      assert.equals(value.name, position.name)
      assert.equals(value.type, position.type)
    end
  end

  async.it("provides meaningful names from a basic spec", function()
    local positions = adapter.discover_positions("./spec/tests/basic.test.ts"):to_list()

    local expected_output = {
      {
        name = "basic.test.ts",
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

  async.it("provides meaningful names for parametric tests", function()
    stub(require("neotest.lib").process, "run")
    local positions = adapter.discover_positions("./spec/tests/array.test.ts"):to_list()

    local expected_output = {
      {
        name = "array.test.ts",
        type = "file",
        is_parameterized = false,
      },
      {
        {
          name = "describe text",
          type = "namespace",
          is_parameterized = false,
        },
        {
          {
            name = "Array1 %d",
            type = "test",
            is_parameterized = true,
          },
        },
        {
          {
            name = "Array2",
            type = "test",
            is_parameterized = true,
          },
        },
        {
          {
            name = "Array3 %d",
            type = "test",
            is_parameterized = true,
          },
        },
        {
          {
            name = "Array4 %d",
            type = "test",
          },
        },
      },
      {
        {
          name = "describe text 2",
          type = "namespace",
        },
        {
          {
            name = "Array1 %d",
            type = "test",
          },
        },
        {
          {
            name = "Array2 %d",
            type = "test",
          },
        },
        {
          {
            name = "Array3 %d",
            type = "test",
          },
        },
        {
          {
            name = "Array4",
            type = "test",
            is_parameterized = true,
          },
        },
      },
    }
    assert.equals(expected_output[1].name, positions[1].name)
    assert.equals(expected_output[1].type, positions[1].type)
    assert.equals(expected_output[2][1].name, positions[2][1].name)
    assert.equals(expected_output[2][1].type, positions[2][1].type)

    assert.equals(expected_output[2][1].is_parameterized, positions[2][1].is_parameterized)

    for i, value in ipairs(expected_output[2][2]) do
      assert.is.truthy(value)
      local position = positions[2][i + 1][1]
      assert.is.truthy(position)
      assert.equals(value.name, position.name)
      assert.equals(value.type, position.type)
      assert.equals(value.is_parameterized, position.is_parameterized)
    end

    assert.equals(5, #positions[2])
    assert_test_positions_match(expected_output[2][2], positions[2])

    assert.equals(5, #positions[3])
    assert_test_positions_match(expected_output[3][2], positions[3])
  end)

  async.it("provides meaningful names for parametric describe", function() end)
end)
