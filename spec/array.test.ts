describe("describe text", () => {
  it.each([1, 2, 3])("Array1", () => {
    console.log("do test");
  });

  it.each([1, 2, 3])("Array2", async () => {
    console.log("do test");
  });

  test.each([1, 2, 3])("Array3", () => {
    console.log("do test");
  });

  test.each([1, 2, 3])("Array4", async () => {
    console.log("do test");
  });
});

describe("describe text 2", function() {
  it.each([1, 2, 3])("Array1", function() {
    console.log("do test");
  });

  it.each([1, 2, 3])("Array2", async function() {
    console.log("do test");
  });

  test.each([1, 2, 3])("Array3", function() {
    console.log("do test");
  });

  test.each([1, 2, 3])("Array4", async function() {
    console.log("do test");
  });
});
