import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SheCommandApp());
}

// Data Models
class EmergencyContact {
  final String id;
  String name;
  String phoneNumber;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class EmergencyContactsProvider extends ChangeNotifier {
  final List<EmergencyContact> _contacts = <EmergencyContact>[
    EmergencyContact(id: '1', name: 'Mom', phoneNumber: '123-456-7890'),
    EmergencyContact(id: '2', name: 'Brother', phoneNumber: '098-765-4321'),
  ];

  List<EmergencyContact> get contacts => List<EmergencyContact>.unmodifiable(_contacts);

  void addContact(EmergencyContact contact) {
    _contacts.add(contact);
    notifyListeners();
  }

  void updateContact(EmergencyContact updatedContact) {
    final int index = _contacts.indexWhere((EmergencyContact contact) => contact.id == updatedContact.id);
    if (index != -1) {
      _contacts[index] = updatedContact;
      notifyListeners();
    }
  }

  void removeContact(String id) {
    _contacts.removeWhere((EmergencyContact contact) => contact.id == id);
    notifyListeners();
  }
}

class AudioRecording {
  final String id;
  final String name;
  final Duration duration;
  final DateTime timestamp;

  AudioRecording({
    required this.id,
    required this.name,
    required this.duration,
    required this.timestamp,
  });
}

class AudioRecordingProvider extends ChangeNotifier {
  final List<AudioRecording> _recordings = <AudioRecording>[];
  bool _isRecording = false;
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;
  Duration _currentRecordingDuration = Duration.zero;

  List<AudioRecording> get recordings => List<AudioRecording>.unmodifiable(_recordings);
  bool get isRecording => _isRecording;
  Duration get currentRecordingDuration => _currentRecordingDuration;

  void startRecording() {
    if (_isRecording) {
      return; // Already recording
    }
    _isRecording = true;
    _recordingStartTime = DateTime.now();
    _currentRecordingDuration = Duration.zero;

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_recordingStartTime != null) {
        _currentRecordingDuration = DateTime.now().difference(_recordingStartTime!);
        if (_currentRecordingDuration.inSeconds >= 15) {
          // Simulate stopping after max 15 seconds
          stopRecording();
        }
      }
      notifyListeners(); // Notify to update any UI displaying current duration
    });

    notifyListeners();
  }

  void stopRecording() {
    if (!_isRecording) {
      return; // Not recording
    }
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final DateTime endTime = DateTime.now();
    final Duration actualDuration = endTime.difference(_recordingStartTime!);
    _recordingStartTime = null;
    _isRecording = false;
    _currentRecordingDuration = Duration.zero;

    _recordings.add(
      AudioRecording(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Recording #${_recordings.length + 1}',
        duration: actualDuration,
        timestamp: endTime,
      ),
    );
    notifyListeners();
  }

  void removeRecording(String id) {
    _recordings.removeWhere((AudioRecording r) => r.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}

enum AppScreen { home, settings, emergencyContacts, savedAudio }

class AppNavigationProvider extends ChangeNotifier {
  AppScreen _currentPage = AppScreen.home;

  AppScreen get currentPage => _currentPage;

  void goTo(AppScreen screen) {
    if (_currentPage != screen) {
      _currentPage = screen;
      notifyListeners();
    }
  }

  void goBack() {
    if (_currentPage == AppScreen.emergencyContacts || _currentPage == AppScreen.savedAudio) {
      _currentPage = AppScreen.settings;
    } else if (_currentPage == AppScreen.settings) {
      _currentPage = AppScreen.home;
    }
    notifyListeners();
  }
}

class SheCommandApp extends StatelessWidget {
  const SheCommandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHE Command',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5A0CA4)),
      ),
      home: const PhoneMockScreen(),
    );
  }
}

