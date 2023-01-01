describe("describe text", () => {
  it("1", () => {
    console.log("do test");
  });

  it("2", async () => {
    console.log("do test");
  });

  test("3", () => {
    console.log("do test");
  });

  test("4", async () => {
    console.log("do test");
  });
});

describe("describe text 2", function() {
  it("1", function() {
    console.log("do test");
  });

  it("2", async function() {
    console.log("do test");
  });

  test("3", function() {
    console.log("do test");
  });

  test("4", async function() {
    console.log("do test");
  });
})
