class Calculator {
  public sum(a: number, b: number): number {
    return a + b
  }

  toString() {
    return "Custom message"
  }
};

describe(Calculator, () => {    // <---- will not match
  it("sum a and b", () => {     // <---- run the nearest test
    expect(new Calculator().sum(1, 2)).toEqual(3);
  });
});
