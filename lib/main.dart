import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'dart:html' as html; 
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_fonts/google_fonts.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

// ================= CONFIGURATION =================
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyAq6yYNCYj1I5A2mSxPglv2i1qESY9WP64",
  authDomain: "meetingapp-9fb61.firebaseapp.com",
  projectId: "meetingapp-9fb61",
  storageBucket: "meetingapp-9fb61.firebasestorage.app",
  messagingSenderId: "993354913044",
  appId: "1:993354913044:web:6efa08b2ec05a93c609e01",
  measurementId: "G-W59NPMWGYP",
);

String getBackendUrl() {
  // ⚠ REPLACE WITH YOUR RENDER URL ⚠
  return "https://meeting-backend-npl2.onrender.com/translate";
}

final List<Map<String, String>> languages = [
  {"name": "English", "code": "en_US", "trans": "en"},
  {"name": "Hindi", "code": "hi_IN", "trans": "hi"},
  {"name": "Kannada", "code": "kn_IN", "trans": "kn"},
  {"name": "Telugu", "code": "te_IN", "trans": "te"},
  {"name": "Tamil", "code": "ta_IN", "trans": "ta"},
  {"name": "Malayalam", "code": "ml_IN", "trans": "ml"},
  {"name": "Marathi", "code": "mr_IN", "trans": "mr"},
  {"name": "French", "code": "fr_FR", "trans": "fr"},
  {"name": "Spanish", "code": "es_ES", "trans": "es"},
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  await FirebaseAuth.instance.signOut(); 
  runApp(const ConferenzaApp());
}

class ConferenzaApp extends StatelessWidget {
  const ConferenzaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conferenza Final', // Version Check
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

// =========================== AUTH WRAPPER ===========================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  static String? pendingRoomID;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('roomID')) {
        pendingRoomID = uri.queryParameters['roomID'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return HomePage(
            user: snapshot.data!,
            pendingRoomID: pendingRoomID,
          );
        }
        return const LoginPage();
      },
    );
  }
}

