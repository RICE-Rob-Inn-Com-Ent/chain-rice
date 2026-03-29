//! CEL runtime — compile expressions, bind variables, evaluate against a [`Context`](cel_interpreter::Context).

use cel_interpreter::{Context, Program, Value};
use cel_interpreter::objects::ResolveResult;

// [ ] https://docs.rs/cel-interpreter/
// [ ] PolicyEngine — Context, rules, mode from RICE_POLICY_ENGINE_MODE
// [ ] load rules from RICE_POLICY_RULES_DIR; validate CEL on load; evaluate / evaluate_batch; rayon when RICE_POLICY_PARALLEL
// [ ] hot reload; OTel spans; CEL custom funcs — decimal, business_day, currency_convert via calc/

/// Compile a CEL source string into an executable program.
pub fn compile(source: &str) -> Result<Program, cel_interpreter::ParseError> {
    Program::compile(source)
}

/// Evaluate a compiled program with the given evaluation context.
pub fn evaluate(program: &Program, ctx: &Context) -> ResolveResult {
    program.execute(ctx)
}

/// Fresh context with standard CEL functions; extend with `add_variable` / `add_function` as needed.
pub fn root_context() -> Context<'static> {
    Context::default()
}

/// Bind a variable from a CEL [`Value`] (see `cel_interpreter::to_value` for adapters).
pub fn bind_value(ctx: &mut Context<'_>, name: &str, value: Value) {
    ctx.add_variable_from_value(name, value);
}

#[cfg(test)]
mod tests {
    use super::*;
    use cel_interpreter::Value;

    #[test]
    fn evaluates_literal_true() {
        let program = compile("true").unwrap();
        let ctx = root_context();
        assert_eq!(evaluate(&program, &ctx).unwrap(), Value::Bool(true));
    }
}
