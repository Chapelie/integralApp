// lib/widgets/inactivity_wrapper.dart
// Wrapper pour détecter l'inactivité et afficher le PIN si nécessaire

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/inactivity_monitor.dart';
import '../core/pin_service.dart';
import '../features/auth/pin_screen.dart';

class InactivityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const InactivityWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends ConsumerState<InactivityWrapper> with WidgetsBindingObserver {
  final InactivityMonitor _monitor = InactivityMonitor();
  final PinService _pinService = PinService();
  bool _showPinScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startMonitoring();
    _monitor.addListener(_onInactivityDetected);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitor.removeListener(_onInactivityDetected);
    _monitor.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // L'app revient au premier plan
        // Vérifier si le PIN est requis
        _checkIfPinRequired();
        _monitor.setActive(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _monitor.setActive(false);
        break;
    }
  }

  void _startMonitoring() {
    _monitor.start();
  }

  void _onInactivityDetected() async {
    print('[InactivityWrapper] Inactivity detected');
    
    // Vérifier si le PIN est activé
    final isPinEnabled = await _pinService.isPinEnabled();
    if (!isPinEnabled) {
      print('[InactivityWrapper] PIN not enabled, not showing PIN screen');
      return;
    }

    print('[InactivityWrapper] Showing PIN screen due to inactivity');
    if (mounted) {
      setState(() {
        _showPinScreen = true;
      });
    }
  }

  Future<void> _checkIfPinRequired() async {
    // Vérifier si le PIN est activé
    final isPinEnabled = await _pinService.isPinEnabled();
    if (!isPinEnabled) {
      return;
    }

    // Si l'utilisateur est inactif depuis trop longtemps, demander le PIN
    final inactivityDuration = _monitor.getInactivityDuration();
    if (inactivityDuration.inSeconds >= 60) {
      print('[InactivityWrapper] User was inactive for ${inactivityDuration.inSeconds}s, showing PIN');
      if (mounted) {
        setState(() {
          _showPinScreen = true;
        });
      }
    }
  }

  void _onPinSuccess() {
    setState(() {
      _showPinScreen = false;
    });
    _monitor.recordActivity();
  }

  void _onPinCancel() {
    setState(() {
      _showPinScreen = false;
    });
    _monitor.recordActivity();
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les interactions utilisateur pour réinitialiser le timer
    return Listener(
      onPointerDown: (_) => _monitor.recordActivity(),
      onPointerUp: (_) => _monitor.recordActivity(),
      onPointerMove: (_) => _monitor.recordActivity(),
      child: GestureDetector(
        onTap: () => _monitor.recordActivity(),
        onPanDown: (_) => _monitor.recordActivity(),
        behavior: HitTestBehavior.translucent,
        child: _showPinScreen
            ? PinScreen(
                onSuccess: _onPinSuccess,
                onCancel: _onPinCancel,
                title: 'Code PIN requis',
                subtitle: 'L\'application a été inactive pendant un moment. Entrez votre code PIN pour continuer.',
              )
            : widget.child,
      ),
    );
  }
}









