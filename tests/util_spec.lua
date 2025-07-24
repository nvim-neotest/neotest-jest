local util = require("neotest-jest.util")

describe("util", function()
  describe("is_callable", function()
    it("checks if argument is callable", function()
      assert.True(util.is_callable(function() end))
      assert.True(util.is_callable({ __call = function() end }))
      assert.False(util.is_callable(1))
      assert.False(util.is_callable("hello"))
    end)
  end)

  describe("path", function()
    describe("join", function()
      it("joins path", function()
        assert.are.same(util.path.join("a", "b", "c"), "a/b/c")
      end)
    end)
  end)

  describe("escapeTestPattern", function()
    it("escapes test pattern", function()
      local testPattern1 = "(^this) i+s' [a] *test-pat/tern?$"
      local testPattern2 = "this is a test pattern"

      assert.are.same(
        util.escapeTestPattern(testPattern1),
        "\\(\\^this\\) i\\+s\\' \\[a\\] \\*test\\-pat\\/tern\\?\\$"
      )
      assert.are.same(util.escapeTestPattern(testPattern2), testPattern2)
    end)
  end)
end)
