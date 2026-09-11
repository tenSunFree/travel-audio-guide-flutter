import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/path_utils.dart';

/// Align with existing conventions: GetActivitiesUseCase, GetAttractionsUseCase, etc.
/// Enforce that classes under `domain/usecases` end with `UseCase`.
class UsecaseNamingConvention extends AnalysisRule {
  UsecaseNamingConvention()
    : super(
        name: 'usecase_naming_convention',
        description:
            'Classes under domain/usecases must be named with a UseCase suffix.',
      );

  static const LintCode code = LintCode(
    'usecase_naming_convention',
    'Classes under domain/usecases must be named with a UseCase suffix.',
    correctionMessage:
        'For example: GetActivitiesUseCase, DeleteReminderUseCase.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(
      this,
      _Visitor(this),
    );
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  static const _allowedHelperSuffixes = {
    'Params',
    'Result',
    'Command',
  };

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    final path =
        unit?.declaredFragment?.source.fullName.replaceAll(r'\', '/') ?? '';
    if (isTestFilePath(path)) {
      return;
    }
    if (!path.contains('/domain/usecases/')) {
      return;
    }
    final nameToken = node.namePart.typeName;
    final className = nameToken.lexeme;
    if (_allowedHelperSuffixes.any(className.endsWith)) {
      return;
    }
    if (!className.endsWith('UseCase')) {
      rule.reportAtToken(nameToken);
    }
  }
}
