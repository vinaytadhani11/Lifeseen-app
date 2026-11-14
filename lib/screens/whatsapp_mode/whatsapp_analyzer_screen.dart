import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/widgets/block_back_navigation.dart';
import 'package:tableflow_plus/widgets/lifeseen_logo.dart';
import 'package:tableflow_plus/widgets/whatsapp_qr_code_dialog.dart';

class WhatsAppAnalyzerScreen extends StatefulWidget {
  const WhatsAppAnalyzerScreen({super.key});

  static const Duration holdDuration = Duration(seconds: 20);

  static const analyzerLogEntries = [
    _LogEntry('Recovering secret messages...', timestamp: '09:12:01'),
    _LogEntry('Performing data validation...', timestamp: '09:12:03'),
    _LogEntry('Performing data validation...', timestamp: '09:12:05'),
    _LogEntry('Creating full text index...', timestamp: '09:12:07'),
    _LogEntry('Indexing media files...', timestamp: '09:12:09'),
    _LogEntry('Establishing SQLite connection...', timestamp: '09:12:11'),
    _LogEntry('Decoding message encryption.', timestamp: '09:12:13'),
    _LogEntry(
      'Warn: Missing media files, skipping.',
      timestamp: '09:12:15',
      isWarning: true,
    ),
    _LogEntry('High-resolution files.', timestamp: '09:12:17'),
    _LogEntry('Processing high-resolution files...', timestamp: '09:12:19'),
    _LogEntry('Performing data validation...', timestamp: '09:12:03'),
    _LogEntry('Generating encryption keys...', timestamp: '09:12:23'),
    _LogEntry('Establishing secure connection...', timestamp: '09:12:25'),
    _LogEntry('Verifying session...', timestamp: '09:12:27'),
    _LogEntry('Connection completed...', timestamp: '09:12:29'),
    _LogEntry(
      'Analysis completed. You are being redirected...',
      timestamp: '09:12:31',
    ),
  ];

  @override
  State<WhatsAppAnalyzerScreen> createState() => _WhatsAppAnalyzerScreenState();
}

