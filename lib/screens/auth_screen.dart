import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';
import '../widgets/tj_widgets.dart';

/// Toss-style "1 thing for 1 page" auth flow.
///
/// One question per screen. The active input always sits at the top, just under
/// the title where the cursor lives; each answered field stacks *below* it as a
/// compact, tappable recap (newest first). The CTA is pinned above the keyboard
/// so it never gets pushed off-screen. Email is asked first; once we know
/// whether the account exists we branch into login (password only) or signup
/// (nickname → password → agreements) — all on this same stacking surface.
///
/// Reference: https://toss.tech/article/toss-signup-process
enum _Field { email, password, passwordConfirm, nickname, agreements }

enum _Mode { unknown, login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  _Mode _mode = _Mode.unknown;
  _Field _active = _Field.email;

  /// Fields the user has already answered, in completion order.
  final List<_Field> _done = [];

  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _submitting = false;
  bool _checkingEmail = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;

  bool get _busy => _submitting || _checkingEmail;

  static final _emailRe = RegExp(r'^\S+@\S+\.\S+$');

  // Signup password complexity rules.
  static final _upperRe = RegExp(r'[A-Z]');
  static final _lowerRe = RegExp(r'[a-z]');
  static final _digitRe = RegExp(r'[0-9]');
  static final _specialRe = RegExp(r'[^A-Za-z0-9]');

  bool get _pwLen => _passwordCtrl.text.length >= 8;
  bool get _pwUpper => _upperRe.hasMatch(_passwordCtrl.text);
  bool get _pwLower => _lowerRe.hasMatch(_passwordCtrl.text);
  bool get _pwDigit => _digitRe.hasMatch(_passwordCtrl.text);
  bool get _pwSpecial => _specialRe.hasMatch(_passwordCtrl.text);
  bool get _pwValid => _pwLen && _pwUpper && _pwLower && _pwDigit && _pwSpecial;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  // ── Step dispatch ───────────────────────────────────────────
  Future<void> _next() async {
    if (_busy) return;
    switch (_active) {
      case _Field.email:
        await _submitEmail();
      case _Field.nickname:
        _submitNickname();
      case _Field.password:
        if (_mode == _Mode.login) {
          await _submitLogin();
        } else {
          _submitPasswordForSignup();
        }
      case _Field.passwordConfirm:
        _submitPasswordConfirm();
      case _Field.agreements:
        await _submitSignup();
    }
  }

  /// Move to a new active field, parking the current answer in the recap stack.
  void _advance(_Field next) => setState(() {
        if (!_done.contains(_active)) _done.add(_active);
        _active = next;
        _error = null;
        _obscure = true;
      });

  /// Tapping a recap chip re-opens that field for editing and forgets every
  /// answer that came after it.
  void _edit(_Field field) {
    final i = _done.indexOf(field);
    if (i < 0) return;
    setState(() {
      _done.removeRange(i, _done.length);
      _active = field;
      _error = null;
      _obscure = true;
      _obscureConfirm = true;
      // Changing the password invalidates the prior confirmation entry.
      if (field == _Field.password) _passwordConfirmCtrl.clear();
      // Re-checking the email may change which branch (login/signup) we take.
      if (field == _Field.email) _mode = _Mode.unknown;
    });
  }

