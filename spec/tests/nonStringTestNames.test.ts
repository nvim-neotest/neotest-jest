class Test {
  public name: string

  constructor(name: string) {
    this.name = name
  }
}

const arrow = () => {}

function func(): void {}

const test = new Test('name')

describe('non-string test names', () => {
  it(Test, () => {
    expect(true).toBe(true)
  })

  it(test.name, () => {
    expect(true).toBe(true)
  })

  it(arrow, () => {
    expect(true).toBe(true)
  })

  it(func, () => {
    expect(true).toBe(true)
  })

  it(123, () => {
    expect(true).toBe(true)
  })
})
