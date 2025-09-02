local jest_util = require("neotest-jest.jest-util")

describe("jest-util", function()
  describe("getTestFullIdFromTestResult", function()
    it("gets test full id from test result", function()
      local testFile = "some/path/mytest.test.ts"
      local assertionResult = {
        ancestorTitles = {
          "describe",
          "nested",
        },
        title = "test 1",
      }

      assert.are.same(
        jest_util.getTestFullIdFromTestResult(testFile, assertionResult),
        ("%s::describe::nested::test 1"):format(testFile)
      )
    end)
  end)

  describe("getJestConfig", function()
    it("gets jest config", function()
      assert.are.same(jest_util.getJestConfig("./spec"), "./spec/jest.config.ts")
      assert.Nil(jest_util.getJestConfig("."))
    end)
  end)
end)
