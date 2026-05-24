import 'package:drift/drift.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../db/database.dart';

/// Optional bounds for metrics that look like supply rails (keys containing `volt`).
typedef RailVoltageBounds = ({double minVoltage, double maxVoltage});

/// Reactive form for creating or editing a [Rules] row.
FormGroup buildRuleFormGroup({RailVoltageBounds? railBounds}) {
  final thresholdValidators = <Validator<dynamic>>[Validators.required];
  final bounds = railBounds;
  if (bounds != null) {
    thresholdValidators.add(
      DelegateValidator(
        (AbstractControl<dynamic> c) => _railThresholdValidatorBody(bounds, c),
      ),
    );
  }

  return FormGroup({
    'name': FormControl<String>(validators: [Validators.required]),
    'metricKey': FormControl<String>(validators: [Validators.required]),
    'compareOp': FormControl<String>(
      value: 'gt',
      validators: [
        Validators.required,
        Validators.pattern(RegExp(r'^(gt|ge|lt|le|eq)$')),
      ],
    ),
    'threshold': FormControl<double>(validators: thresholdValidators),
    'action': FormControl<String>(validators: [Validators.required]),
    'priority': FormControl<int>(
      value: 0,
      validators: [Validators.number(allowNegatives: true, allowNull: false)],
    ),
    'enabled': FormControl<bool>(value: true),
  });
}

Map<String, dynamic>? _railThresholdValidatorBody(
  RailVoltageBounds bounds,
  AbstractControl<dynamic> control,
) {
    final parent = control.parent;
    if (parent is! FormGroup) {
      return null;
    }
    final metricRaw = parent.control('metricKey').value;
    if (metricRaw is! String) {
      return null;
    }
    if (!metricRaw.toLowerCase().contains('volt')) {
      return null;
    }
    final v = control.value;
    if (v is! num) {
      return null;
    }
    if (v > bounds.maxVoltage) {
      return {'railMax': bounds.maxVoltage};
    }
    if (v < bounds.minVoltage) {
      return {'railMin': bounds.minVoltage};
    }
    return null;
}

/// Builds an insert companion from a valid [form] (call when `form.valid`).
RulesCompanion ruleCompanionFromForm(FormGroup form) {
  return RulesCompanion.insert(
    name: form.control('name').value as String,
    metricKey: form.control('metricKey').value as String,
    compareOp: form.control('compareOp').value as String,
    threshold: (form.control('threshold').value as num).toDouble(),
    action: form.control('action').value as String,
    priority: Value(form.control('priority').value as int),
    enabled: Value(form.control('enabled').value as bool? ?? true),
  );
}

/// Applies an existing [rule] into [form] controls.
void patchRuleForm(FormGroup form, Rule rule) {
  form.control('name').value = rule.name;
  form.control('metricKey').value = rule.metricKey;
  form.control('compareOp').value = rule.compareOp;
  form.control('threshold').value = rule.threshold;
  form.control('action').value = rule.action;
  form.control('priority').value = rule.priority;
  form.control('enabled').value = rule.enabled;
}
