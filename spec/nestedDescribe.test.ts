
describe('outer', () => {
  describe('middle', function() {
    describe('inner', () => {
      it('should do a thing', () => {
        expect('hello').toEqual('hello');
      });
      it("this has a '", () => {
        expect('hello').toEqual('hello');
      });
    });
  })
});
