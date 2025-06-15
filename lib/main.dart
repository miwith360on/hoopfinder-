import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bqpsowmknofckevcrnaq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxcHNvd21rbm9mY2tldmNybmFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzOTIzMjcsImV4cCI6MjA2NDk2ODMyN30.25RXvW4u2wwoYmiI7xDG82NacOfDufC0In9APDUTbag',
  );
  runApp(const HoopFinderApp());
}

class HoopFinderApp extends StatelessWidget {
  const HoopFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoop Finder',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const CourtMapPage(),
    );
  }
}

class Court {
  final String id; // <-- Add this line
  final String name;
  final LatLng location;
  final bool isIndoor;
  final String description;
  final bool isBusy;
  final bool hasLights;
  final bool hasRestrooms;
  final bool hasWaterFountain;

  Court({
    required this.id, // <-- Add this line
    required this.name,
    required this.location,
    required this.isIndoor,
    required this.description,
    required this.isBusy,
    required this.hasLights,
    required this.hasRestrooms,
    required this.hasWaterFountain,
  });

  Map<String, dynamic> toJson() => {
    'id': id, // <-- Add this line
    'name': name,
    'lat': location.latitude,
    'lng': location.longitude,
    'isIndoor': isIndoor,
    'description': description,
    'isBusy': isBusy,
    'hasLights': hasLights,
    'hasRestrooms': hasRestrooms,
    'hasWaterFountain': hasWaterFountain,
  };

  factory Court.fromJson(Map<String, dynamic> json) => Court(
    id: json['id'], // <-- Add this line
    name: json['name'],
    location: LatLng(
      json['lat'] is double ? json['lat'] : double.parse(json['lat'].toString()),
      json['lng'] is double ? json['lng'] : double.parse(json['lng'].toString()),
    ),
    isIndoor: json['isIndoor'] is bool ? json['isIndoor'] : json['isIndoor'].toString() == 'true',
    description: json['description'] ?? '',
    isBusy: json['isBusy'] is bool ? json['isBusy'] : json['isBusy'].toString() == 'true',
    hasLights: json['hasLights'] is bool ? json['hasLights'] : json['hasLights'].toString() == 'true',
    hasRestrooms: json['hasRestrooms'] is bool ? json['hasRestrooms'] : json['hasRestrooms'].toString() == 'true',
    hasWaterFountain: json['hasWaterFountain'] is bool ? json['hasWaterFountain'] : json['hasWaterFountain'].toString() == 'true',
  );
}

class CourtMapPage extends StatefulWidget {
  const CourtMapPage({super.key});

  @override
  State<CourtMapPage> createState() => _CourtMapPageState();
}

class _CourtMapPageState extends State<CourtMapPage> {
  LatLng? _pendingPin;
  bool forceMobile = false; // store this in your state
  String searchQuery = '';

  void _showAddCourtDialog(LatLng location) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String courtType = 'Indoor';
    bool hasLights = false;
    bool hasRestrooms = false;
    bool hasWaterFountain = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Court'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Court Name'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  DropdownButtonFormField<String>(
                    value: courtType,
                    items: ['Indoor', 'Outdoor'].map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        courtType = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  CheckboxListTile(
                    title: const Text('Lights'),
                    value: hasLights,
                    onChanged: (val) => setState(() => hasLights = val!),
                  ),
                  CheckboxListTile(
                    title: const Text('Restrooms'),
                    value: hasRestrooms,
                    onChanged: (val) => setState(() => hasRestrooms = val!),
                  ),
                  CheckboxListTile(
                    title: const Text('Water Fountain'),
                    value: hasWaterFountain,
                    onChanged: (val) => setState(() => hasWaterFountain = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a court name.'),
                        ),
                      );
                      return;
                    }
                    final desc = descriptionController.text.trim(); // Get the description text
                    await Supabase.instance.client.from('courts').insert({
                      'name': name,
                      'lat': location.latitude,
                      'lng': location.longitude,
                      'isIndoor': courtType == 'Indoor',
                      'description': desc,
                      'isBusy': false,
                      'hasLights': hasLights,
                      'hasRestrooms': hasRestrooms,
                      'hasWaterFountain': hasWaterFountain,
                    });
                    // print(response); // <-- Remove or comment out this line for production
                    if (!mounted) return;
                    setState(() {
                      _pendingPin = null;
                    });
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  late void Function(TapPosition, LatLng) _mapOptionsOnTap;

  @override
  void initState() {
    super.initState();
    _mapOptionsOnTap = _defaultOnTap;
  }