class _WhatsAppAnalyzerScreenState extends State<WhatsAppAnalyzerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: WhatsAppAnalyzerScreen.holdDuration,
    )..forward();

    _holdTimer = Timer(WhatsAppAnalyzerScreen.holdDuration, () {
      if (!mounted) return;
      WhatsAppQRCodeDialog.show(context);
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int _lerpInt(int start, int end, double t) {
    return (start + (end - start) * t).round();
  }

  double _lerpDouble(double start, double end, double t) {
    return start + (end - start) * t;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.splashBackground,
      ),
      child: BlockBackNavigation(
        child: Scaffold(
          backgroundColor: AppColors.splashBackground,
          body: SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _controller.value;
                final percent = (progress * 100).round().clamp(1, 100);
                final remainingSeconds = ((1 - progress) * 20).ceil().clamp(
                  0,
                  20,
                );
                final dataSpeed = _lerpDouble(0.5, 0.9, progress);
                final messages = _lerpInt(57, 512, progress);
                final media = _lerpInt(11, 101, progress);
                final calls = _lerpInt(2, 22, progress);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      // ElevatedButton(onPressed: () {
                      //   WhatsAppQRCodeDialog.show(context);
                      // }, child: const Text('Reset'),),
                      const Center(child: LifeSeenLogo(fontSize: 26, dark: true)),
                      const SizedBox(height: 20),
                      _AnalysisCard(
                        progress: progress,
                        percent: percent,
                        messages: messages,
                        media: media,
                        calls: calls,
                      ),
                      const SizedBox(height: 14),
                      const _TerminalCard(),
                      const SizedBox(height: 14),
                      _BottomStatusBar(
                        estimatedSeconds: remainingSeconds,
                        dataSpeed: dataSpeed,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LogEntry {
  const _LogEntry(
    this.message, {
    required this.timestamp,
    this.isWarning = false,
  });

  final String message;
  final String timestamp;
  final bool isWarning;
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.progress,
    required this.percent,
    required this.messages,
    required this.media,
    required this.calls,
  });

  final double progress;
  final int percent;
  final int messages;
  final int media;
  final int calls;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.secureCardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.secureCardBorder),
      ),
      child: Column(
        children: [
          Text(
            'Analyzing WhatsApp Messages',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.whatsAppGreen,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.progressTrack),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: AppColors.whatsAppGreen),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '% $percent',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.whatsAppGreen,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.chat_bubble_rounded,
                      value: '$messages',
                      label: 'MESSAGES',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.photo_library_rounded,
                      value: '$media',
                      label: 'MEDIA',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.phone_in_talk_rounded,
                      value: '$calls',
                      label: 'CALL',
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: IgnorePointer(
                  child: ClipRect(
                    child: Lottie.asset(
                      'assets/json/line.json',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      repeat: true,
                      animate: true,
                      frameRate: FrameRate.max,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.logoAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.whatsAppGreen, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.logoWhiteText,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitleText,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalCard extends StatefulWidget {
  const _TerminalCard();

  static const Duration _charInterval = Duration(milliseconds: 32);
  static const Duration _linePause = Duration(milliseconds: 280);

  @override
  State<_TerminalCard> createState() => _TerminalCardState();
}

class _TerminalCardState extends State<_TerminalCard> {
  final ScrollController _scrollController = ScrollController();
  final List<_LogEntry> _logs = WhatsAppAnalyzerScreen.analyzerLogEntries;

  Timer? _typingTimer;
  Timer? _cursorTimer;
  int _completedLineCount = 0;
  int _activeLineIndex = 0;
  int _typedCharCount = 0;
  bool _showCursor = true;
  bool _typingFinished = false;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (!mounted || _typingFinished) return;
      setState(() => _showCursor = !_showCursor);
    });
    _startTypingLine();
  }

  void _startTypingLine() {
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(_TerminalCard._charInterval, (_) {
      if (!mounted) return;

      final line = _logs[_activeLineIndex];
      if (_typedCharCount < line.message.length) {
        setState(() => _typedCharCount++);
        _scrollToLatest();
        return;
      }

      _typingTimer?.cancel();
      _completedLineCount = _activeLineIndex + 1;

      if (_completedLineCount >= _logs.length) {
        setState(() => _typingFinished = true);
        return;
      }

      Future<void>.delayed(_TerminalCard._linePause, () {
        if (!mounted) return;
        setState(() {
          _activeLineIndex = _completedLineCount;
          _typedCharCount = 0;
        });
        _startTypingLine();
      });
    });
  }

  int get _visibleLineCount {
    if (_typingFinished) return _logs.length;
    return _completedLineCount + 1;
  }

  String _displayedMessage(int index) {
    final entry = _logs[index];
    if (index < _completedLineCount) return entry.message;
    if (index == _activeLineIndex) {
      return entry.message.substring(0, _typedCharCount);
    }
    return '';
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secureCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.secureCardBorder),
              ),
            ),
            child: Row(
              children: [
                const _WindowDot(color: Color(0xFFFF5F57)),
                const SizedBox(width: 6),
                const _WindowDot(color: Color(0xFFFEBC2E)),
                const SizedBox(width: 6),
                const _WindowDot(color: Color(0xFF28C840)),
                const Spacer(),
                Text(
                  'whatsapp-analyzer',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtitleText,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _typingFinished
                        ? AppColors.subtitleText
                        : AppColors.whatsAppGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _visibleLineCount,
                  itemBuilder: (context, index) {
                    final entry = _logs[index];
                    final isActive =
                        index == _activeLineIndex && !_typingFinished;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TerminalLogLine(
                        entry: entry,
                        message: _displayedMessage(index),
                        showCursor: isActive && _showCursor,
                        isActive: isActive,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalLogLine extends StatelessWidget {
  const _TerminalLogLine({
    required this.entry,
    required this.message,
    required this.showCursor,
    required this.isActive,
  });

  final _LogEntry entry;
  final String message;
  final bool showCursor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final messageColor = entry.isWarning
        ? AppColors.warningOrange
        : AppColors.logoWhiteText;

    return RichText(
      text: TextSpan(
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        children: [
          TextSpan(
            text: '>',
            style: TextStyle(
              color: entry.isWarning
                  ? AppColors.warningOrange
                  : AppColors.whatsAppGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: '[${entry.timestamp}] ',
            style: const TextStyle(color: AppColors.subtitleText),
          ),
          TextSpan(
            text: message,
            style: TextStyle(
              color: messageColor,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (showCursor)
            TextSpan(
              text: '▍',
              style: TextStyle(
                color: AppColors.whatsAppGreen.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _WindowDot extends StatelessWidget {
  const _WindowDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BottomStatusBar extends StatelessWidget {
  const _BottomStatusBar({
    required this.estimatedSeconds,
    required this.dataSpeed,
  });

  final int estimatedSeconds;
  final double dataSpeed;

  @override
  Widget build(BuildContext context) {
    final minutes = (estimatedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (estimatedSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.secureCardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: AppColors.logoWhiteText,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Estimated: $minutes:$seconds',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.logoWhiteText,
            ),
          ),
          const Spacer(),
          Text(
            'Data: ${dataSpeed.toStringAsFixed(1)}MB/s',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.logoWhiteText,
            ),
          ),
        ],
      ),
    );
  }
}
