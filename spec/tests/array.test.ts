describe("describe text", () => {
  it.each([1, 2, 3])("Array1 %d", () => {
    console.log("do test");
  });

  it.each([1, 2, 3])("Array2", async () => {
    console.log("do test");
  });

  test.each([1, 2, 3])("Array3 %d", () => {
    console.log("do test");
  });

  test.each([1, 2, 3])("Array4 %d", async () => {
    console.log("do test");
  });
});

describe("describe text 2", function() {
  it.each([1, 2, 3])("Array1 %d", function() {
    console.log("do test");
  });

  it.each([1, 2, 3])("Array2 %d", async function() {
    console.log("do test");
  });

  test.each([1, 2, 3])("Array3 %d", function() {
    console.log("do test");
  });

  test.each([1, 2, 3])("Array4", async function() {
    console.log("do test");
  });
});
