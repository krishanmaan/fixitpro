import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/providers/admin_provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTimeSlotsScreen extends StatefulWidget {
  static const String routeName = '/admin/manage-time-slots';

  const ManageTimeSlotsScreen({super.key});

  @override
  State<ManageTimeSlotsScreen> createState() => _ManageTimeSlotsScreenState();
}

class _ManageTimeSlotsScreenState extends State<ManageTimeSlotsScreen> {
  bool _isLoading = false;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<Map<String, dynamic>> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchTimeSlots();
  }

  Future<void> _fetchTimeSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Format date to YYYY-MM-DD for Firebase query
      final dateStr =
          '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}';

      // Import the cloud_firestore package at the top of the file
      final firestore = FirebaseFirestore.instance;
      final snapshot =
          await firestore
              .collection('timeSlots')
              .where('dateStr', isEqualTo: dateStr)
              .get();

      setState(() {
        _timeSlots =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

        // Sort by time
        _timeSlots.sort(
          (a, b) => (a['time'] as String).compareTo(b['time'] as String),
        );

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching time slots: $e');
      setState(() {
        _timeSlots = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Time Slots')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCalendar(),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Create time slots for specific dates. Users will only see and be able to book slots you have created. Booked slots will show in red.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _isLoading
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : _buildTimeSlotsSection(),
              // Add space at the bottom for the floating action button
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTimeSlotsDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Slots'),
        backgroundColor: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 30)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _fetchTimeSlots();
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppConstants.primaryColor.withAlpha(128), // 0.5 * 255 = 128
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppConstants.primaryColor,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    if (_timeSlots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Time Slots for ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'No time slots available for this date',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateTimeSlotsDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Time Slots'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Time Slots for ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusIndicator(
                    Colors.green.shade50,
                    Colors.green.shade800,
                    'Available',
                  ),
                  const SizedBox(width: 16),
                  _buildStatusIndicator(
                    Colors.red.shade50,
                    Colors.red.shade800,
                    'Booked',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_timeSlots.where((slot) => slot['status'] == 'SlotStatus.available').length} slots available',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Disable scrolling for the grid
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _timeSlots.length + 1,
          itemBuilder: (context, index) {
            if (index == _timeSlots.length) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.blue.shade300, width: 1),
                ),
                color: Colors.blue.shade50,
                child: InkWell(
                  onTap: () => _showAddSingleSlotDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.blue.shade800,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ADD SLOT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final slot = _timeSlots[index];
            final isBooked = slot['status'] == 'SlotStatus.booked';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isBooked ? Colors.red.shade300 : Colors.green.shade300,
                  width: 1,
                ),
              ),
              color: isBooked ? Colors.red.shade50 : Colors.green.shade50,
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slot['time'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isBooked
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isBooked
                                ? Icons.cancel_rounded
                                : Icons.check_circle_rounded,
                            size: 14,
                            color:
                                isBooked
                                    ? Colors.red.shade800
                                    : Colors.green.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBooked ? 'BOOKED' : 'AVAILABLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  isBooked
                                      ? Colors.red.shade800
                                      : Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Add delete button for available slots
                  if (!isBooked)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        onPressed:
                            () => _confirmDeleteSlot(slot['id'] as String),
                        tooltip: 'Delete slot',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    Color backgroundColor,
    Color textColor,
    String label,
  ) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: textColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showCreateTimeSlotsDialog(BuildContext context) {
    // Default time slots (9 AM to 8 PM, hourly)
    final List<String> defaultTimes = [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '1:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
      '6:00 PM',
      '7:00 PM',
      '8:00 PM',
    ];

    // Create a map of times with selected state
    Map<String, bool> selectedTimes = {};
    for (var time in defaultTimes) {
      selectedTimes[time] = true;
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Create Time Slots for ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                  style: const TextStyle(fontSize: 16),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Select available time slots:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: defaultTimes.length,
                          itemBuilder: (context, index) {
                            final time = defaultTimes[index];
                            return CheckboxListTile(
                              title: Text(time),
                              value: selectedTimes[time],
                              onChanged: (value) {
                                setState(() {
                                  selectedTimes[time] = value!;
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  for (var time in defaultTimes) {
                                    selectedTimes[time] = true;
                                  }
                                });
                              },
                              child: const Text('Select All'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  for (var time in defaultTimes) {
                                    selectedTimes[time] = false;
                                  }
                                });
                              },
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (selectedTimes.values.every(
                        (isSelected) => !isSelected,
                      )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select at least one time slot',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Get the list of selected times
                      final List<String> timesToCreate =
                          selectedTimes.entries
                              .where((entry) => entry.value)
                              .map((entry) => entry.key)
                              .toList();

                      Navigator.of(context).pop();
                      await _createTimeSlots(timesToCreate);
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _createTimeSlots(List<String> selectedTimes) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    final success = await adminProvider.createTimeSlotsForDate(
      _selectedDay,
      selectedTimes,
    );

    // Refresh the time slots after creation
    if (success) {
      await _fetchTimeSlots();
    } else {
      setState(() {
        _isLoading = false;
      });
    }

    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Time slots created successfully'
              : 'Failed to create time slots: ${adminProvider.error ?? "Unknown error"}',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _confirmDeleteSlot(String slotId) {
    final slotData = _timeSlots.firstWhere((slot) => slot['id'] == slotId);
    final String timeStr = slotData['time'] as String;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Time Slot'),
            content: Text(
              'Are you sure you want to delete the $timeStr time slot?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteTimeSlot(slotId, timeStr);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteTimeSlot(String slotId, String timeStr) async {
    setState(() {
      _isLoading = true;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    try {
      final success = await adminProvider.deleteTimeSlot(slotId);

      if (success) {
        // Remove from local list for immediate UI update
        setState(() {
          _timeSlots.removeWhere((slot) => slot['id'] == slotId);
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Time slot $timeStr deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                adminProvider.error ?? 'Failed to delete time slot',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddSingleSlotDialog(BuildContext context) {
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Add Time Slot for ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                  style: const TextStyle(fontSize: 16),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Select a time for the new slot:'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppConstants.primaryColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            setState(() {
                              selectedTime = pickedTime;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          selectedTime == null
                              ? 'Select Time'
                              : 'Selected: ${_formatTimeOfDay(selectedTime!)}',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed:
                        selectedTime == null
                            ? null
                            : () {
                              Navigator.of(context).pop();
                              _addSingleTimeSlot(
                                _formatTimeOfDay(selectedTime!),
                              );
                            },
                    child: const Text('Add Slot'),
                  ),
                ],
              );
            },
          ),
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:00 $period';
  }

  Future<void> _addSingleTimeSlot(String timeStr) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if this time already exists
      final existingSlot = _timeSlots.any((slot) => slot['time'] == timeStr);
      if (existingSlot) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('A time slot for $timeStr already exists'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Use the admin provider to create the single time slot
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final success = await adminProvider.createTimeSlotsForDate(_selectedDay, [
        timeStr,
      ]);

      // Refresh the time slots list
      if (success) {
        await _fetchTimeSlots();
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(adminProvider.error ?? 'Failed to add time slot'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time slot for $timeStr added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding time slot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