  void _defaultOnTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _pendingPin = latlng;
    });
    _showAddCourtDialog(latlng);
  }

  void _showMoveCourtDialog(Court court) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Move Court'),
          content: const Text('Tap the new location on the map.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    setState(() {
      _pendingPin = null;
    });

    void onTapMove(TapPosition tapPosition, LatLng latlng) async {
      // Update the court in Supabase
      await Supabase.instance.client
          .from('courts')
          .update({
            'lat': latlng.latitude,
            'lng': latlng.longitude,
          })
          .eq('name', court.name)
          .eq('lat', court.location.latitude)
          .eq('lng', court.location.longitude)
          .select();
      if (!mounted) return;
      setState(() {
        _pendingPin = null;
      });
      _mapOptionsOnTap = _defaultOnTap;
    }

    _mapOptionsOnTap = onTapMove;
  }

  Stream<List<Court>> getCourtsStream() {
    return Supabase.instance.client
        .from('courts')
        .stream(primaryKey: ['id'])
        .map((data) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => Court.fromJson(json))
              .toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = forceMobile || MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoop Finder'),
        actions: [
          IconButton(
            icon: Icon(isMobile ? Icons.desktop_windows : Icons.phone_android),
            onPressed: () {
              setState(() {
                forceMobile = !forceMobile;
              });
            },
            tooltip: isMobile ? 'Switch to Desktop View' : 'Switch to Mobile View',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by city or court name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: isMobile ? buildMobileLayout() : buildDesktopLayout(),
    );
  }

  // When building your court list:
  List<Court> filterCourts(List<Court> courts) {
    if (searchQuery.isEmpty) return courts;
    return courts.where((court) =>
      court.name.toLowerCase().contains(searchQuery)
    ).toList();
  }

  Widget buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Courts'),
      ),
      body: StreamBuilder<List<Court>>(
        stream: getCourtsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final courts = snapshot.data!;
          final filteredCourts = filterCourts(courts);

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(42.5247, -83.1336),
              initialZoom: 12.0,
              onTap: _mapOptionsOnTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  ...filteredCourts.map((court) => Marker(
                    point: court.location,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () async {
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(court.name),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(court.isIndoor ? 'Indoor' : 'Outdoor'),
                                const SizedBox(height: 8),
                                Text(court.description.isNotEmpty ? court.description : 'No description'),
                                Row(
                                  children: [
                                    if (court.hasLights) Icon(Icons.lightbulb, color: Colors.yellow),
                                    if (court.hasRestrooms) Icon(Icons.wc, color: Colors.blue),
                                    if (court.hasWaterFountain) Icon(Icons.local_drink, color: Colors.teal),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  await Supabase.instance.client
                                      .from('courts')
                                      .delete()
                                      .eq('name', court.name)
                                      .eq('lat', court.location.latitude)
                                      .eq('lng', court.location.longitude);
                                  if (!mounted) return;
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                },
                                child: const Text('Remove'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showMoveCourtDialog(court);
                                },
                                child: const Text('Move'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final url = 'https://www.google.com/maps/search/?api=1&query=${court.location.latitude},${court.location.longitude}';
                                  if (await canLaunch(url)) {
                                    await launch(url);
                                  }
                                },
                                child: const Text('Directions'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await Supabase.instance.client
                                      .from('courts')
                                      .update({'isBusy': !court.isBusy})
                                      .eq('name', court.name)
                                      .eq('lat', court.location.latitude)
                                      .eq('lng', court.location.longitude);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                },
                                child: Text(court.isBusy ? 'Mark as Free' : 'Mark as Busy'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await Supabase.instance.client.from('court_checkins').insert({
                                    'court_id': court.id,
                                  });
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                },
                                child: const Text('Check In'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Remove the latest check-in for this court (for demo, removes any)
                                  await Supabase.instance.client
                                    .from('court_checkins')
                                    .delete()
                                    .eq('court_id', court.id);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                },
                                child: const Text('Check Out'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Icon(
                        Icons.location_pin,
                        color: court.isBusy
                            ? Colors.red // Busy = red
                            : (court.isIndoor ? Colors.green : Colors.orange), // Free = green/orange
                        size: 40,
                      ),
                    ),
                  )),
                  if (_pendingPin != null)
                    Marker(
                      point: _pendingPin!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.add_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildDesktopLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Courts'),
      ),
      body: StreamBuilder<List<Court>>(
        stream: getCourtsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final courts = snapshot.data!;
          final filteredCourts = filterCourts(courts);

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(42.5247, -83.1336),
              initialZoom: 12.0,
              onTap: _mapOptionsOnTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  ...filteredCourts.map((court) => Marker(
                    point: court.location,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () async {
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(court.name),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(court.isIndoor ? 'Indoor' : 'Outdoor'),
                                const SizedBox(height: 8),
                                Text(court.description.isNotEmpty ? court.description : 'No description'),
                                Row(
                                  children: [
                                    if (court.hasLights) Icon(Icons.lightbulb, color: Colors.yellow),
                                    if (court.hasRestrooms) Icon(Icons.wc, color: Colors.blue),
                                    if (court.hasWaterFountain) Icon(Icons.local_drink, color: Colors.teal),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  await Supabase.instance.client
                                      .from('courts')
                                      .delete()
                                      .eq('name', court.name)
                                      .eq('lat', court.location.latitude)
                                      .eq('lng', court.location.longitude);
                                  if (!mounted) return;
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                },
                                child: const Text('Remove'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showMoveCourtDialog(court);
                                },
                                child: const Text('Move'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final url = 'https://www.google.com/maps/search/?api=1&query=${court.location.latitude},${court.location.longitude}';
                                  if (await canLaunch(url)) {
                                    await launch(url);
                                  }
                                },
                                child: const Text('Directions'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await Supabase.instance.client
                                      .from('courts')
                                      .update({'isBusy': !court.isBusy})
                                      .eq('name', court.name)
                                      .eq('lat', court.location.latitude)
                                      .eq('lng', court.location.longitude);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                },
                                child: Text(court.isBusy ? 'Mark as Free' : 'Mark as Busy'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await Supabase.instance.client.from('court_checkins').insert({
                                    'court_id': court.id,
                                  });
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                },
                                child: const Text('Check In'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Remove the latest check-in for this court (for demo, removes any)
                                  await Supabase.instance.client
                                    .from('court_checkins')
                                    .delete()
                                    .eq('court_id', court.id);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                },
                                child: const Text('Check Out'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Icon(
                        Icons.location_pin,
                        color: court.isBusy
                            ? Colors.red // Busy = red
                            : (court.isIndoor ? Colors.green : Colors.orange), // Free = green/orange
                        size: 40,
                      ),
                    ),
                  )),
                  if (_pendingPin != null)
                    Marker(
                      point: _pendingPin!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.add_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}