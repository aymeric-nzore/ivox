import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/chat/services/chat_services.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceCallPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final bool isIncoming;
  final String? callId;

  const VoiceCallPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
    this.isIncoming = false,
    this.callId,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  final ChatServices _chatService = ChatServices();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription<Map<String, dynamic>>? _callSubscription;

  late final String _callId;
  bool _offerSent = false;
  bool _isConnecting = true;
  bool _isConnected = false;
  bool _isMuted = false;
  bool _callEnded = false;
  String _status = 'Connexion...';

  @override
  void initState() {
    super.initState();
    _callId = widget.callId ?? DateTime.now().microsecondsSinceEpoch.toString();
    _bootstrapCall();
  }

  Future<void> _bootstrapCall() async {
    await _chatService.ensureSocketReady();

    _callSubscription = _chatService.callEvents.listen(_handleCallEvent);

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (!mounted) return;
      setState(() {
        _status = 'Microphone refuse';
        _isConnecting = false;
      });
      return;
    }

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      });

      for (final track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) {
          return;
        }
        _chatService.sendWebRtcIce(
          toUserId: widget.receiverId,
          callId: _callId,
          candidate: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      };

      _peerConnection!.onConnectionState = (state) {
        if (!mounted) return;
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            setState(() {
              _isConnecting = false;
              _isConnected = true;
              _status = 'Appel en cours';
            });
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            if (!_callEnded) {
              _endCall(notifyPeer: true, popPage: true);
            }
            break;
          default:
            break;
        }
      };

      if (widget.isIncoming) {
        await _chatService.sendCallAccept(
          toUserId: widget.receiverId,
          callId: _callId,
        );
        if (mounted) {
          setState(() {
            _status = 'Connexion a l\'appel...';
          });
        }
      } else {
        final me = AuthService().getUser();
        final callerName =
            (me?.displayName?.trim().isNotEmpty ?? false)
                ? me!.displayName!.trim()
                : (me?.email?.trim().isNotEmpty ?? false)
                ? me!.email!.trim()
                : 'Utilisateur';

        await _chatService.sendCallInvite(
          toUserId: widget.receiverId,
          callId: _callId,
          callerName: callerName,
        );
        if (mounted) {
          setState(() {
            _status = 'Sonnerie...';
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'Impossible de demarrer l\'appel';
        _isConnecting = false;
      });
    }
  }

  Future<void> _createAndSendOffer() async {
    if (_peerConnection == null || _offerSent) {
      return;
    }

    final offer = await _peerConnection!.createOffer({'offerToReceiveAudio': 1});
    await _peerConnection!.setLocalDescription(offer);
    _offerSent = true;

    await _chatService.sendWebRtcOffer(
      toUserId: widget.receiverId,
      callId: _callId,
      sdp: {'type': offer.type, 'sdp': offer.sdp},
    );

    if (!mounted) return;
    setState(() {
      _isConnecting = true;
      _status = 'Connexion...';
    });
  }

  Future<void> _handleIncomingOffer(Map<String, dynamic> payload) async {
    if (_peerConnection == null) return;

    final sdp = payload['sdp'];
    if (sdp is! Map) return;
    final map = sdp.map((key, value) => MapEntry(key.toString(), value));

    final remoteDesc = RTCSessionDescription(
      (map['sdp'] ?? '').toString(),
      (map['type'] ?? 'offer').toString(),
    );

    await _peerConnection!.setRemoteDescription(remoteDesc);
    final answer = await _peerConnection!.createAnswer({'offerToReceiveAudio': 1});
    await _peerConnection!.setLocalDescription(answer);

    await _chatService.sendWebRtcAnswer(
      toUserId: widget.receiverId,
      callId: _callId,
      sdp: {'type': answer.type, 'sdp': answer.sdp},
    );

    if (!mounted) return;
    setState(() {
      _status = 'Connexion...';
      _isConnecting = true;
    });
  }

  Future<void> _handleIncomingAnswer(Map<String, dynamic> payload) async {
    if (_peerConnection == null) return;

    final sdp = payload['sdp'];
    if (sdp is! Map) return;
    final map = sdp.map((key, value) => MapEntry(key.toString(), value));

    final remoteDesc = RTCSessionDescription(
      (map['sdp'] ?? '').toString(),
      (map['type'] ?? 'answer').toString(),
    );

    await _peerConnection!.setRemoteDescription(remoteDesc);
    if (!mounted) return;
    setState(() {
      _status = 'Connexion...';
      _isConnecting = true;
    });
  }

  Future<void> _handleIncomingIce(Map<String, dynamic> payload) async {
    if (_peerConnection == null) return;

    final candidate = payload['candidate'];
    if (candidate is! Map) return;
    final map = candidate.map((key, value) => MapEntry(key.toString(), value));

    final rtcCandidate = RTCIceCandidate(
      (map['candidate'] ?? '').toString(),
      map['sdpMid']?.toString(),
      map['sdpMLineIndex'] is int
          ? map['sdpMLineIndex'] as int
          : int.tryParse((map['sdpMLineIndex'] ?? '').toString()),
    );

    await _peerConnection!.addCandidate(rtcCandidate);
  }

  void _handleCallEvent(Map<String, dynamic> payload) {
    final incomingCallId = (payload['callId'] ?? '').toString();
    if (incomingCallId != _callId) return;

    final fromUserId = (payload['fromUserId'] ?? '').toString();
    if (fromUserId != widget.receiverId) return;

    final event = (payload['event'] ?? '').toString();

    switch (event) {
      case 'call_accept':
        if (!widget.isIncoming) {
          _createAndSendOffer();
        }
        break;
      case 'call_reject':
        _endCall(notifyPeer: false, popPage: true, endText: 'Appel refuse');
        break;
      case 'call_end':
        _endCall(notifyPeer: false, popPage: true, endText: 'Appel termine');
        break;
      case 'webrtc_offer':
        if (widget.isIncoming) {
          _handleIncomingOffer(payload);
        }
        break;
      case 'webrtc_answer':
        if (!widget.isIncoming) {
          _handleIncomingAnswer(payload);
        }
        break;
      case 'webrtc_ice':
        _handleIncomingIce(payload);
        break;
      default:
        break;
    }
  }

  Future<void> _toggleMute() async {
    final stream = _localStream;
    if (stream == null) return;

    final tracks = stream.getAudioTracks();
    if (tracks.isEmpty) return;

    final newMuted = !_isMuted;
    for (final track in tracks) {
      track.enabled = !newMuted;
    }

    if (!mounted) return;
    setState(() {
      _isMuted = newMuted;
    });
  }

  Future<void> _endCall({
    required bool notifyPeer,
    required bool popPage,
    String endText = 'Appel termine',
  }) async {
    if (_callEnded) return;
    _callEnded = true;

    if (notifyPeer) {
      await _chatService.sendCallEnd(
        toUserId: widget.receiverId,
        callId: _callId,
      );
    }

    await _callSubscription?.cancel();

    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }

    await _peerConnection?.close();

    if (mounted) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _status = endText;
      });

      if (popPage) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _endCall(notifyPeer: true, popPage: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appel vocal'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 44,
                backgroundImage:
                    widget.receiverPhotoUrl != null &&
                            widget.receiverPhotoUrl!.isNotEmpty
                        ? NetworkImage(widget.receiverPhotoUrl!)
                        : null,
                child:
                    widget.receiverPhotoUrl == null ||
                            widget.receiverPhotoUrl!.isEmpty
                        ? const Icon(Icons.person, size: 34)
                        : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.receiverName,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _status,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_isConnecting) ...[
                const SizedBox(height: 18),
                const CircularProgressIndicator(strokeWidth: 2.2),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _isConnected || _isConnecting ? _toggleMute : null,
                    icon: Icon(
                      _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    ),
                    label: Text(_isMuted ? 'Activer micro' : 'Couper micro'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  _endCall(notifyPeer: true, popPage: true);
                },
                icon: const Icon(Icons.call_end_rounded),
                label: const Text('Raccrocher'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
