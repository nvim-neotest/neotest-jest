describe.each([true, false])('is it enabled? [%s]', isEnabled => {
  describe.each([1, 2])('how many?: %d', isEnabled => {
    it('test 1', () => {
      expect(true).toBeTruthy()
    });

    it('test 2', () => {
      expect(true).toBeTruthy()
    });

    it('test 3', () => {
      throw new Error('I have failed you');
    });
  });
});
