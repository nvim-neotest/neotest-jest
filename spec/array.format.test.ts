describe("formatted array test", () => {
  test.each([1, 2, 3])("test %p, idx: %#, %%", () => {
    console.log("do test");
  });
});