class PhoneMockScreen extends StatelessWidget {
  const PhoneMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161022),
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            width: 360,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF5A0CA4), // purple
                  Color(0xFF3C0C7A),
                ],
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: MultiProvider(
              providers: <ChangeNotifierProvider<ChangeNotifier>>[
                ChangeNotifierProvider<AppNavigationProvider>(
                  create: (BuildContext context) => AppNavigationProvider(),
                ),
                ChangeNotifierProvider<EmergencyContactsProvider>(
                  create: (BuildContext context) => EmergencyContactsProvider(),
                ),
                ChangeNotifierProvider<AudioRecordingProvider>(
                  create: (BuildContext context) => AudioRecordingProvider(),
                ),
              ],
              builder: (BuildContext context, Widget? child) => const _AppRouter(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final AppScreen currentPage = context.watch<AppNavigationProvider>().currentPage;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: <Widget>[
            if (currentPage == AppScreen.home) const _TopBar(title: 'SHE COMMAND') else Container(),
            if (currentPage == AppScreen.settings)
              _CustomAppBar(
                title: 'SETTINGS',
                onBack: () => context.read<AppNavigationProvider>().goBack(),
              ),
            if (currentPage == AppScreen.emergencyContacts)
              _CustomAppBar(
                title: 'EMERGENCY CONTACTS',
                onBack: () => context.read<AppNavigationProvider>().goBack(),
              ),
            if (currentPage == AppScreen.savedAudio)
              _CustomAppBar(
                title: 'SAVED AUDIO',
                onBack: () => context.read<AppNavigationProvider>().goBack(),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (BuildContext context) {
                  switch (currentPage) {
                    case AppScreen.home:
                      return const _HomeScreenContent();
                    case AppScreen.settings:
                      return const _SettingsScreen();
                    case AppScreen.emergencyContacts:
                      return const _EmergencyContactsScreen();
                    case AppScreen.savedAudio:
                      return const _SavedAudioScreen();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            if (currentPage != AppScreen.emergencyContacts && currentPage != AppScreen.savedAudio)
              const _BottomBar(),
          ],
        ),
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _CustomAppBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            fontSize: 16,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            fontSize: 16,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final AudioRecordingProvider audioProvider = context.watch<AudioRecordingProvider>();

    return Column(
      children: <Widget>[
        const _SosButton(),
        const SizedBox(height: 24),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: FeatureCircle(
                      icon: Icons.place_outlined,
                      title: 'NOTIFY\nCONTACTS',
                      onTap: () {
                        final EmergencyContactsProvider contactsProvider =
                            context.read<EmergencyContactsProvider>();
                        final List<EmergencyContact> contacts = contactsProvider.contacts;

                        if (contacts.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No emergency contacts to notify.')),
                          );
                        } else {
                          for (final EmergencyContact contact in contacts) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Message: "Help, I am in trouble!" sent to ${contact.name} (${contact.phoneNumber})'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FeatureCircle(
                      icon: Icons.mic_none_rounded,
                      title: 'VOICE\nSOS',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('VOICE SOS triggered')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FeatureCircle(
                      icon: Icons.warning_amber_rounded,
                      title: 'UNSAFE\nZONES',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UNSAFE ZONES tapped')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FeatureCircle(
                      icon: audioProvider.isRecording
                          ? Icons.fiber_manual_record_rounded
                          : Icons.graphic_eq_rounded,
                      title: audioProvider.isRecording
                          ? 'RECORDING\n${audioProvider.currentRecordingDuration.inSeconds}s'
                          : 'AUTO-AUDIO\nRECORDING',
                      color: audioProvider.isRecording ? Colors.red : null,
                      onTap: () {
                        if (audioProvider.isRecording) {
                          audioProvider.stopRecording();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audio recording stopped and saved.')),
                          );
                        } else {
                          audioProvider.startRecording();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audio recording started.')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS Triggered')),
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: const BoxDecoration(
          color: Color(0xFFD0021B), // red
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(Icons.notifications_active_rounded, color: Colors.white, size: 40),
            SizedBox(height: 6),
            Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    final AppNavigationProvider navigation = context.read<AppNavigationProvider>();
    final AppScreen currentPage = context.watch<AppNavigationProvider>().currentPage;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          GestureDetector(
            onTap: () => navigation.goTo(AppScreen.home),
            child: Icon(
              Icons.home_outlined,
              color: currentPage == AppScreen.home ? Colors.white : Colors.white70,
              size: 28,
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile page (not implemented)')),
              );
            },
            child: const Icon(Icons.person_outline, color: Colors.white70, size: 28),
          ),
          GestureDetector(
            onTap: () => navigation.goTo(AppScreen.settings),
            child: Icon(
              Icons.settings_outlined,
              color: currentPage == AppScreen.settings ? Colors.white : Colors.white70,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCircle extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const FeatureCircle({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color ?? const Color.fromRGBO(255, 255, 255, 0.9), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SettingsTile(
          icon: Icons.group_outlined,
          title: 'Emergency Contacts',
          onTap: () => context.read<AppNavigationProvider>().goTo(AppScreen.emergencyContacts),
        ),
        _SettingsTile(
          icon: Icons.mic_rounded,
          title: 'Saved Audio',
          onTap: () => context.read<AppNavigationProvider>().goTo(AppScreen.savedAudio),
        ),
        _SettingsTile(
          icon: Icons.location_on_outlined,
          title: 'Location Settings',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location Settings tapped')),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notification Preferences',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification Preferences tapped')),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.security_outlined,
          title: 'Privacy & Security',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy & Security tapped')),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyContactsScreen extends StatelessWidget {
  const _EmergencyContactsScreen();

  Future<void> _showContactForm(BuildContext context, EmergencyContact? contact) async {
    final TextEditingController nameController = TextEditingController(text: contact?.name);
    final TextEditingController phoneController = TextEditingController(text: contact?.phoneNumber);

    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3C0C7A),
          title: Text(
            contact == null ? 'Add Contact' : 'Edit Contact',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  final EmergencyContactsProvider contactsProvider =
                      context.read<EmergencyContactsProvider>();
                  if (contact == null) {
                    contactsProvider.addContact(
                      EmergencyContact(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        phoneNumber: phoneController.text,
                      ),
                    );
                  } else {
                    contactsProvider.updateContact(
                      contact.copyWith(
                        name: nameController.text,
                        phoneNumber: phoneController.text,
                      ),
                    );
                  }
                  Navigator.of(dialogContext).pop(true);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Both fields are required.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A0CA4)),
              child: Text(contact == null ? 'Add' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<EmergencyContact> contacts = context.watch<EmergencyContactsProvider>().contacts;

    return Stack(
      children: <Widget>[
        if (contacts.isEmpty)
          const Center(
            child: Text(
              'No emergency contacts added yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          )
        else
          ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (BuildContext context, int index) {
              final EmergencyContact contact = contacts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    contact.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    contact.phoneNumber,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                        onPressed: () => _showContactForm(context, contact),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () async {
                          final bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF3C0C7A),
                                title: const Text('Delete Contact', style: TextStyle(color: Colors.white)),
                                content: Text('Are you sure you want to delete ${contact.name}?',
                                    style: const TextStyle(color: Colors.white70)),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmDelete ?? false) {
                            context.read<EmergencyContactsProvider>().removeContact(contact.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${contact.name} deleted')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              onPressed: () => _showContactForm(context, null),
              backgroundColor: const Color(0xFF5A0CA4),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedAudioScreen extends StatelessWidget {
  const _SavedAudioScreen();

  @override
  Widget build(BuildContext context) {
    final List<AudioRecording> recordings = context.watch<AudioRecordingProvider>().recordings;

    if (recordings.isEmpty) {
      return const Center(
        child: Text(
          'No audio recordings saved yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: recordings.length,
      itemBuilder: (BuildContext context, int index) {
        final AudioRecording recording = recordings[index];
        final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
        final String formattedTimestamp = formatter.format(recording.timestamp);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              recording.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${recording.duration.inSeconds} seconds - $formattedTimestamp',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.greenAccent),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playing "${recording.name}"... (simulated)')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () async {
                    final bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF3C0C7A),
                          title: const Text('Delete Recording', style: TextStyle(color: Colors.white)),
                          content: Text('Are you sure you want to delete "${recording.name}"?',
                              style: const TextStyle(color: Colors.white70)),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirmDelete ?? false) {
                      context.read<AudioRecordingProvider>().removeRecording(recording.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${recording.name}" deleted')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}