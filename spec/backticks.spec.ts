describe("test names containing backticks", () => {
  it("`", () => {
    console.log("do test");
  });

  test("`", () => {
    console.log("do test");
  });

  it("``", () => {
    console.log("do test");
  });

  test("``", () => {
    console.log("do test");
  });
});
