function someFunc(fn: () => void): () => void {
  return fn
}

describe("describe text", () => {
  it("1", someFunc(() => {
    console.log("do test");
  }));
});
