// ============================================================
// FILE: customer_list_screen.dart
//
// PURPOSE:
// Displays the Customer Management screen of Sri Guru
// Enterprises.
//
// FUNCTIONALITY:
// - Displays all saved customers.
// - Provides a search field.
// - Searches customers by name or contact number.
// - Shows customer information in cards.
// - Provides an Add Customer button.
// - Provides Edit and Delete actions.
//
// IMPORTANT:
// This screen currently focuses on displaying and managing
// customers.
//
// The Add/Edit screens will be created in the next steps.
// ============================================================

import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import 'add_edit_customer_screen.dart';

// ============================================================
// CUSTOMER LIST SCREEN
//
// Main screen for Customer Management.
// ============================================================

class CustomerListScreen extends StatefulWidget {
  // ------------------------------------------------------------
  // CONSTRUCTOR
  // ------------------------------------------------------------

  const CustomerListScreen({
    super.key,
  });

  @override
  State<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

// ============================================================
// CUSTOMER LIST SCREEN STATE
// ============================================================

class _CustomerListScreenState
    extends State<CustomerListScreen> {
  // ------------------------------------------------------------
  // CUSTOMER REPOSITORY
  //
  // Handles all database operations related to customers.
  // ------------------------------------------------------------

  final CustomerRepository _repository =
  CustomerRepository();

  // ------------------------------------------------------------
  // SEARCH CONTROLLER
  //
  // Controls the customer search field.
  // ------------------------------------------------------------

  final TextEditingController _searchController =
  TextEditingController();

  // ------------------------------------------------------------
  // CUSTOMER LIST
  //
  // Stores the customers currently displayed on screen.
  // ------------------------------------------------------------

  List<Customer> _customers = [];

  // ------------------------------------------------------------
  // LOADING STATE
  //
  // Used while customers are being loaded from SQLite.
  // ------------------------------------------------------------

  bool _isLoading = true;

  // ============================================================
  // INIT STATE
  //
  // Called when the screen is first created.
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // LOAD CUSTOMERS
    // ----------------------------------------------------------

    _loadCustomers();
  }

  // ============================================================
  // DISPOSE
  //
  // Releases the search controller when the screen is removed.
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD CUSTOMERS
  //
  // Retrieves all customers from the repository.
  // ============================================================

  Future<void> _loadCustomers() async {
    // ----------------------------------------------------------
    // SHOW LOADING INDICATOR
    // ----------------------------------------------------------

    setState(() {
      _isLoading = true;
    });

    // ----------------------------------------------------------
    // GET CUSTOMERS FROM DATABASE
    // ----------------------------------------------------------

    final List<Customer> customers =
    await _repository.getCustomers();

    // ----------------------------------------------------------
    // CHECK WHETHER SCREEN IS STILL ACTIVE
    //
    // Prevents calling setState after the widget has been
    // removed from the widget tree.
    // ----------------------------------------------------------

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // UPDATE SCREEN
    // ----------------------------------------------------------

    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  // ============================================================
  // SEARCH CUSTOMERS
  //
  // Searches the database using the entered text.
  // ============================================================

  Future<void> _searchCustomers(String value) async {
    // ----------------------------------------------------------
    // SEARCH DATABASE
    // ----------------------------------------------------------

    final List<Customer> customers =
    await _repository.searchCustomers(value);

    // ----------------------------------------------------------
    // CHECK WHETHER SCREEN IS STILL ACTIVE
    // ----------------------------------------------------------

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // UPDATE CUSTOMER LIST
    // ----------------------------------------------------------

    setState(() {
      _customers = customers;
    });
  }

  // ============================================================
  // DELETE CUSTOMER
  //
  // Deletes the selected customer after confirmation.
  // ============================================================

  Future<void> _deleteCustomer(Customer customer) async {
    // ----------------------------------------------------------
    // CUSTOMER MUST HAVE AN ID
    // ----------------------------------------------------------

    if (customer.id == null) {
      return;
    }

    // ----------------------------------------------------------
    // SHOW CONFIRMATION DIALOG
    // ----------------------------------------------------------

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Customer',
          ),
          content: Text(
            'Are you sure you want to delete '
                '${customer.name}?',
          ),
          actions: [
            // --------------------------------------------------
            // CANCEL BUTTON
            // --------------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            // --------------------------------------------------
            // DELETE BUTTON
            // --------------------------------------------------

            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    // ----------------------------------------------------------
    // USER CANCELLED
    // ----------------------------------------------------------

    if (confirmed != true) {
      return;
    }

    // ----------------------------------------------------------
    // DELETE FROM DATABASE
    // ----------------------------------------------------------

    await _repository.deleteCustomer(
      customer.id!,
    );

    // ----------------------------------------------------------
    // RELOAD CUSTOMER LIST
    // ----------------------------------------------------------

    await _loadCustomers();

    // ----------------------------------------------------------
    // CHECK WHETHER SCREEN IS STILL ACTIVE
    // ----------------------------------------------------------

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // SHOW SUCCESS MESSAGE
    // ----------------------------------------------------------

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${customer.name} deleted successfully.',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          'Customers',
        ),
      ),

      // --------------------------------------------------------
      // MAIN BODY
      // --------------------------------------------------------

