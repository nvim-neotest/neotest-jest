describe.each([['Alice'], ['Bob']])('greeting %s', (name) => {
  it.each([
    ['Hello'],
    ['Hi'],
  ])('should greet using %s!', (salutation) => {
    expect(`${salutation}, ${name}!`).toBe(`${salutation}, ${name}!`);
  });
});
