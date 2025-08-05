local adapter = require("neotest-jest")({ jestCommand = "jest" })
local async = require("nio").tests
local util = require("neotest-jest.util")

describe("adapter.is_test_file", function()
  async.it("matches jest test files", function()
    assert.True(adapter.is_test_file("./spec/basic.test.ts"))
    assert.True(adapter.is_test_file("./spec/__tests__/some.test.ts"))
  end)

  async.it("does not match nil or plain js/ts files", function()
    assert.False(adapter.is_test_file(nil))
    assert.False(adapter.is_test_file("./index.js"))
    assert.False(adapter.is_test_file("./index.ts"))
  end)

  async.it("matches all supported extensions", function()
    for _, extension in ipairs(util.getDefaultTestExtensions()) do
      local path = "./spec/file." .. extension[1] .. "." .. extension[2]
      local result = adapter.is_test_file(path)

      if not result then
        vim.print(path)
      end

      assert.True(result)
    end
  end)

  async.it("uses isTestFile option if given", function()
    local _adapter = require("neotest-jest")({
      jestCommand = "jest",
      isTestFile = function(file_path)
        if not file_path then
          return false
        end

        return vim.fn.fnamemodify(file_path, ":e:e") == "testy.js"
      end,
    })

    assert.False(_adapter.is_test_file(nil))
    assert.False(_adapter.is_test_file("./spec/basic.test.ts"))
    assert.False(_adapter.is_test_file("./spec/__tests__/some.test.ts"))
    assert.False(_adapter.is_test_file("./spec/test.test.ts"))
    assert.True(_adapter.is_test_file("./spec/test.testy.js"))
  end)
end)