// =========================== HELPER WIDGETS ===========================
class ConferenzaLogo extends StatelessWidget {
  final double size;
  const ConferenzaLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/conferenza_logo.png',
      height: size, 
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.video_camera_front_outlined, 
            color: const Color(0xFF00E5FF), size: size);
      },
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = 20,
    this.borderRadius = 25,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AestheticTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  const AestheticTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> colors;
  const GradientButton({super.key, required this.text, required this.onPressed, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: colors[0].withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}

// =========================== LOGIN / REGISTER ===========================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      await cred.user!.updateDisplayName(_nameCtrl.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const AnimatedGradientBg(),
        Center(
          child: SizedBox(
            width: 400,
            child: GlassCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const ConferenzaLogo(size: 80),
                const SizedBox(height: 30),
                AestheticTextField(controller: _nameCtrl, label: "Full Name", icon: Icons.person),
                const SizedBox(height: 15),
                AestheticTextField(controller: _emailCtrl, label: "Email", icon: Icons.email),
                const SizedBox(height: 15),
                AestheticTextField(controller: _passCtrl, label: "Password", icon: Icons.lock, isPassword: true),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : GradientButton(text: "Sign Up", colors: const [Color(0xFF6C63FF), Color(0xFF3B3B98)], onPressed: _register),
                const SizedBox(height: 15),
                TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                    child: const Text("Already have an account? Login", style: TextStyle(color: Color(0xFF00E5FF))))
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const AnimatedGradientBg(),
        Center(
          child: SizedBox(
            width: 420,
            child: GlassCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ConferenzaLogo(size: 70), 
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Welcome to", style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.1)),
                        Text("Conferenza", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 26, fontWeight: FontWeight.bold, shadows: [Shadow(color: Color(0x6600E5FF), blurRadius: 15)])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                AestheticTextField(controller: _emailCtrl, label: "Email", icon: Icons.email),
                const SizedBox(height: 15),
                AestheticTextField(controller: _passCtrl, label: "Password", icon: Icons.lock, isPassword: true),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : GradientButton(text: "Login", colors: const [Color(0xFFFF4081), Color(0xFFC2185B)], onPressed: _login),
                const SizedBox(height: 15),
                TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                    child: const Text("Don't have an account? Register", style: TextStyle(color: Color(0xFFFF4081))))
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// =========================== HOME PAGE ===========================
class HomePage extends StatefulWidget {
  final User user;
  final String? pendingRoomID;
  const HomePage({super.key, required this.user, this.pendingRoomID});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final createController = TextEditingController();
  final joinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.pendingRoomID != null && widget.pendingRoomID!.isNotEmpty) {
      joinController.text = widget.pendingRoomID!;
    }
  }

  String _generateRandomCode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random rnd = Random();
    String code = String.fromCharCodes(Iterable.generate(3, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    String code2 = String.fromCharCodes(Iterable.generate(3, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return "$code-$code2";
  }

  void _createMeeting() {
    String roomCode = _generateRandomCode();
    _join(context, roomCode, true);
  }

  void _join(BuildContext context, String room, bool isCreator) {
    if (room.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WebRTCMeetingPage(
            roomId: room,
            user: widget.user,
            isCreator: isCreator,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: "Logout",
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(children: [
        const AnimatedGradientBg(),
        Center(
          child: SizedBox(
            width: 450,
            child: GlassCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const ConferenzaLogo(size: 55),
                const SizedBox(height: 15),
                Text("Hi, ${widget.user.displayName ?? 'User'}!",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 5),
                const Text("Ready for your next meeting?", style: TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 30),
                const Divider(color: Colors.white12),
                const SizedBox(height: 20),
                const Text("Instant Meeting", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                const SizedBox(height: 10),
                GradientButton(text: "NEW MEETING", colors: const [Color(0xFF00E5FF), Color(0xFF00B8D4)], onPressed: _createMeeting),
                const SizedBox(height: 25),
                const Text("Join with Code", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF4081))),
                const SizedBox(height: 10),
                AestheticTextField(controller: joinController, label: "Room Code (e.g. ABC-123)", icon: Icons.login),
                const SizedBox(height: 15),
                GradientButton(text: "JOIN MEETING", colors: const [Color(0xFFFF4081), Color(0xFFC2185B)], onPressed: () => _join(context, joinController.text, false)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// =========================== MEETING PAGE (FIXED) ===========================
class WebRTCMeetingPage extends StatefulWidget {
  final String roomId;
  final User user;
  final bool isCreator;
  const WebRTCMeetingPage({super.key, required this.roomId, required this.user, required this.isCreator});

  @override
  State<WebRTCMeetingPage> createState() => _WebRTCMeetingPageState();
}

class _WebRTCMeetingPageState extends State<WebRTCMeetingPage> {
  Timer? _subtitleTimer;
  final List<RTCVideoRenderer> _videoRenderers = [];
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final PageController _pageController = PageController();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  bool _remoteDescriptionSet = false;
  final List<RTCIceCandidate> _iceCandidatesQueue = [];

  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isScreenSharing = false;
  bool _isRecording = false;
  bool _showParticipants = false;
  bool _showChat = false;
  bool _showTranslation = false; 
  bool _showEmojiPicker = false;
  bool _inLobby = true;
  bool _isObserver = false;

  int _recordSeconds = 0;
  Timer? _recordTimer;

  late stt.SpeechToText _speech;
  String _originalText = "Listening...";
  String _translatedText = "Translation...";
  String _sourceLang = "en_US";
  String _targetLang = "hi";

  final TextEditingController _chatController = TextEditingController();
  StreamSubscription<QuerySnapshot>? _captionsSub;
  final Set<String> _handledCaptionIds = {};
  Map<String, Map<String, dynamic>> _participantsData = {};
  StreamSubscription<DocumentSnapshot>? _myLobbySub;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _showTranslation = false; // Off by default

    if (widget.isCreator) {
      setState(() {
        _inLobby = false;
        _isObserver = false;
      });
      _joinParticipantList('accepted');
      _initWebRTC();
    } else {
      _joinParticipantList('waiting');
      _listenToLobbyStatus();
    }

    _listenParticipants();
    _listenToCaptions();
  }

  Future<void> _checkObserverStatus() async {
    final snap = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('participants')
        .where('status', isEqualTo: 'accepted')
        .get();
        
    if (snap.docs.length > 2) { 
      setState(() => _isObserver = true);
    } else {
      setState(() => _isObserver = false);
      _initWebRTC(); 
    }
  }

  Future<void> _joinParticipantList(String status) async {
    final ref = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('participants').doc(widget.user.uid);
    await ref.set({
      'name': widget.user.displayName ?? "User",
      'uid': widget.user.uid,
      'mic': _isMicOn,
      'cam': _isCameraOn,
      'status': status,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenToLobbyStatus() {
    _myLobbySub = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('participants').doc(widget.user.uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'waiting';
        if (status == 'accepted' && _inLobby) {
          setState(() => _inLobby = false);
          _checkObserverStatus();
        }
      }
    });
  }

  Future<void> _admitUser(String uid) async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('participants').doc(uid).update({'status': 'accepted'});
  }

  void _listenParticipants() {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('participants').snapshots().listen((snapshot) {
      final map = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? 'User';
        map[name] = data;
      }
      if (mounted) setState(() => _participantsData = map);
    });
  }

  Future<void> _updateStatusInFirestore() async {
    if (_isObserver) return; 
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('participants').doc(widget.user.uid).update({'mic': _isMicOn, 'cam': _isCameraOn});
  }

  // --- AUDIO/VIDEO FIX: SIMPLIFIED CONSTRAINTS + UNIFIED PLAN ---
  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    _videoRenderers.add(_localRenderer);
    
    // 1. SIMPLIFIED AUDIO CONSTRAINTS (Better compatibility)
    final mediaConstraints = {
      'audio': true, // Basic True is often more reliable on mobile web
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480}
      }
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      // Force Speakerphone (Requires package import check, but this usually defaults well)
      // await Helper.setSpeakerphoneOn(true); 
      setState(() {});
    } catch (e) {
      print("Error getting user media: $e");
    }

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'turn:openrelay.metered.ca:80', 'username': 'openrelayproject', 'credential': 'openrelayproject'},
        {'urls': 'turn:openrelay.metered.ca:443', 'username': 'openrelayproject', 'credential': 'openrelayproject'},
        {'urls': 'turn:openrelay.metered.ca:443?transport=tcp', 'username': 'openrelayproject', 'credential': 'openrelayproject'}
      ],
      'sdpSemantics': 'unified-plan'
    });

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        var remoteStream = event.streams[0];
        bool alreadyExists = _videoRenderers.any((r) => r.srcObject?.id == remoteStream.id);
        if (!alreadyExists && event.track.kind == 'video') {
          var remoteRenderer = RTCVideoRenderer();
          remoteRenderer.initialize().then((_) {
            remoteRenderer.srcObject = remoteStream;
            setState(() => _videoRenderers.add(remoteRenderer));
          });
        }
      }
    };
    
    _peerConnection!.onIceCandidate = (candidate) {
      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection(widget.isCreator ? 'callerCandidates' : 'calleeCandidates').add(candidate.toMap());
    };

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => _peerConnection!.addTrack(track, _localStream!));
    }

    if (widget.isCreator) {
      _createRoom();
    } else {
      _joinRoom();
    }
  }

  Future<void> _createRoom() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).set({'offer': offer.toMap()}, SetOptions(merge: true));

    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots().listen((snapshot) async {
      var data = snapshot.data();
      if (data != null && data.containsKey('answer')) {
        var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        await _peerConnection!.setRemoteDescription(answer);
        setState(() => _remoteDescriptionSet = true);
        for (var candidate in _iceCandidatesQueue) {
          _peerConnection!.addCandidate(candidate);
        }
        _iceCandidatesQueue.clear();
      }
    });

    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
          if (_remoteDescriptionSet) {
            _peerConnection!.addCandidate(candidate);
          } else {
            _iceCandidatesQueue.add(candidate);
          }
        }
      }
    });
  }

  Future<void> _joinRoom() async {
    var snapshot = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
    if (snapshot.exists && snapshot.data()!.containsKey('offer')) {
      var data = snapshot.data()!;
      var offer = data['offer'];
      await _peerConnection!.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
      setState(() => _remoteDescriptionSet = true); 

      var answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({'answer': answer.toMap()});

      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('callerCandidates').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            var data = change.doc.data() as Map<String, dynamic>;
            var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
            if (_remoteDescriptionSet) {
              _peerConnection!.addCandidate(candidate);
            } else {
              _iceCandidatesQueue.add(candidate);
            }
          }
        }
      });
    }
  }

  // --- MIC FIX ---
  // Add this near your other state fields in _WebRTCMeetingPageState:
