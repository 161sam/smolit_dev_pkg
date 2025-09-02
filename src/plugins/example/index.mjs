// src/plugins/example/index.mjs - Example JS plugin for Node CLI
export function register(registerFn, env) {
  registerFn("example:js", async (args, env) => {
    console.log("Hello from JS plugin!");
    console.log("Args:", args);
    console.log("Workspace:", env.WORKSPACE || process.cwd());
    console.log("Bridge Port:", env.BRIDGE_PORT || 8815);
  }, "Demo JS Plugin");

  registerFn("example:env", async (args, env) => {
    console.log("Environment variables:");
    console.log("WORKSPACE:", env.WORKSPACE);
    console.log("OH_PORT:", env.OH_PORT);
    console.log("BRIDGE_PORT:", env.BRIDGE_PORT);
    console.log("LM_BASE_URL:", env.LM_BASE_URL);
  }, "Show environment info");
}