function greet(name: string, salutation: string): string {
  return `${salutation}, ${name}!`
}

describe.each([['Alice'], ['Bob']])('greeting %s', (name) => {
  it.each([
    ['Hello'],
    ['Hi'],
  ])('should greet using %s!', (salutation) => {
    expect(greet(name, salutation)).toBe(`${salutation}, ${name}!`);
  });
});
