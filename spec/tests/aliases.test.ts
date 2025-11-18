const fakeAsync = (fn: () => void): (() => void) => {
  return () => fn()
}

describe('describe', () => {
  it.only('it.only', () => {
    expect(true).toBe(true)
  }) 

  it.failing('it.failing', () => {
    expect(true).toBe(false)
  }) 

  it.concurrent('it.concurrent', () => {
    expect(true).toBe(true)
  }) 

  it.only.failing('it.only.failing', function() {
    expect(true).toBe(false)
  }) 

  it.skip.failing('it.skip.failing', () => {
    expect(true).toBe(false)
  }) 

  fit.failing('fit.failing', fakeAsync(() => {
    expect(true).toBe(false)
  }))

  xit.failing('xit.failing', () => {
    expect(true).toBe(false)
  }) 

  it.todo('it.todo')
})

fdescribe('fdescribe', function() {
  test.only('test.only', function() {
    expect(true).toBe(true)
  }) 

  test.failing('test.failing', () => {
    expect(true).toBe(false)
  }) 

  test.concurrent('test.concurrent', fakeAsync(() => {
    expect(true).toBe(true)
  }) )

  test.only.failing('test.only.failing', () => {
    expect(true).toBe(false)
  }) 

  test.skip.failing('test.skip.failing', function() {
    expect(true).toBe(false)
  }) 

  xtest.failing('xtest.failing', () => {
    expect(true).toBe(false)
  }) 

  test.todo('test.todo')
})

xdescribe('xdescribe', () => {
  it.each([1, 2])('it.each %d', () => {
    expect(true).toBe(true)
  })

  it.only.each([1, 2])('it.only.each %d', () => {
    expect(true).toBe(true)
  })

  it.failing.each([1, 2])('it.failing.each %d', () => {
    expect(true).toBe(false)
  })

  it.skip.each([1, 2])('it.skip.each %d', fakeAsync(() => {
    expect(true).toBe(true)
  }))

  it.concurrent.each([1, 2])('it.concurrent.each %d', () => {
    expect(true).toBe(true)
  })

  it.concurrent.only.each([1, 2])('it.concurrent.only.each %d', () => {
    expect(true).toBe(true)
  })

  it.concurrent.skip.each([1, 2])('it.concurrent.skip.each %d', function() {
    expect(true).toBe(true)
  })

  fit.each([1, 2])('fit.each %d', () => {
    expect(true).toBe(true)
  })

  xit.each([1, 2])('xit.each %d', fakeAsync(() => {
    expect(true).toBe(true)
  }))

  test.each([1, 2])('test.each %d', () => {
    expect(true).toBe(true)
  })

  test.only.each([1, 2])('test.only.each %d', () => {
    expect(true).toBe(true)
  })

  test.failing.each([1, 2])('test.failing.each %d', () => {
    expect(true).toBe(false)
  })

  test.skip.each([1, 2])('test.skip.each %d', function() {
    expect(true).toBe(true)
  })

  test.concurrent.each([1, 2])('test.concurrent.each %d', () => {
    expect(true).toBe(true)
  })

  test.concurrent.only.each([1, 2])('test.concurrent.only.each %d', () => {
    expect(true).toBe(true)
  })

  test.concurrent.skip.each([1, 2])('test.concurrent.skip.each %d', () => {
    expect(true).toBe(true)
  })

  xtest.each([1, 2])('xtest.each %d', function() {
    expect(true).toBe(true)
  })
})

describe.only('describe.only', () => {})

describe.skip('describe.skip', () => {})
