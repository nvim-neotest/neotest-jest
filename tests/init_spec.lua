local stub = require("luassert.stub")
local async = require("nio").tests
local plugin = require("neotest-jest")({
  jestCommand = "jest",
})
local Tree = require("neotest.types").Tree
require("neotest-jest-assertions")
A = function(...)
  print(vim.inspect(...))
end

describe("adpter root", function()
  async.it("jest is installed", function()
    assert.Not.Nil(plugin.root("./spec"))
  end)
end)

describe("is_test_file", function()
  it("matches jest files", function()
    assert.True(plugin.is_test_file("./spec/basic.test.ts"))
  end)

  it("does not match plain js files", function()
    assert.False(plugin.is_test_file("./index.ts"))
  end)
end)

describe("discover_positions", function()
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
    local positions = plugin.discover_positions("./spec/basic.test.ts"):to_list()

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
      },
    }

    assert.equals(expected_output[1].name, positions[1].name)
    assert.equals(expected_output[1].type, positions[1].type)
    assert.equals(expected_output[2][1].name, positions[2][1].name)
    assert.equals(expected_output[2][1].type, positions[2][1].type)

    assert.equals(positions[2][1].is_parameterized, false)

    assert.equals(5, #positions[2])
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

    assert.equals(5, #positions[2])
    assert_test_positions_match(expected_output[2][2], positions[2])

    assert.equals(5, #positions[3])
    assert_test_positions_match(expected_output[3][2], positions[3])
  end)

  async.it("provides meaningful names for array driven tests", function()
    stub(require("neotest.lib").process, "run")
    local positions = plugin.discover_positions("./spec/array.test.ts"):to_list()

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
            name = "Array1",
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
            name = "Array3",
            type = "test",
            is_parameterized = true,
          },
        },
        {
          {
            name = "Array4",
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
            name = "Array1",
            type = "test",
          },
        },
        {
          {
            name = "Array2",
            type = "test",
          },
        },
        {
          {
            name = "Array3",
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
end)

describe("build_spec", function()
  async.it("builds command for file test", function()
    local positions = plugin.discover_positions("./spec/basic.test.ts"):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = plugin.build_spec({ tree = tree })

    assert.is.truthy(spec)
    local command = spec.command
    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--json")
    assert.is_not.contains(command, "--config=jest.config.js")
    assert.contains(command, "--testNamePattern='.*'")
    assert.contains(command, "./spec/basic.test.ts")
    assert.is.truthy(spec.context.file)
    assert.is.truthy(spec.context.results_path)
  end)

  async.it("builds command for file test with jestCommand arg", function()
    local positions = plugin.discover_positions("./spec/basic.test.ts"):to_list()
    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    local spec = plugin.build_spec({ tree = tree, jestCommand = 'jest --watch ' })

    assert.is.truthy(spec)
    local command = spec.command
    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--watch")
    assert.contains(command, "--json")
    assert.is_not.contains(command, "--config=jest.config.js")
    assert.contains(command, "--testNamePattern='.*'")
    assert.contains(command, "./spec/basic.test.ts")
    assert.is.truthy(spec.context.file)
    assert.is.truthy(spec.context.results_path)
  end)

  async.it("builds command for namespace", function()
    local positions = plugin.discover_positions("./spec/basic.test.ts"):to_list()

    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)

    local spec = plugin.build_spec({ tree = tree:children()[1] })

    assert.is.truthy(spec)
    local command = spec.command
    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--json")
    assert.is_not.contains(command, "--config=jest.config.js")
    assert.contains(command, "--testNamePattern='^describe text'")
    assert.contains(command, "./spec/basic.test.ts")
    assert.is.truthy(spec.context.file)
    assert.is.truthy(spec.context.results_path)
  end)

  async.it("builds command for nested namespace", function()
    local positions = plugin.discover_positions("./spec/nestedDescribe.test.ts"):to_list()

    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)

    local spec = plugin.build_spec({ tree = tree:children()[1]:children()[1]:children()[1] })

    assert.is.truthy(spec)
    local command = spec.command
    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--json")
    assert.is_not.contains(command, "--config=jest.config.js")
    assert.contains(command, "--testNamePattern='^outer middle inner'")
    assert.contains(command, "./spec/nestedDescribe.test.ts")
    assert.is.truthy(spec.context.file)
    assert.is.truthy(spec.context.results_path)
  end)

  async.it("builds correct command for test name with ' ", function()
    local positions = plugin.discover_positions("./spec/nestedDescribe.test.ts"):to_list()

    local tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)

    local spec =
      plugin.build_spec({ tree = tree:children()[1]:children()[1]:children()[1]:children()[2] })
    assert.is.truthy(spec)
    local command = spec.command
    assert.is.truthy(command)
    assert.contains(command, "jest")
    assert.contains(command, "--json")
    assert.is_not.contains(command, "--config=jest.config.js")
    assert.contains(command, "--testNamePattern='^outer middle inner this has a \\'$'")
    assert.contains(command, "./spec/nestedDescribe.test.ts")
    assert.is.truthy(spec.context.file)
    assert.is.truthy(spec.context.results_path)
  end)

  describe("parameterized test names", function()
    for _, test_data in ipairs({
      { index = 1, expected_name = "^describe text test with percent .*$" },
      {
        index = 2,
        expected_name = "^describe text test with all of the parameters .* .* .* .* .* .* .* .* .* .* .* .* .* .* .* .* .* .*$",
      },
      { index = 3, expected_name = "^describe text test with .*$" },
      { index = 4, expected_name = "^describe text test with .* and .*$" },
      { index = 5, expected_name = "^describe text test with .*$" },
      { index = 6, expected_name = "^describe text test with .* and \\(parenthesis\\)$" },
    }) do
      async.it("builds command with correct test name pattern " .. test_data.index, function()
        -- mock neotest process run to not run jest test discovery
        stub(require("neotest.lib").process, "run")

        local positions = plugin.discover_positions("./spec/parameterized.test.ts"):to_list()

        local tree = Tree.from_list(positions, function(pos)
          return pos.id
        end)

        local spec = plugin.build_spec({ tree = tree:children()[1]:children()[test_data.index] })
        assert.contains(spec.command, "--testNamePattern='" .. test_data.expected_name .. "'")
      end)
    end
  end)
end)
