// ============================================================
// FILE: tyre_stock_list_screen.dart
//
// PURPOSE:
// Displays and manages all Tyre Stock records.
//
// FUNCTIONALITY:
// - Display stock records.
// - Search stock.
// - Add stock.
// - Edit stock.
// - Delete stock.
// - Generate complete stock image.
// - Share stock image using Android Share Sheet.
//
// STOCK GROUPING:
// - Cherry
// - Tyreplex
//
// VEHICLE TYPES:
// - 2 Wheeler
// - 4 Wheeler
//
// IMPORTANT:
// The Generate Stock Image function always loads ALL records
// directly from SQLite.
//
// Therefore, the image is not affected by the current search.
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';

import '../models/tyre_stock.dart';
import '../repositories/tyre_stock_repository.dart';
import '../services/tyre_stock_image_service.dart';
import 'add_edit_tyre_stock_screen.dart';

// ============================================================
// TYRE STOCK LIST SCREEN
// ============================================================

class TyreStockListScreen extends StatefulWidget {
  const TyreStockListScreen({
    super.key,
  });

  @override
  State<TyreStockListScreen> createState() =>
      _TyreStockListScreenState();
}

// ============================================================
// STATE
// ============================================================

class _TyreStockListScreenState
    extends State<TyreStockListScreen> {
  // ============================================================
  // SEARCH CONTROLLER
  // ============================================================

  final TextEditingController
  _searchController =
  TextEditingController();

  // ============================================================
  // TYRE STOCK REPOSITORY
  //
  // PURPOSE:
  // Handles SQLite operations.
  // ============================================================

  final TyreStockRepository
  _repository =
  TyreStockRepository();

  // ============================================================
  // IMAGE SERVICE
  //
  // PURPOSE:
  // Generates the stock PNG and opens the Android Share Sheet.
  // ============================================================

  final TyreStockImageService
  _imageService =
      TyreStockImageService.instance;

  // ============================================================
  // STOCK LIST
  // ============================================================

  List<TyreStock> _stocks =
  <TyreStock>[];

  // ============================================================
  // LOADING STATE
  // ============================================================

  bool _isLoading = true;

  // ============================================================
  // IMAGE GENERATION STATE
  //
  // PURPOSE:
  // Prevents multiple image-generation operations from being
  // started at the same time.
  // ============================================================

  bool _isGeneratingImage = false;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadStocks();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD STOCKS
  //
  // PURPOSE:
  // Loads stock records using the current search text.
  //
  // NOTE:
  // This method is used only for the screen list.
  //
  // Generate Stock Image does NOT use the search text.
  // ============================================================

  Future<void> _loadStocks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // --------------------------------------------------------
      // Search repository.
      // --------------------------------------------------------

      final List<TyreStock> stocks =
      await _repository.search(
        _searchController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stocks = stocks;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to load tyre stock.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ADD STOCK
  //
  // PURPOSE:
  // Opens the Add Tyre Stock screen.
  // ============================================================

  Future<void> _addStock() async {
    final bool? saved =
    await Navigator.of(context)
        .push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (
            BuildContext context,
            ) {
          return const
          AddEditTyreStockScreen();
        },
      ),
    );

    // ----------------------------------------------------------
    // Reload the list after a successful save.
    // ----------------------------------------------------------

    if (saved == true) {
      await _loadStocks();
    }
  }

  // ============================================================
  // EDIT STOCK
  // ============================================================

  Future<void> _editStock(
      TyreStock stock,
      ) async {
    final bool? saved =
    await Navigator.of(context)
        .push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (
            BuildContext context,
            ) {
          return AddEditTyreStockScreen(
            stock: stock,
          );
        },
      ),
    );

    // ----------------------------------------------------------
    // Reload after successful update.
    // ----------------------------------------------------------

    if (saved == true) {
      await _loadStocks();
    }
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<void> _confirmDelete(
      TyreStock stock,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder:
          (
          BuildContext context,
          ) {
        return AlertDialog(
          title: const Text(
            'Delete Tyre Stock?',
          ),
          content: Text(
            'Delete ${stock.tyre} '
                '${stock.pattern} '
                '${stock.size} from '
                '${stock.franchise} '
                '${stock.vehicleType} stock?',
          ),
          actions: <Widget>[
            // --------------------------------------------------
            // CANCEL
            // --------------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(false);
              },
              child:
              const Text('Cancel'),
            ),

            // --------------------------------------------------
            // DELETE
            // --------------------------------------------------

            FilledButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(true);
              },
              child:
              const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _deleteStock(
      stock,
    );
  }

  // ============================================================
  // DELETE STOCK
  // ============================================================

  Future<void> _deleteStock(
      TyreStock stock,
      ) async {
    if (stock.id == null) {
      return;
    }

    try {
      // --------------------------------------------------------
      // Delete from SQLite.
      // --------------------------------------------------------

      await _repository.delete(
        stock.id!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Tyre stock deleted successfully.',
      );

      // --------------------------------------------------------
      // Refresh list.
      // --------------------------------------------------------

      await _loadStocks();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete tyre stock.',
      );
    }
  }

  // ============================================================
  // GENERATE STOCK IMAGE
  //
  // PURPOSE:
  // Generates an image containing ALL tyre stock records.
  //
  // IMPORTANT:
  // The current search filter is intentionally ignored.
  //
  // Example:
  //
  // If the search box contains:
  //
  // JK
  //
  // the screen may display only JK records.
  //
  // But Generate Stock Image will still include:
  //
  // - All Cherry stock
  // - All Tyreplex stock
  // - All 2 Wheeler stock
  // - All 4 Wheeler stock
  // - All tyre companies
  //
  // This makes the generated image a complete stock report.
  // ============================================================

  Future<void> _generateStockImage() async {
    // ----------------------------------------------------------
    // Prevent duplicate image-generation requests.
    // ----------------------------------------------------------

    if (_isGeneratingImage) {
      return;
    }

    // ----------------------------------------------------------
    // Prevent generation while the list is loading.
    // ----------------------------------------------------------

    if (_isLoading) {
      return;
    }

    // ----------------------------------------------------------
    // Set generation state.
    // ----------------------------------------------------------

    setState(() {
      _isGeneratingImage = true;
    });

    bool progressDialogShown = false;

    try {
      // --------------------------------------------------------
      // IMPORTANT:
      // Load ALL stock directly from SQLite.
      //
      // Do NOT use _searchController.text here.
      // --------------------------------------------------------

      final List<TyreStock> stocks =
      await _repository.getAll();

      // --------------------------------------------------------
      // Check whether stock exists.
      // --------------------------------------------------------

      if (stocks.isEmpty) {
        if (!mounted) {
          return;
        }

        _showMessage(
          'There is no tyre stock to generate an image.',
        );

        return;
      }

      // --------------------------------------------------------
      // Make sure the screen is still available.
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // Show progress dialog.
      // --------------------------------------------------------

      progressDialogShown = true;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (
            BuildContext context,
            ) {
          return const AlertDialog(
            content: Row(
              children: <Widget>[
                SizedBox(
                  width: 24,
                  height: 24,
                  child:
                  CircularProgressIndicator(),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: Text(
                    'Generating stock image...',
                  ),
                ),
              ],
            ),
          );
        },
      );

      // --------------------------------------------------------
      // Generate PNG.
      // --------------------------------------------------------

      final File imageFile =
      await _imageService.generateImage(
        stocks: stocks,
      );

      // --------------------------------------------------------
      // Close progress dialog.
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      if (progressDialogShown) {
        Navigator.of(context).pop();

        progressDialogShown =
        false;
      }

      // --------------------------------------------------------
      // Show success dialog.
      // --------------------------------------------------------

      await _showImageGeneratedDialog(
        imageFile,
      );
    } catch (_) {
      // --------------------------------------------------------
      // Close progress dialog if it is still open.
      // --------------------------------------------------------

      if (mounted &&
          progressDialogShown) {
        Navigator.of(context).pop();

        progressDialogShown =
        false;
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to generate tyre stock image.',
      );
    } finally {
      // --------------------------------------------------------
      // Reset image-generation state.
      // --------------------------------------------------------

      if (mounted) {
        setState(() {
          _isGeneratingImage =
          false;
        });
      }
    }
  }

  // ============================================================
  // SHOW IMAGE GENERATED DIALOG
  //
  // PURPOSE:
  // Displays a confirmation after the PNG has been generated.
  //
  // BUTTONS:
  // - Close
  // - Share
  //
  // SHARE:
  // Opens the native Android Share Sheet.
  // ============================================================

  Future<void>
  _showImageGeneratedDialog(
      File imageFile,
      ) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder:
          (
          BuildContext context,
          ) {
        return AlertDialog(
          // ----------------------------------------------------
          // TITLE
          // ----------------------------------------------------

          title: const Row(
            children: <Widget>[
              Icon(
                Icons
                    .check_circle_outline,
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  'Stock Image Ready',
                ),
              ),
            ],
          ),

          // ----------------------------------------------------
          // CONTENT
          // ----------------------------------------------------

          content:
          const Text(
            'The complete tyre stock image '
                'has been generated successfully.',
          ),

          // ----------------------------------------------------
          // ACTIONS
          // ----------------------------------------------------

          actions: <Widget>[
            // --------------------------------------------------
            // CLOSE
            // --------------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop();
              },
              child:
              const Text('Close'),
            ),

            // --------------------------------------------------
            // SHARE
            // --------------------------------------------------

            FilledButton.icon(
              onPressed: () async {
                try {
                  // --------------------------------------------
                  // Close the dialog before opening the
                  // Android Share Sheet.
                  // --------------------------------------------

                  Navigator.of(
                    context,
                  ).pop();

                  // --------------------------------------------
                  // Open native Android Share Sheet.
                  // --------------------------------------------

                  await _imageService
                      .shareImage(
                    imageFile,
                  );
                } catch (_) {
                  if (!mounted) {
                    return;
                  }

                  _showMessage(
                    'Unable to share stock image.',
                  );
                }
              },
              icon:
              const Icon(
                Icons.share_outlined,
              ),
              label:
              const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Text(message),
        ),
      );
  }

  // ============================================================
  // DETAIL ROW
  //
  // PURPOSE:
  // Displays one stock property inside a card.
  // ============================================================

  Widget _buildDetailRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STOCK CARD
  //
  // PURPOSE:
  // Displays one tyre stock record.
  // ============================================================

  Widget _buildStockCard(
      TyreStock stock,
      ) {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    stock.tyre,
                    style:
                    const TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                // ----------------------------------------------
                // EDIT
                // ----------------------------------------------

                IconButton(
                  tooltip:
                  'Edit',
                  onPressed: () {
                    _editStock(
                      stock,
                    );
                  },
                  icon:
                  const Icon(
                    Icons
                        .edit_outlined,
                  ),
                ),

                // ----------------------------------------------
                // DELETE
                // ----------------------------------------------

                IconButton(
                  tooltip:
                  'Delete',
                  onPressed: () {
                    _confirmDelete(
                      stock,
                    );
                  },
                  icon:
                  const Icon(
                    Icons
                        .delete_outline,
                  ),
                ),
              ],
            ),

            const Divider(),

            // --------------------------------------------------
            // FRANCHISE
            // --------------------------------------------------

            _buildDetailRow(
              label:
              'Franchise',
              value:
              stock.franchise,
            ),

            // --------------------------------------------------
            // VEHICLE TYPE
            // --------------------------------------------------

            _buildDetailRow(
              label:
              'Vehicle Type',
              value:
              stock.vehicleType,
            ),

            // --------------------------------------------------
            // PATTERN
            // --------------------------------------------------

            _buildDetailRow(
              label:
              'Pattern',
              value:
              stock.pattern,
            ),

            // --------------------------------------------------
            // SIZE
            // --------------------------------------------------

            _buildDetailRow(
              label:
              'Size',
              value:
              stock.size,
            ),

            // --------------------------------------------------
            // STOCK
            // --------------------------------------------------

            _buildDetailRow(
              label:
              'Stock',
              value:
              stock.stock.toString(),
            ),

            // --------------------------------------------------
            // SELL PRICE
            // --------------------------------------------------

            _buildDetailRow(
              label:
              'Sell Price',
              value:
              '₹ ${stock.sellPrice.toStringAsFixed(2)}',
            ),

            // --------------------------------------------------
            // LLP
            // --------------------------------------------------

            _buildDetailRow(
              label:
              'LLP',
              value:
              '₹ ${stock.llp.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final bool isSearching =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: <Widget>[
            // --------------------------------------------------
            // ICON
            // --------------------------------------------------

            Icon(
              isSearching
                  ? Icons.search_off
                  : Icons
                  .tire_repair_outlined,
              size: 64,
            ),

            const SizedBox(
              height: 16,
            ),

            // --------------------------------------------------
            // MESSAGE
            // --------------------------------------------------

            Text(
              isSearching
                  ? 'No tyre stock found.'
                  : 'No tyre stock added yet.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title:
        const Text(
          'Tyre Stock',
        ),

        actions:
        <Widget>[
          // ----------------------------------------------------
          // GENERATE STOCK IMAGE
          // ----------------------------------------------------

          IconButton(
            tooltip:
            'Generate Stock Image',
            onPressed:
            _isGeneratingImage
                ? null
                : _generateStockImage,
            icon:
            _isGeneratingImage
                ? const SizedBox(
              width: 22,
              height: 22,
              child:
              CircularProgressIndicator(
                strokeWidth:
                2,
              ),
            )
                : const Icon(
              Icons
                  .image_outlined,
            ),
          ),
        ],
      ),

      // ========================================================
      // ADD STOCK BUTTON
      // ========================================================

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        _isGeneratingImage
            ? null
            : _addStock,
        icon:
        const Icon(
          Icons.add,
        ),
        label:
        const Text(
          'Add Stock',
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ==================================================
            // SEARCH BAR
            // ==================================================

            Padding(
              padding:
              const EdgeInsets.all(
                16,
              ),
              child:
              TextField(
                controller:
                _searchController,

                // ------------------------------------------------
                // SEARCH WHEN TEXT CHANGES
                // ------------------------------------------------

                onChanged:
                    (_) {
                  _loadStocks();
                },

                decoration:
                InputDecoration(
                  hintText:
                  'Search franchise, vehicle type, tyre, pattern or size',

                  prefixIcon:
                  const Icon(
                    Icons.search,
                  ),

                  suffixIcon:
                  _searchController
                      .text
                      .isEmpty
                      ? null
                      : IconButton(
                    onPressed:
                        () {
                      _searchController
                          .clear();

                      _loadStocks();
                    },
                    icon:
                    const Icon(
                      Icons
                          .clear,
                    ),
                  ),

                  border:
                  const OutlineInputBorder(),
                ),
              ),
            ),

            // ==================================================
            // STOCK LIST
            // ==================================================

            Expanded(
              child:
              _isLoading
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )
                  : _stocks.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh:
                _loadStocks,
                child:
                ListView.builder(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    16,
                    0,
                    16,
                    100,
                  ),
                  itemCount:
                  _stocks.length,
                  itemBuilder:
                      (
                      BuildContext
                      context,
                      int index,
                      ) {
                    return _buildStockCard(
                      _stocks[
                      index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}