  // ── email → branch into login or signup ─────────────────────
  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = '이메일 형식이 좀 이상해요');
      return;
    }
    setState(() {
      _checkingEmail = true;
      _error = null;
    });
    try {
      final available = await context.read<AuthProvider>().isEmailAvailable(email);
      if (!mounted) return;
      setState(() {
        _checkingEmail = false;
        // available == not registered → signup; otherwise → login.
        _mode = available ? _Mode.signup : _Mode.login;
        if (!_done.contains(_Field.email)) _done.add(_Field.email);
        _active = available ? _Field.nickname : _Field.password;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '확인에 실패했어요: $e');
    } finally {
      if (mounted) setState(() => _checkingEmail = false);
    }
  }

  void _submitNickname() {
    if (_nicknameCtrl.text.trim().isEmpty) {
      setState(() => _error = '닉네임을 입력해 주세요');
      return;
    }
    _advance(_Field.password);
  }

  void _submitPasswordForSignup() {
    if (!_pwValid) {
      setState(() => _error = '대소문자·숫자·특수문자를 모두 포함해 8자 이상이어야 해요');
      return;
    }
    _advance(_Field.passwordConfirm);
  }

  void _submitPasswordConfirm() {
    if (_passwordConfirmCtrl.text != _passwordCtrl.text) {
      setState(() => _error = '비밀번호가 일치하지 않아요');
      return;
    }
    _advance(_Field.agreements);
  }

  Future<void> _submitLogin() async {
    if (_passwordCtrl.text.length < 4) {
      setState(() => _error = '비밀번호 다시 한번 천천히');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(_emailCtrl.text.trim(), _passwordCtrl.text);
      // On success AuthGate swaps to HomeScreen.
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '요청에 실패했습니다: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitSignup() async {
    if (!_agreeTerms || !_agreePrivacy) {
      setState(() => _error = '약관 및 개인정보 수집·이용에 동의해 주세요');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            nickname: _nicknameCtrl.text.trim(),
            agreeTerms: _agreeTerms,
            agreePrivacy: _agreePrivacy,
          );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '요청에 실패했습니다: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Copy per active field ───────────────────────────────────
  (String, String) get _prompt => switch (_active) {
        _Field.email => ('이메일을\n입력해 주세요.', '로그인도 가입도, 이메일 하나로 시작해요.'),
        _Field.nickname => ('어떻게\n불러드릴까요?', '앱에서 보여질 닉네임이에요.'),
        _Field.password => _mode == _Mode.login
            ? ('비밀번호를\n입력해 주세요.', '마지막 단계예요.')
            : ('비밀번호를\n만들어 주세요.', '대소문자·숫자·특수문자를 섞어 주세요.'),
        _Field.passwordConfirm => ('비밀번호를\n한 번 더 입력해 주세요.', '확인을 위해 똑같이 입력해 주세요.'),
        _Field.agreements => ('약관에\n동의해 주세요.', '동의하면 바로 가입돼요.'),
      };

  String get _ctaLabel => switch (_active) {
        _Field.email => '다음',
        _Field.nickname => '다음',
        _Field.password => _mode == _Mode.login ? '로그인' : '다음',
        _Field.passwordConfirm => '다음',
        _Field.agreements => '가입 완료',
      };

  String _fieldLabel(_Field f) => switch (f) {
        _Field.email => '이메일',
        _Field.nickname => '닉네임',
        _Field.password => '비밀번호',
        _Field.passwordConfirm => '비밀번호 확인',
        _Field.agreements => '약관 동의',
      };

  String _fieldValue(_Field f) => switch (f) {
        _Field.email => _emailCtrl.text.trim(),
        _Field.nickname => _nicknameCtrl.text.trim(),
        _Field.password => '•' * _passwordCtrl.text.length,
        _Field.passwordConfirm => '•' * _passwordConfirmCtrl.text.length,
        _Field.agreements => '모든 약관에 동의함',
      };

  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _prompt;
    return Scaffold(
      backgroundColor: TjColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scrollable question area — title, active field, recap stack.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const TjLogo(size: 36),
                        if (_mode != _Mode.unknown) _modeBadge(),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(title, style: TjType.display),
                    const SizedBox(height: 8),
                    Text(subtitle, style: TjType.body.copyWith(color: TjColors.ink2)),
                    const SizedBox(height: 28),
                    // Active input — always on top, where the cursor lives.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      // A plain fade+slide (no SizeTransition/ClipRect) so the
                      // floating label, which paints across the field's top
                      // edge, never gets clipped.
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_active),
                        child: _activeField(),
                      ),
                    ),
                    _errorText(),
                    // Answered fields stack below, newest first.
                    if (_done.isNotEmpty) const SizedBox(height: 16),
                    ..._done.reversed.map(_recapChip),
                  ],
                ),
              ),
            ),
            // CTA pinned above the keyboard.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                onPressed: _busy ? null : _next,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: TjColors.onInk),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_ctaLabel),
                          if (_active != _Field.agreements) ...[
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.arrowRight, size: 18, color: TjColors.onInk),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeBadge() {
    final isLogin = _mode == _Mode.login;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLogin ? TjColors.incomeSoft : TjColors.stampSoft,
        borderRadius: BorderRadius.circular(TjRadii.full),
      ),
      child: Text(
        isLogin ? '로그인' : '회원가입',
        style: TjType.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: isLogin ? TjColors.income : TjColors.stamp,
        ),
      ),
    );
  }

  // The single active input for the current step.
  Widget _activeField() {
    switch (_active) {
      case _Field.email:
        return TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearError(),
          onSubmitted: (_) => _next(),
          decoration: const InputDecoration(
            labelText: '이메일',
            hintText: 'example@email.com',
            prefixIcon: Icon(LucideIcons.mail),
          ),
        );
      case _Field.nickname:
        return TextField(
          controller: _nicknameCtrl,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearError(),
          onSubmitted: (_) => _next(),
          decoration: const InputDecoration(
            labelText: '닉네임',
            hintText: '뭐라고 부를까요?',
            prefixIcon: Icon(LucideIcons.user),
          ),
        );
      case _Field.password:
        final isLogin = _mode == _Mode.login;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              autofocus: true,
              textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
              // Signup needs a rebuild on every keystroke to refresh the checklist.
              onChanged: (_) => isLogin ? _clearError() : setState(() => _error = null),
              onSubmitted: (_) => _next(),
              decoration: InputDecoration(
                labelText: '비밀번호',
                hintText: isLogin ? '••••••••' : '8자 이상',
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (!isLogin) ...[
              const SizedBox(height: 14),
              _pwStrengthBar(),
            ],
          ],
        );
      case _Field.passwordConfirm:
        return TextField(
          controller: _passwordConfirmCtrl,
          obscureText: _obscureConfirm,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) => _clearError(),
          onSubmitted: (_) => _next(),
          decoration: InputDecoration(
            labelText: '비밀번호 확인',
            hintText: '한 번 더 입력',
            prefixIcon: const Icon(LucideIcons.lockKeyhole),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        );
      case _Field.agreements:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _agreeAllTile(),
            const Divider(height: 8),
            CheckboxListTile(
              value: _agreeTerms,
              onChanged: (v) => setState(() {
                _agreeTerms = v ?? false;
                _clearError();
              }),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('(필수) 서비스 이용약관에 동의합니다',
                  style: TjType.body.copyWith(fontSize: 14)),
            ),
            CheckboxListTile(
              value: _agreePrivacy,
              onChanged: (v) => setState(() {
                _agreePrivacy = v ?? false;
                _clearError();
              }),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('(필수) 개인정보 수집·이용에 동의합니다',
                  style: TjType.body.copyWith(fontSize: 14)),
            ),
          ],
        );
    }
  }

  Widget _agreeAllTile() {
    final all = _agreeTerms && _agreePrivacy;
    return InkWell(
      onTap: () => setState(() {
        final next = !all;
        _agreeTerms = next;
        _agreePrivacy = next;
        _clearError();
      }),
      borderRadius: BorderRadius.circular(TjRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: all ? TjColors.stampSoft : TjColors.card,
          borderRadius: BorderRadius.circular(TjRadii.md),
          border: Border.all(color: all ? TjColors.stamp : TjColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              all ? LucideIcons.circleCheck : LucideIcons.circle,
              size: 22,
              color: all ? TjColors.stamp : TjColors.ink4,
            ),
            const SizedBox(width: 12),
            Text('약관 전체 동의',
                style: TjType.title.copyWith(
                    color: all ? TjColors.stamp : TjColors.ink)),
          ],
        ),
      ),
    );
  }

  // Horizontal password-strength graph: a row of segments that fills from the
  // left as conditions are met, colored by strength, with the remaining rules
  // spelled out below.
  Widget _pwStrengthBar() {
    final rules = <(String, bool)>[
      ('8자 이상', _pwLen),
      ('대문자', _pwUpper),
      ('소문자', _pwLower),
      ('숫자', _pwDigit),
      ('특수문자', _pwSpecial),
    ];
    final met = rules.where((r) => r.$2).length;
    final allMet = met == rules.length;
    final empty = _passwordCtrl.text.isEmpty;
    final unmet = rules.where((r) => !r.$2).map((r) => r.$1).toList();

    final fillColor = allMet
        ? TjColors.income
        : met >= 3
            ? TjColors.amber
            : TjColors.expense;
    final label = allMet
        ? '강함'
        : met >= 3
            ? '보통'
            : '약함';
    final labelColor = empty ? TjColors.ink3 : fillColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < rules.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < met ? fillColor : TjColors.paperDeep,
                    borderRadius: BorderRadius.circular(TjRadii.full),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (!empty) ...[
              Text('비밀번호 강도 ',
                  style: TjType.caption.copyWith(fontWeight: FontWeight.w600)),
              Text(label,
                  style: TjType.caption
                      .copyWith(fontWeight: FontWeight.w700, color: labelColor)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                allMet
                    ? '안전한 비밀번호예요'
                    : '필요: ${unmet.join(' · ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: empty ? TextAlign.start : TextAlign.end,
                style: TjType.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: allMet ? TjColors.income : TjColors.ink3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // A compact, tappable recap of an already-answered field.
  Widget _recapChip(_Field f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _busy ? null : () => _edit(f),
        borderRadius: BorderRadius.circular(TjRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: TjColors.card,
            borderRadius: BorderRadius.circular(TjRadii.md),
            border: Border.all(color: TjColors.divider),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.check, size: 16, color: TjColors.income),
              const SizedBox(width: 10),
              Text('${_fieldLabel(f)}  ',
                  style: TjType.caption.copyWith(fontWeight: FontWeight.w600)),
              Expanded(
                child: Text(
                  _fieldValue(f),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TjType.body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Text('변경',
                  style: TjType.caption
                      .copyWith(color: TjColors.stamp, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorText() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              const Icon(LucideIcons.circleAlert, size: 16, color: TjColors.expense),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error!,
                    style: TjType.caption.copyWith(color: TjColors.expense)),
              ),
            ],
          ),
        );
}
