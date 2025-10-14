describe("test names ` containing backticks", () => {
  it("` 1", () => {
    console.log("do test");
  });

  test("2`", () => {
    console.log("do test");
  });

  it("`` 3", () => {
    console.log("do test");
  });

  test("` 4`", () => {
    console.log("do test");
  });
});
