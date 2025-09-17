// it('[TEST1] should run this test', () => {
//   expect(true).toBeTruthy()
// });
//
// it('xx[TEST1] should run this test', () => {
//   expect(true).toBeTruthy()
// });

describe.each([true, false])('is it enabled? [%s]', isEnabled => {
  it('[TEST1] should run this test', () => {
   expect(true).toBeTruthy()
  });

  //it('xx[TEST1] should run this test', () => {
  //  expect(true).toBeTruthy()
  //});
  //

  // it('[TEST2] dont run this test', () => {
  //   throw new Error('I have failed you');
  // });
});