String _lastFinalText = "";

void _startListening() async {
  // Prevent duplicate initializations
  if (_speech.isListening) return;

  bool available = await _speech.initialize(
    onStatus: (status) {
      // When engine stops but mic+translation are still on, restart
      if ((status == 'done' || status == 'notListening') && _isMicOn && _showTranslation) {
        Future.delayed(const Duration(milliseconds: 300), _startListening);
      }
    },
    onError: (e) {
      if (_isMicOn && _showTranslation) {
        Future.delayed(const Duration(milliseconds: 800), _startListening);
      }
    },
  );

  if (!available) return;

  _speech.listen(
    localeId: _sourceLang,
    listenFor: const Duration(minutes: 5),
    pauseFor: const Duration(seconds: 3),          // shorter pause → faster finalResult
    partialResults: true,
    listenMode: stt.ListenMode.dictation,
    cancelOnError: false,
    onResult: (res) async {
      final text = res.recognizedWords.trim();
      if (text.isEmpty) return;

      // Update local log so user sees live text
      if (mounted) {
        setState(() {
          _originalText = text;
        });
      }
      // Only translate when result is final
  //if (res.finalResult) {
    await _runTranslation(text);
  //}

      // ONLY send when result is final (end of sentence / long pause)
      if (res.finalResult) {
        if (text == _lastFinalText) return; // avoid duplicates
        _lastFinalText = text;

        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('captions')
            .add({
          'sender': widget.user.displayName,
          'text': text,
          'lang': _sourceLang,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    },
  );
}


 void _listenToCaptions() {
  _captionsSub = FirebaseFirestore.instance
      .collection('rooms')
      .doc(widget.roomId)
      .collection('captions')
      .orderBy('timestamp')
      .snapshots()
      .listen((snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final doc = change.doc;
        if (_handledCaptionIds.contains(doc.id)) continue;
        _handledCaptionIds.add(doc.id);

        final data = doc.data() as Map<String, dynamic>;
        final text = data['text'] as String? ?? '';
        final senderName = data['sender'] as String? ?? 'Unknown';

        if (text.isEmpty || !_showTranslation) continue;

        setState(() => _originalText = "$senderName: $text");

        _runTranslation(text);   // important: send full sentence
      }
    }
  });
}


  // UPDATED: Simple 2-way translation appearing in the box
// UPDATED FUNCTION: Clears text automatically
  Future<void> _runTranslation(String text) async {
  try {
    final resp = await http.post(
      Uri.parse(getBackendUrl()),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "text": text,
        "target_lang": _targetLang,
        "source_lang": "auto",
      }),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);

      if (!mounted) return;

      // Stop old clear timer so new text is not removed too early
      _subtitleTimer?.cancel();

      setState(() {
        _translatedText = data["translated"] ?? "";
      });

      // How long subtitles stay visible
      _subtitleTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _translatedText = "";
          _originalText = "";
        });
      });
    }
  } catch (_) {
    // keep UI silent on errors to avoid flicker
  }
}

  void _toggleMic() {
    setState(() => _isMicOn = !_isMicOn);
    _localStream?.getAudioTracks()[0].enabled = _isMicOn;
    _updateStatusInFirestore();
    if (_isMicOn && _showTranslation) {
      _startListening();
    } else {
      _speech.stop();
    } 
  }

  void _toggleTranslation() {
    setState(() => _showTranslation = !_showTranslation);
    if (_showTranslation && _isMicOn) {
      _startListening();
    } else {
      _speech.stop();
    }
  }

  void _toggleCamera() {
    setState(() => _isCameraOn = !_isCameraOn);
    _localStream?.getVideoTracks()[0].enabled = _isCameraOn;
    _updateStatusInFirestore();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _recordTimer?.cancel();
      setState(() { _isRecording = false; _recordSeconds = 0; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recording Saved (Dummy)!"), backgroundColor: Colors.green));
    } else {
      setState(() => _isRecording = true);
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _recordSeconds++));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recording Started"), backgroundColor: Colors.red));
    }
  }

  void _toggleScreenShare() async {
    if (!_isScreenSharing) {
      try {
        final stream = await navigator.mediaDevices.getDisplayMedia({'video': true});
        _localRenderer.srcObject = stream;
        var senders = await _peerConnection!.getSenders();
        var sender = senders.firstWhere((s) => s.track?.kind == 'video');
        sender.replaceTrack(stream.getVideoTracks()[0]);
        setState(() => _isScreenSharing = true);
      } catch (e) { print(e); }
    } else {
      _localRenderer.srcObject = _localStream;
      var senders = await _peerConnection!.getSenders();
      var sender = senders.firstWhere((s) => s.track?.kind == 'video');
      sender.replaceTrack(_localStream!.getVideoTracks()[0]);
      setState(() => _isScreenSharing = false);
    }
  }

  void _copyLink() {
    String baseUrl = html.window.location.href.split('?')[0];
    if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    Clipboard.setData(ClipboardData(text: "$baseUrl/?roomID=${widget.roomId}"));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link Copied!")));
  }

  void _sendMessage() {
    if (_chatController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('chat').add({
        'sender': widget.user.displayName,
        'text': _chatController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'reaction': null,
      });
      _chatController.clear();
    }
  }

  void _addReaction(String docId, String emoji) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('chat').doc(docId).update({'reaction': emoji});
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    for (var r in _videoRenderers) {
      r.dispose();
    }
    _peerConnection?.close();
    _speech.stop();
    _recordTimer?.cancel();
    _captionsSub?.cancel();
    _myLobbySub?.cancel();
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('participants').doc(widget.user.uid).delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_inLobby) {
      return Scaffold(
        body: Stack(children: [
          const AnimatedGradientBg(),
          Center(
            child: GlassCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.hourglass_empty, size: 50, color: Colors.amber),
                const SizedBox(height: 20),
                Text("Waiting for Host...", style: GoogleFonts.poppins(fontSize: 20, color: Colors.white)),
                const SizedBox(height: 10),
                Text("Room Code: ${widget.roomId}", style: const TextStyle(color: Colors.white54)),
              ]),
            ),
          )
        ]),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedGradientBg(),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 160),
            child: _isObserver 
              ? Center(
                  child: GlassCard(
                    padding: 30,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.visibility, size: 60, color: Colors.white54),
                      const SizedBox(height: 20),
                      const Text("Spectator Mode", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 10),
                      const Text("You are viewing the live translation and chat.", style: TextStyle(color: Colors.white70)),
                      const Divider(color: Colors.white24, height: 40),
                      Text(_originalText, style: const TextStyle(color: Colors.white38, fontSize: 16)),
                      const SizedBox(height: 10),
                      Text(_translatedText, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ]),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: 1, 
                  itemBuilder: (context, pageIndex) {
                    return Center(
                      child: SizedBox(
                        width: 900,
                        child: GridView.builder(
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, childAspectRatio: 16 / 9, crossAxisSpacing: 20, mainAxisSpacing: 20,
                          ),
                          itemCount: _videoRenderers.length,
                          itemBuilder: (ctx, idx) => _buildVideoTile(_videoRenderers[idx], idx),
                        ),
                      ),
                    );
                  },
                ),
          ),

          Positioned(
            top: 20, left: 20, right: 20,
            child: GlassCard(
              padding: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const ConferenzaLogo(size: 20),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)),
                      child: SelectableText("Code: ${widget.roomId}", style: const TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 10),
                    IconButton(icon: const Icon(Icons.copy, color: Color(0xFF00E5FF)), onPressed: _copyLink),
                  ]),
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [const Icon(Icons.fiber_manual_record, color: Colors.white, size: 16), const SizedBox(width: 5), Text(_formatTime(_recordSeconds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
                  IconButton(icon: const Icon(Icons.people, color: Colors.white), onPressed: () => setState(() => _showParticipants = !_showParticipants))
                ],
              ),
            ),
          ),

          if (_showParticipants)
            Positioned(
              top: 90, right: 20, width: 300,
              child: GlassCard(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('participants').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var docs = snapshot.data!.docs;
                    var admitted = docs.where((d) => d['status'] == 'accepted').toList();
                    var waiting = docs.where((d) => d['status'] == 'waiting').toList();
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      if (widget.isCreator && waiting.isNotEmpty) ...[
                        Text("Waiting Room (${waiting.length})", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        const Divider(color: Colors.amber),
                        ...waiting.map((doc) => ListTile(
                          title: Text(doc['name'], style: const TextStyle(color: Colors.white)),
                          trailing: IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _admitUser(doc.id)),
                        )),
                        const SizedBox(height: 10),
                      ],
                      Text("Participants (${admitted.length})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white24),
                      SizedBox(height: 200, child: ListView(children: admitted.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage("https://api.dicebear.com/9.x/avataaars/png?seed=${data['name']}")),
                          title: Text(data['name'], style: const TextStyle(color: Colors.white)),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(data['mic'] ? Icons.mic : Icons.mic_off, color: data['mic'] ? Colors.green : Colors.red, size: 16),
                            const SizedBox(width: 5),
                            Icon(data['cam'] ? Icons.videocam : Icons.videocam_off, color: data['cam'] ? Colors.green : Colors.red, size: 16),
                          ]),
                        );
                      }).toList()))
                    ]);
                  },
                ),
              ),
            ),

          if (_showChat)
            Positioned(
              bottom: 140, right: 20, width: 350, height: 450,
              child: GlassCard(
                padding: 0,
                child: Column(children: [
                  Container(padding: const EdgeInsets.all(15), color: Colors.white.withOpacity(0.1), child: const Row(children: [Text("Group Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
                  Expanded(child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('chat').orderBy('timestamp').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        var msgs = snapshot.data!.docs;
                        return ListView.builder(
                          padding: const EdgeInsets.all(10), itemCount: msgs.length,
                          itemBuilder: (ctx, i) {
                            var data = msgs[i].data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(data['sender'] ?? 'Anon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF00E5FF))),
                              subtitle: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(data['text'], style: const TextStyle(color: Colors.white))),
                              trailing: data['reaction'] != null ? Text(data['reaction'], style: const TextStyle(fontSize: 20)) : PopupMenuButton<String>(icon: const Icon(Icons.add_reaction, size: 18, color: Colors.white38), onSelected: (e) => _addReaction(msgs[i].id, e), itemBuilder: (ctx) => ["👍", "❤", "😂", "😮"].map((e) => PopupMenuItem(value: e, child: Text(e))).toList()),
                            );
                          },
                        );
                      })),
                  Padding(padding: const EdgeInsets.all(8.0), child: Row(children: [IconButton(icon: const Icon(Icons.emoji_emotions, color: Colors.white70), onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker)), Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Type...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none), onSubmitted: (_) => _sendMessage())), IconButton(icon: const Icon(Icons.send, color: Color(0xFF00E5FF)), onPressed: _sendMessage)])),
                  if (_showEmojiPicker) SizedBox(height: 200, child: EmojiPicker(onEmojiSelected: (c, e) { _chatController.text += e.emoji; }))
                ]),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_showTranslation && !_isObserver)
                  GlassCard(
                    padding: 15,
                    child: SizedBox(
                      width: 600,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          DropdownButton<String>(value: _sourceLang, dropdownColor: Colors.grey[900], style: const TextStyle(color: Colors.white), items: languages.map((l) => DropdownMenuItem(value: l['code'], child: Text(l['name']!))).toList(), onChanged: (v) => setState(() => _sourceLang = v!)),
                          const Icon(Icons.arrow_forward, color: Colors.white54),
                          DropdownButton<String>(value: _targetLang, dropdownColor: Colors.grey[900], style: const TextStyle(color: Colors.white), items: languages.map((l) => DropdownMenuItem(value: l['trans'], child: Text(l['name']!))).toList(), onChanged: (v) => setState(() => _targetLang = v!)),
                        ]),
                        Text("Log: $_originalText", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        Text(_translatedText, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 16, fontWeight: FontWeight.bold))
                      ]),
                    ),
                  ),
                const SizedBox(height: 10),
                
                GlassCard(
                  backgroundColor: Colors.black.withOpacity(0.7),
                  borderColor: const Color(0xFF00E5FF),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (!_isObserver) ...[
                      _controlBtn(icon: _isMicOn ? Icons.mic : Icons.mic_off, isActive: _isMicOn, onTap: _toggleMic, activeColor: Colors.white),
                      _controlBtn(icon: _isCameraOn ? Icons.videocam : Icons.videocam_off, isActive: _isCameraOn, onTap: _toggleCamera, activeColor: Colors.white),
                      _controlBtn(icon: Icons.closed_caption, isActive: _showTranslation, onTap: _toggleTranslation, activeColor: const Color(0xFF00E5FF)),
                      _controlBtn(icon: Icons.screen_share, isActive: _isScreenSharing, onTap: _toggleScreenShare, activeColor: Colors.blue),
                    ],
                    _controlBtn(icon: Icons.chat_bubble, isActive: _showChat, onTap: () => setState(() => _showChat = !_showChat), activeColor: Colors.purpleAccent),
                    if (!_isObserver) _controlBtn(icon: Icons.fiber_manual_record, isActive: _isRecording, onTap: _toggleRecording, activeColor: Colors.red),
                    const SizedBox(width: 15),
                    FloatingActionButton(heroTag: "end", backgroundColor: Colors.red, child: const Icon(Icons.call_end, color: Colors.white), onPressed: () { _localRenderer.dispose(); Navigator.pop(context); }),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTile(RTCVideoRenderer renderer, int index) {
    bool isLocal = (index == 0);
    String userName = widget.user.displayName ?? "User";
    String displayName = isLocal ? "$userName (You)" : "Participant $index";
    String pureName = isLocal ? userName : "Participant $index";

    if (!isLocal) {
      List<String> remoteNames = _participantsData.keys.where((k) => k != userName).toList();
      if (remoteNames.isNotEmpty) {
        int remoteIndex = index - 1; 
        if (remoteIndex < remoteNames.length) {
          pureName = remoteNames[remoteIndex];
          displayName = pureName;
        }
      }
    }

    bool camOn = true;
    if (isLocal) {
      camOn = _isCameraOn;
    } else {
      if (_participantsData.containsKey(pureName)) {
        camOn = _participantsData[pureName]!['cam'] as bool? ?? true;
      }
    }
    
    final bool hasVideoTrack = renderer.srcObject?.getVideoTracks().isNotEmpty == true &&
                               renderer.srcObject!.getVideoTracks()[0].enabled;
                                
    bool showAvatar = !camOn || !hasVideoTrack;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Colors.black54,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showAvatar)
              Center(child: CircleAvatar(radius: 60, backgroundColor: Colors.white10, backgroundImage: NetworkImage("https://api.dicebear.com/9.x/avataaars/png?seed=$pureName")))
            else
              RTCVideoView(renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: isLocal),
            Positioned(bottom: 10, left: 10, child: GlassCard(padding: 5, child: Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 12)))),
          ],
        ),
      ),
    );
  }

  Widget _controlBtn({required IconData icon, required VoidCallback onTap, bool isActive = false, Color activeColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)),
        child: IconButton(icon: Icon(icon, color: isActive ? activeColor : Colors.white70), onPressed: onTap, style: IconButton.styleFrom(backgroundColor: isActive ? activeColor.withOpacity(0.2) : Colors.transparent)),
      ),
    );
  }
}

class AnimatedGradientBg extends StatefulWidget {
  const AnimatedGradientBg({super.key});
  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) { return Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: const [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)], stops: [0, _controller.value, 1]))); });
  }
}