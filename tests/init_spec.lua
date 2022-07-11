local async = require("plenary.async.tests")
local plugin = require("neotest-jest")

describe("is_test_file", function()
  it("matches jest files", function()
    assert.equals(true, plugin.is_test_file("./spec/basic.test.ts"))
  end)

  it("does not match plain js files", function()
    assert.equals(false, plugin.is_test_file("./index.ts"))
  end)
end)

describe("discover_positions", function()
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
      },
    }

    assert.equals(expected_output[1].name, positions[1].name)
    assert.equals(expected_output[1].type, positions[1].type)
    assert.equals(expected_output[2][1].name, positions[2][1].name)
    assert.equals(expected_output[2][1].type, positions[2][1].type)

    for i, value in ipairs(expected_output[2][2]) do
      local position = positions[2][i + 1][1]
      assert.equals(value.name, position.name)
      assert.equals(value.type, position.type)
    end
  end)
end)