      body: Column(
        children: [
          // ======================================================
          // SEARCH FIELD
          // ======================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,

              // --------------------------------------------------
              // SEARCH WHEN TEXT CHANGES
              // --------------------------------------------------

              onChanged: _searchCustomers,

              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(
                  Icons.search,
                ),
              ),
            ),
          ),

          // ======================================================
          // CUSTOMER LIST
          // ======================================================

          Expanded(
            child: _buildCustomerContent(),
          ),
        ],
      ),

      // --------------------------------------------------------
      // ADD CUSTOMER BUTTON
      //
      // The actual Add Customer screen will be connected in
      // the next step.
      // --------------------------------------------------------

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // --------------------------------------------------------
          // OPEN ADD CUSTOMER SCREEN
          // --------------------------------------------------------

          final bool? saved =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return const AddEditCustomerScreen();
              },
            ),
          );

          // --------------------------------------------------------
          // REFRESH CUSTOMER LIST
          //
          // If a customer was successfully saved, reload the list.
          // --------------------------------------------------------

          if (saved == true) {
            await _loadCustomers();
          }
        },
        icon: const Icon(
          Icons.person_add,
        ),
        label: const Text(
          'Add Customer',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD CUSTOMER CONTENT
  //
  // Determines what should be displayed:
  //
  // Loading
  // Empty
  // Customer list
  // ============================================================

  Widget _buildCustomerContent() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ----------------------------------------------------------
    // EMPTY LIST
    // ----------------------------------------------------------

    if (_customers.isEmpty) {
      return _buildEmptyState();
    }

    // ----------------------------------------------------------
    // CUSTOMER LIST
    // ----------------------------------------------------------

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          100,
        ),
        itemCount: _customers.length,
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          final Customer customer =
          _customers[index];

          return _buildCustomerCard(
            customer,
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD EMPTY STATE
  //
  // Displayed when there are no customers.
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            // --------------------------------------------------
            // ICON
            // --------------------------------------------------

            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(
              height: 16,
            ),

            // --------------------------------------------------
            // TITLE
            // --------------------------------------------------

            const Text(
              'No customers found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            // --------------------------------------------------
            // DESCRIPTION
            // --------------------------------------------------

            Text(
              'Add your first customer to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD CUSTOMER CARD
  //
  // Displays one customer's information.
  // ============================================================

  Widget _buildCustomerCard(
      Customer customer,
      ) {
    return Card(
      color: Colors.lightGreen.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ====================================================
            // CUSTOMER NAME
            // ====================================================

            Row(
              children: [
                // ------------------------------------------------
                // CUSTOMER ICON
                // ------------------------------------------------

                CircleAvatar(
                  child: const Icon(
                    Icons.person,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // ------------------------------------------------
                // CUSTOMER NAME
                // ------------------------------------------------

                Expanded(
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            // ====================================================
            // CUSTOMER NUMBER
            // ====================================================

            _buildInformationRow(
              icon: Icons.phone,
              label: 'Customer Number',
              value: customer.phone,
            ),

            // ====================================================
            // ALTERNATE NUMBER
            // ====================================================

            if (customer.alternatePhone != null &&
                customer.alternatePhone!
                    .trim()
                    .isNotEmpty)
              _buildInformationRow(
                icon: Icons.phone_android,
                label: 'Alternate Number',
                value: customer.alternatePhone!,
              ),

            // ====================================================
            // ADDRESS
            // ====================================================

            if (customer.address != null &&
                customer.address!
                    .trim()
                    .isNotEmpty)
              _buildInformationRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: customer.address!,
              ),

            // ====================================================
            // REMARKS
            // ====================================================

            if (customer.remarks != null &&
                customer.remarks!
                    .trim()
                    .isNotEmpty)
              _buildInformationRow(
                icon: Icons.notes,
                label: 'Remarks',
                value: customer.remarks!,
              ),

            const SizedBox(
              height: 8,
            ),

            const Divider(),

            // ====================================================
            // ACTION BUTTONS
            // ====================================================

            Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              children: [
                // ------------------------------------------------
                // EDIT BUTTON
                // ------------------------------------------------

              TextButton.icon(
              onPressed: () async {
              // --------------------------------------------------------
              // OPEN EDIT CUSTOMER SCREEN
              //
              // The selected customer is passed to the form so that
              // its existing information can be displayed.
              // --------------------------------------------------------

              final bool? updated =
              await Navigator.of(context).push<bool>(
              MaterialPageRoute(
              builder: (BuildContext context) {
              return AddEditCustomerScreen(
              customer: customer,
              );
              },
              ),
              );

              // --------------------------------------------------------
              // REFRESH CUSTOMER LIST
              //
              // Reload the list after a successful update.
              // --------------------------------------------------------

              if (updated == true) {
              await _loadCustomers();
              }
              },
              icon: const Icon(
              Icons.edit_outlined,
              ),
              label: const Text(
              'Edit',
              ),
              ),

                const SizedBox(
                  width: 8,
                ),

                // ------------------------------------------------
                // DELETE BUTTON
                // ------------------------------------------------

                TextButton.icon(
                  onPressed: () {
                    _deleteCustomer(
                      customer,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  label: const Text(
                    'Delete',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  //
  // Reusable widget for displaying customer information.
  // ============================================================

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // INFORMATION ICON
          // ------------------------------------------------------

          Icon(
            icon,
            size: 20,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),

          const SizedBox(
            width: 10,
          ),

          // ------------------------------------------------------
          // INFORMATION TEXT
          // ------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}