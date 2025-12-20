import 'package:flutter/material.dart';

/// Demo navigation screen showing UI without Supabase connection.
class DemoNavigationScreen extends StatefulWidget {
  const DemoNavigationScreen({super.key});

  @override
  State<DemoNavigationScreen> createState() => _DemoNavigationScreenState();
}

class _DemoNavigationScreenState extends State<DemoNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DemoDashboard(),
    _DemoExpenseList(),
    _DemoScanner(),
    _DemoGroup(),
    _DemoProfile(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Spese',
    ),
    NavigationDestination(
      icon: Icon(Icons.camera_alt_outlined),
      selectedIcon: Icon(Icons.camera_alt),
      label: 'Scansiona',
    ),
    NavigationDestination(
      icon: Icon(Icons.group_outlined),
      selectedIcon: Icon(Icons.group),
      label: 'Gruppo',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profilo',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: _destinations,
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo: Aggiungi spesa')),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _DemoDashboard extends StatelessWidget {
  const _DemoDashboard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector mock
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _PeriodChip(label: 'Settimana', selected: false),
                    _PeriodChip(label: 'Mese', selected: true),
                    _PeriodChip(label: 'Anno', selected: false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Total summary
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Totale Spese',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '€ 1.234,56',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '23 transazioni',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category breakdown
            Text('Spese per Categoria', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _CategoryRow(emoji: '🛒', name: 'Spesa', amount: '€ 456,78', percent: 37),
                    _CategoryRow(emoji: '🏠', name: 'Casa', amount: '€ 320,00', percent: 26),
                    _CategoryRow(emoji: '🚗', name: 'Trasporti', amount: '€ 180,50', percent: 15),
                    _CategoryRow(emoji: '⚡', name: 'Bollette', amount: '€ 145,00', percent: 12),
                    _CategoryRow(emoji: '🍽️', name: 'Ristoranti', amount: '€ 132,28', percent: 10),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Members breakdown
            Text('Spese per Membro', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _MemberRow(name: 'Marco', amount: '€ 567,23', color: Colors.blue),
                    _MemberRow(name: 'Laura', amount: '€ 445,11', color: Colors.pink),
                    _MemberRow(name: 'Giovanni', amount: '€ 222,22', color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _PeriodChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String emoji;
  final String name;
  final String amount;
  final int percent;
  const _CategoryRow({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String name;
  final String amount;
  final Color color;
  const _MemberRow({required this.name, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(name[0], style: const TextStyle(color: Colors.white)),
      ),
      title: Text(name),
      trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _DemoExpenseList extends StatelessWidget {
  const _DemoExpenseList();

  @override
  Widget build(BuildContext context) {
    final expenses = [
      _ExpenseData('Supermercato Esselunga', '🛒', 78.45, DateTime.now()),
      _ExpenseData('Benzina', '🚗', 65.00, DateTime.now().subtract(const Duration(days: 1))),
      _ExpenseData('Bolletta Gas', '⚡', 89.50, DateTime.now().subtract(const Duration(days: 2))),
      _ExpenseData('Ristorante Da Mario', '🍽️', 45.00, DateTime.now().subtract(const Duration(days: 3))),
      _ExpenseData('Farmacia', '💊', 23.80, DateTime.now().subtract(const Duration(days: 4))),
      _ExpenseData('Cinema', '🎬', 32.00, DateTime.now().subtract(const Duration(days: 5))),
      _ExpenseData('Abbigliamento', '👕', 89.99, DateTime.now().subtract(const Duration(days: 6))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spese'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(expense.emoji, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(expense.description),
              subtitle: Text(_formatDate(expense.date)),
              trailing: Text(
                '€ ${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Demo: Dettaglio ${expense.description}')),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Oggi';
    if (diff == 1) return 'Ieri';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ExpenseData {
  final String description;
  final String emoji;
  final double amount;
  final DateTime date;
  _ExpenseData(this.description, this.emoji, this.amount, this.date);
}

class _DemoScanner extends StatelessWidget {
  const _DemoScanner();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scansiona Scontrino')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 100, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            const Text('Inquadra uno scontrino'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo: Scansione scontrino')),
                );
              },
              icon: const Icon(Icons.camera),
              label: const Text('Scatta Foto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoGroup extends StatelessWidget {
  const _DemoGroup();

  @override
  Widget build(BuildContext context) {
    final members = [
      ('Marco', 'marco@example.com', Colors.blue, true),
      ('Laura', 'laura@example.com', Colors.pink, false),
      ('Giovanni', 'giovanni@example.com', Colors.green, false),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Famiglia Rossi'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invite code card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Codice Invito'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'FAM-ABC123',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Codice copiato!')),
                            );
                          },
                        ),
                      ],
                    ),
                    const Text(
                      'Condividi questo codice per invitare membri',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Members list
            Text('Membri (${members.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...members.map((m) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: m.$3,
                  child: Text(m.$1[0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text(m.$1),
                subtitle: Text(m.$2),
                trailing: m.$4
                    ? Chip(
                        label: const Text('Admin'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      )
                    : null,
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _DemoProfile extends StatelessWidget {
  const _DemoProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text('Marco Rossi', style: Theme.of(context).textTheme.headlineSmall),
            const Text('marco.rossi@example.com'),
            const SizedBox(height: 32),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Modifica Profilo'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifiche'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Tema'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Esci', style: TextStyle(color: Colors.red)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo: Logout')),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'DEMO MODE',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            const Text(
              'UI Preview - Nessun database connesso',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
