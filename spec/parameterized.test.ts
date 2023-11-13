describe("describe text", () => {
  it.each(["string"])("test with percent %%", () => {
    console.log("do test");
  });

  it.each(["string"])(
    "test with all of the parameters %p %s %d %i %f %j %o %# %% %p %s %d %i %f %j %o %# %%",
    async () => {
      console.log("do test");
    }
  );

  it.each(["string"])("test with $namedParameter", () => {
    console.log("do test");
  });

  it.each(["string"])(
    "test with $namedParameter and $anotherNamedParameter",
    async () => {
      console.log("do test");
    }
  );

  it.each(["string"])("test with $variable.field.otherField", async () => {
    console.log("do test");
  });

  it.each(["string"])(
    "test with $variable.field.otherField and (parenthesis)",
    async () => {
      console.log("do test");
    }
  );
});
