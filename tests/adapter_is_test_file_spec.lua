local adapter = require("neotest-jest")({ jestCommand = "jest" })
local async = require("nio").tests
local stub = require("luassert.stub")
local util = require("neotest-jest.util")

describe("adapter.is_test_file", function()
  async.it("matches jest test files", function()
    assert.True(adapter.is_test_file("./spec/basic.test.ts"))
  end)

  async.it("does not match plain js/ts files", function()
    assert.False(adapter.is_test_file("./index.js"))
    assert.False(adapter.is_test_file("./index.ts"))
  end)
end)
